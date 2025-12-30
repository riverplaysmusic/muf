#!/bin/bash
set -e

# --- Configuration ---
APP_NAME="musical-universe-factory"
BILLING_ACCOUNT_ID="${BILLING_ACCOUNT_ID:-01AB2C-9ECECA-DACA89}"
REGION="us-central1"

# Generate a random project ID to avoid conflicts
RANDOM_SUFFIX=$((1000 + RANDOM % 9999))
# Allow user to provide a specific project ID if they want to 'resume' a setup
PROJECT_ID="${PROJECT_ID:-muf-prod-${RANDOM_SUFFIX}}"

echo "======================================================"
echo "   GCP INIT SCRIPT"
echo "======================================================"
echo "Project ID:      $PROJECT_ID"
echo "Billing Account: $BILLING_ACCOUNT_ID"
echo "======================================================"
echo "Starting in 5 seconds... (Ctrl+C to cancel)"
sleep 5

# 1. Create Project
echo "--- Creating Project: $PROJECT_ID ---"
if gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
  echo "Project $PROJECT_ID already exists."
else
  gcloud projects create "$PROJECT_ID" --name="$APP_NAME"
fi

# 2. Link Billing
echo "--- Linking Billing ---"
gcloud beta billing projects link "$PROJECT_ID" --billing-account "$BILLING_ACCOUNT_ID"

# 3. Handover to Deploy Script
echo "--- Starting Deployment ---"
# We export these variables so deploy.sh picks them up
export PROJECT_ID
export APP_NAME
export REGION

# Get the directory where this script is located to call deploy.sh correctly
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"$SCRIPT_DIR/deploy.sh"