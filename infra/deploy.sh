#!/bin/bash
set -euo pipefail

# --- Load Configuration ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/config.sh"

# --- Prerequisite Checks ---
# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
  echo "ERROR: gcloud CLI is not installed."
  echo "Install from: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
  echo "ERROR: Not authenticated with gcloud."
  echo "Run: gcloud auth login"
  exit 1
fi

# --- Project ID Configuration ---
# PROJECT_ID should be set by the caller or the environment.
# If not set, we default to the currently active gcloud project.
if [ -z "${PROJECT_ID:-}" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "${PROJECT_ID:-}" ]; then
      echo "ERROR: No PROJECT_ID set and no default gcloud project configured."
      echo "Run: gcloud config set project YOUR_PROJECT_ID"
      exit 1
    fi
    echo "Using current gcloud project: $PROJECT_ID"
fi
export PROJECT_ID

# Update IMAGE_URI now that PROJECT_ID is set
IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$APP_NAME:$IMAGE_TAG"

# --- Configuration Validation ---
echo "--- Validating Configuration ---"

# Validate memory format (must match pattern like 512Mi, 1Gi, 2G, etc.)
if ! [[ "$CLOUD_RUN_MEMORY" =~ ^[0-9]+(Mi|Gi|M|G)$ ]]; then
  echo "ERROR: Invalid CLOUD_RUN_MEMORY format: $CLOUD_RUN_MEMORY"
  echo "Expected format: 512Mi, 1Gi, 2G, etc."
  exit 1
fi

