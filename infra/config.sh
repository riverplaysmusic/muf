#!/bin/bash
# Central configuration for MUF infrastructure
# This file contains default values that can be overridden by environment variables

# --- Application Configuration ---
export APP_NAME="${APP_NAME:-musical-universe-factory}"
export REGION="${REGION:-us-central1}"

# --- GCP Project Configuration ---
# BILLING_ACCOUNT_ID is required for setup_fresh.sh (no default)
export BILLING_ACCOUNT_ID="${BILLING_ACCOUNT_ID:-}"

# --- Artifact Registry Configuration ---
export REPO_NAME="${REPO_NAME:-muf-repo}"
export IMAGE_TAG="${IMAGE_TAG:-latest}"

# --- Cloud Run Configuration ---
export CLOUD_RUN_PORT="${CLOUD_RUN_PORT:-8080}"
export CLOUD_RUN_MIN_INSTANCES="${CLOUD_RUN_MIN_INSTANCES:-0}"
export CLOUD_RUN_MAX_INSTANCES="${CLOUD_RUN_MAX_INSTANCES:-10}"
export CLOUD_RUN_MEMORY="${CLOUD_RUN_MEMORY:-512Mi}"
export CLOUD_RUN_CPU="${CLOUD_RUN_CPU:-1}"
export CLOUD_RUN_CONCURRENCY="${CLOUD_RUN_CONCURRENCY:-80}"
export CLOUD_RUN_TIMEOUT="${CLOUD_RUN_TIMEOUT:-300}"
export CLOUD_RUN_ALLOW_UNAUTHENTICATED="${CLOUD_RUN_ALLOW_UNAUTHENTICATED:-true}"
export CLOUD_RUN_SERVICE_ACCOUNT="${CLOUD_RUN_SERVICE_ACCOUNT:-}"

# --- Retry Configuration ---
export RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
export RETRY_DELAY="${RETRY_DELAY:-60}"

# --- Environment-specific overrides ---
# Load .env file if it exists (for environment-specific settings)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Loading environment-specific configuration from .env"
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

# Note: IMAGE_URI is constructed in deploy.sh after PROJECT_ID is determined
