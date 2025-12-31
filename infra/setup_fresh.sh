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

# --- Configuration ---
# Billing account must be provided
if [ -z "${BILLING_ACCOUNT_ID:-}" ]; then
  echo "ERROR: BILLING_ACCOUNT_ID environment variable is required."
  echo ""
  echo "Option 1 - Set in .env file (recommended):"
  echo "  cp infra/.env.example infra/.env"
  echo "  # Edit infra/.env and set BILLING_ACCOUNT_ID"
  echo "  ./infra/setup_fresh.sh"
  echo ""
  echo "Option 2 - Pass as environment variable:"
  echo "  BILLING_ACCOUNT_ID=your-id ./infra/setup_fresh.sh"
  echo ""
  echo "Find your billing account ID:"
  echo "  gcloud billing accounts list"
  exit 1
fi

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

# Call deploy.sh (SCRIPT_DIR already set at top of file)
"$SCRIPT_DIR/deploy.sh"