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

# Validation: gcloud will fail fast if values are wrong. Trust the tools.

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

# 4. Load PUBLIC environment variables for build
echo "--- Loading Environment Variables ---"
if [ ! -f ".env" ]; then
  echo "ERROR: .env file not found in project root."
  echo "Copy .env.example to .env and configure it."
  exit 1
fi

# Load PUBLIC env vars (needed at build time for Astro)
# shellcheck disable=SC2046
export $(grep "^PUBLIC_" .env | xargs)

if [ -z "${PUBLIC_SUPABASE_URL:-}" ] || [ -z "${PUBLIC_SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  echo "ERROR: Required PUBLIC environment variables not set in .env"
  echo "Required: PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY"
  exit 1
fi

echo "✓ Environment variables loaded"

# 4. Build & Push (Cloud Build)
echo "--- Building Container (Cloud Build) ---"
# Retry loop for Cloud Build (uses cloudbuild.yaml with substitutions)
SUCCESS=false
for i in $(seq 1 "$RETRY_ATTEMPTS"); do
  if gcloud builds submit \
    --config cloudbuild.yaml \
    --substitutions "_IMAGE_URI=$IMAGE_URI,_PUBLIC_SUPABASE_URL=$PUBLIC_SUPABASE_URL,_PUBLIC_SUPABASE_PUBLISHABLE_KEY=$PUBLIC_SUPABASE_PUBLISHABLE_KEY" \
    .; then
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

# 5. Load SECRET environment variables for Cloud Run runtime
echo "--- Loading Secret Environment Variables ---"
# shellcheck disable=SC2046
export $(grep -v "^PUBLIC_" .env | grep -v "^#" | grep -v "^$" | xargs)

# Validate required secret environment variables
REQUIRED_SECRETS="SUPABASE_SERVICE_KEY STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET"
for secret in $REQUIRED_SECRETS; do
  if [ -z "${!secret:-}" ]; then
    echo "ERROR: Required secret environment variable $secret not set in .env"
    exit 1
  fi
done

echo "✓ Secret environment variables validated"

# 6. Deploy to Cloud Run
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
  --max-instances $CLOUD_RUN_MAX_INSTANCES \
  --set-env-vars=\"SUPABASE_SERVICE_KEY=$SUPABASE_SERVICE_KEY,STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY,STRIPE_WEBHOOK_SECRET=$STRIPE_WEBHOOK_SECRET,PUBLIC_SUPABASE_URL=$PUBLIC_SUPABASE_URL,PUBLIC_SUPABASE_PUBLISHABLE_KEY=$PUBLIC_SUPABASE_PUBLISHABLE_KEY\""

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