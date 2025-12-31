#!/bin/bash
set -e

# --- Configuration ---
# Allow overriding via environment variables
APP_NAME="${APP_NAME:-musical-universe-factory}"
REGION="${REGION:-us-central1}"
REPO_NAME="${REPO_NAME:-muf-repo}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
# PROJECT_ID should be set by the caller or the environment. 
# If not set, we default to the currently active gcloud project.
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project)
    echo "Using current gcloud project: $PROJECT_ID"
fi

echo "======================================================"
echo "   DEPLOY SCRIPT"
echo "======================================================"
echo "Project ID:      $PROJECT_ID"
echo "App Name:        $APP_NAME"
echo "Region:          $REGION"
echo "======================================================"

# 1. Set Context
# Ensure we are in the project root (assuming script is in infra/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
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
  echo "Repository not found. Attempting to create (retrying up to 5 times for IAM propagation)..."
  for i in {1..5}; do
    if gcloud artifacts repositories create "$REPO_NAME" \
      --repository-format=docker \
      --location="$REGION" \
      --description="Docker repository for $APP_NAME"; then
      echo "Repository created successfully."
      break
    else
      echo "Creation failed (likely IAM delay). Waiting 60 seconds before retry $i..."
      sleep 60
    fi
  done
else
  echo "Repository $REPO_NAME already exists."
fi

# 4. Build & Push (Cloud Build)
IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$APP_NAME:$IMAGE_TAG"

echo "--- Building Container (Cloud Build) ---"
# Copy .gcloudignore to root for gcloud to find it
cp "$SCRIPT_DIR/.gcloudignore" "$PROJECT_ROOT/.gcloudignore"

# Retry loop for Cloud Build
for i in {1..5}; do
  if gcloud builds submit --config="$SCRIPT_DIR/docker/Dockerfile" --tag "$IMAGE_URI" .; then
    echo "Build submitted successfully."
    break
  else
    echo "Build submission failed (likely IAM delay). Waiting 60 seconds before retry $i..."
    sleep 60
  fi
done

# Clean up
rm -f "$PROJECT_ROOT/.gcloudignore"

# 5. Deploy to Cloud Run
echo "--- Deploying to Cloud Run ---"
gcloud run deploy "$APP_NAME" \
  --image "$IMAGE_URI" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --port 8080

echo "======================================================"
echo "SUCCESS!"
echo "Service URL:"
gcloud run services describe "$APP_NAME" --region "$REGION" --format 'value(status.url)'
echo "======================================================"