# Validate CPU (must be a positive number)
if ! [[ "$CLOUD_RUN_CPU" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_CPU" -lt 1 ]; then
  echo "ERROR: Invalid CLOUD_RUN_CPU: $CLOUD_RUN_CPU (must be a positive integer)"
  exit 1
fi

# Validate port (must be a positive number)
if ! [[ "$CLOUD_RUN_PORT" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_PORT" -lt 1 ] || [ "$CLOUD_RUN_PORT" -gt 65535 ]; then
  echo "ERROR: Invalid CLOUD_RUN_PORT: $CLOUD_RUN_PORT (must be 1-65535)"
  exit 1
fi

# Validate timeout (must be a positive number, max 3600 for Cloud Run)
if ! [[ "$CLOUD_RUN_TIMEOUT" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_TIMEOUT" -lt 1 ] || [ "$CLOUD_RUN_TIMEOUT" -gt 3600 ]; then
  echo "ERROR: Invalid CLOUD_RUN_TIMEOUT: $CLOUD_RUN_TIMEOUT (must be 1-3600 seconds)"
  exit 1
fi

# Validate concurrency (must be a positive number)
if ! [[ "$CLOUD_RUN_CONCURRENCY" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_CONCURRENCY" -lt 1 ]; then
  echo "ERROR: Invalid CLOUD_RUN_CONCURRENCY: $CLOUD_RUN_CONCURRENCY (must be a positive integer)"
  exit 1
fi

# Validate min/max instances
if ! [[ "$CLOUD_RUN_MIN_INSTANCES" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_MIN_INSTANCES" -lt 0 ]; then
  echo "ERROR: Invalid CLOUD_RUN_MIN_INSTANCES: $CLOUD_RUN_MIN_INSTANCES (must be >= 0)"
  exit 1
fi

if ! [[ "$CLOUD_RUN_MAX_INSTANCES" =~ ^[0-9]+$ ]] || [ "$CLOUD_RUN_MAX_INSTANCES" -lt 1 ]; then
  echo "ERROR: Invalid CLOUD_RUN_MAX_INSTANCES: $CLOUD_RUN_MAX_INSTANCES (must be >= 1)"
  exit 1
fi

if [ "$CLOUD_RUN_MIN_INSTANCES" -gt "$CLOUD_RUN_MAX_INSTANCES" ]; then
  echo "ERROR: CLOUD_RUN_MIN_INSTANCES ($CLOUD_RUN_MIN_INSTANCES) cannot exceed CLOUD_RUN_MAX_INSTANCES ($CLOUD_RUN_MAX_INSTANCES)"
  exit 1
fi

# Validate retry configuration
if ! [[ "$RETRY_ATTEMPTS" =~ ^[0-9]+$ ]] || [ "$RETRY_ATTEMPTS" -lt 1 ]; then
  echo "ERROR: Invalid RETRY_ATTEMPTS: $RETRY_ATTEMPTS (must be >= 1)"
  exit 1
fi

if ! [[ "$RETRY_DELAY" =~ ^[0-9]+$ ]] || [ "$RETRY_DELAY" -lt 0 ]; then
  echo "ERROR: Invalid RETRY_DELAY: $RETRY_DELAY (must be >= 0)"
  exit 1
fi

echo "Configuration validated successfully."

echo "======================================================"
echo "   DEPLOY SCRIPT"
echo "======================================================"
echo "Project ID:      $PROJECT_ID"
echo "App Name:        $APP_NAME"
echo "Region:          $REGION"
echo "======================================================"

# 1. Set Context
# Ensure we are in the project root (assuming script is in infra/)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Set the project and suppress the 'Information' log about environment tags
gcloud config set project "$PROJECT_ID" > /dev/null 2>&1

# Fix "Quota Project" warning by syncing ADC quota project
# We use '|| true' to ensure this doesn't break the script if ADC isn't set up
echo "--- Syncing Quota Project ---"
gcloud auth application-default set-quota-project "$PROJECT_ID" > /dev/null 2>&1 || true

# 2. Enable APIs (Idempotent)
echo "--- Enabling APIs ---"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com

# 3. Create Artifact Registry (Idempotent with Retry)
echo "--- Checking Artifact Registry Repo ---"
if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" > /dev/null 2>&1; then
  echo "Repository not found. Attempting to create (retrying up to $RETRY_ATTEMPTS times for IAM propagation)..."
  SUCCESS=false
  for i in $(seq 1 "$RETRY_ATTEMPTS"); do
    if gcloud artifacts repositories create "$REPO_NAME" \
      --repository-format=docker \
      --location="$REGION" \
      --description="Docker repository for $APP_NAME"; then
      echo "Repository created successfully."
      SUCCESS=true
      break
    else
      if [ "$i" -lt "$RETRY_ATTEMPTS" ]; then
        echo "Creation failed (likely IAM delay). Waiting $RETRY_DELAY seconds before retry $i..."
        sleep "$RETRY_DELAY"
      fi
    fi
  done
  if [ "$SUCCESS" = false ]; then
    echo "ERROR: Failed to create Artifact Registry repository after $RETRY_ATTEMPTS attempts."
    exit 1
  fi
else
  echo "Repository $REPO_NAME already exists."
fi

# 4. Build & Push (Cloud Build)
echo "--- Building Container (Cloud Build) ---"
# Retry loop for Cloud Build (uses Dockerfile and .gcloudignore in project root)
SUCCESS=false
for i in $(seq 1 "$RETRY_ATTEMPTS"); do
  if gcloud builds submit --tag "$IMAGE_URI" .; then
    echo "Build submitted successfully."
    SUCCESS=true
    break
  else
    if [ "$i" -lt "$RETRY_ATTEMPTS" ]; then
      echo "Build submission failed (likely IAM delay). Waiting $RETRY_DELAY seconds before retry $i..."
      sleep "$RETRY_DELAY"
    fi
  fi
done
if [ "$SUCCESS" = false ]; then
  echo "ERROR: Failed to submit build after $RETRY_ATTEMPTS attempts."
  exit 1
fi

# 5. Deploy to Cloud Run
echo "--- Deploying to Cloud Run ---"

# Build the deploy command with conditional flags
DEPLOY_CMD="gcloud run deploy $APP_NAME \
  --image $IMAGE_URI \
  --region $REGION \
  --platform managed \
  --port $CLOUD_RUN_PORT \
  --memory $CLOUD_RUN_MEMORY \
  --cpu $CLOUD_RUN_CPU \
  --concurrency $CLOUD_RUN_CONCURRENCY \
  --timeout $CLOUD_RUN_TIMEOUT \
  --min-instances $CLOUD_RUN_MIN_INSTANCES \
  --max-instances $CLOUD_RUN_MAX_INSTANCES"

# Add authentication flag
if [ "$CLOUD_RUN_ALLOW_UNAUTHENTICATED" = "true" ]; then
  DEPLOY_CMD="$DEPLOY_CMD --allow-unauthenticated"
else
  DEPLOY_CMD="$DEPLOY_CMD --no-allow-unauthenticated"
fi

# Add service account if specified
if [ -n "${CLOUD_RUN_SERVICE_ACCOUNT:-}" ]; then
  DEPLOY_CMD="$DEPLOY_CMD --service-account $CLOUD_RUN_SERVICE_ACCOUNT"
fi

# Execute the deployment
eval "$DEPLOY_CMD"

echo "======================================================"
echo "SUCCESS!"
echo "Service URL:"
gcloud run services describe "$APP_NAME" --region "$REGION" --format 'value(status.url)'
echo "======================================================"