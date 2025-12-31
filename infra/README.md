# Infrastructure Deployment Scripts

This directory contains scripts to deploy the Musical Universe Factory (MUF) application to Google Cloud Platform (GCP) using Cloud Run.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Scripts](#scripts)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Overview

The deployment system consists of:

- **`config.sh`**: Centralized configuration with sensible defaults
- **`setup_fresh.sh`**: Creates a new GCP project and deploys the app
- **`deploy.sh`**: Deploys the app to an existing GCP project
- **`.env.example`**: Template for environment-specific configuration

## Prerequisites

1. **Google Cloud SDK (gcloud CLI)**
   ```bash
   # Install from: https://cloud.google.com/sdk/docs/install

   # Verify installation
   gcloud --version
   ```

2. **Authentication**
   ```bash
   # Login to your Google account
   gcloud auth login

   # Set application default credentials
   gcloud auth application-default login
   ```

3. **Billing Account** (for `setup_fresh.sh` only)
   ```bash
   # List your billing accounts
   gcloud billing accounts list
   ```

4. **Docker** (optional, for local testing)

## Quick Start

### Option 1: Deploy to Existing Project

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Deploy with defaults
./infra/deploy.sh
```

### Option 2: Create New Project and Deploy

```bash
# Create .env file
cp infra/.env.example infra/.env

# Edit .env and set BILLING_ACCOUNT_ID
# Find it with: gcloud billing accounts list

# Run setup (creates project and deploys)
./infra/setup_fresh.sh
```

## Configuration

### Configuration Files

1. **`config.sh`**: Contains all default values
2. **`.env`**: Override defaults for your environment (git-ignored)
3. **Environment variables**: Override any setting at runtime

### Configuration Priority

Environment variables > `.env` file > `config.sh` defaults

### Available Configuration Options

#### Application Configuration

```bash
APP_NAME=musical-universe-factory  # Cloud Run service name
REGION=us-central1                 # GCP region
```

#### GCP Project Configuration

```bash
BILLING_ACCOUNT_ID=                # Required for setup_fresh.sh only
```

#### Artifact Registry Configuration

```bash
REPO_NAME=muf-repo                 # Docker repository name
IMAGE_TAG=latest                   # Docker image tag
```

#### Cloud Run Configuration

```bash
# Basic settings
CLOUD_RUN_PORT=8080                # Application port
CLOUD_RUN_MEMORY=512Mi             # Memory allocation (256Mi, 512Mi, 1Gi, 2Gi, 4Gi, 8Gi)
CLOUD_RUN_CPU=1                    # CPU allocation (1, 2, 4, 8)
CLOUD_RUN_TIMEOUT=300              # Request timeout in seconds (max 3600)

# Scaling
CLOUD_RUN_MIN_INSTANCES=0          # Minimum instances (0 = scale to zero)
CLOUD_RUN_MAX_INSTANCES=10         # Maximum instances
CLOUD_RUN_CONCURRENCY=80           # Max concurrent requests per instance

# Security
CLOUD_RUN_ALLOW_UNAUTHENTICATED=true        # Allow public access
CLOUD_RUN_SERVICE_ACCOUNT=                  # Optional: custom service account
```

#### Retry Configuration

```bash
RETRY_ATTEMPTS=5                   # Number of retry attempts for operations
RETRY_DELAY=60                     # Delay between retries in seconds
```

### Example Configurations

#### Development Environment

Create `infra/.env`:

```bash
APP_NAME=muf-dev
IMAGE_TAG=dev
CLOUD_RUN_MIN_INSTANCES=0
CLOUD_RUN_MAX_INSTANCES=5
CLOUD_RUN_MEMORY=256Mi
CLOUD_RUN_ALLOW_UNAUTHENTICATED=true
```

#### Production Environment

Create `infra/.env`:

```bash
APP_NAME=muf-prod
IMAGE_TAG=v1.0.0
CLOUD_RUN_MIN_INSTANCES=1
CLOUD_RUN_MAX_INSTANCES=100
CLOUD_RUN_MEMORY=1Gi
CLOUD_RUN_CPU=2
CLOUD_RUN_ALLOW_UNAUTHENTICATED=false
CLOUD_RUN_SERVICE_ACCOUNT=muf-prod-sa@project-id.iam.gserviceaccount.com
```

## Scripts

### `deploy.sh`

Deploys the application to Cloud Run in an existing GCP project.

**Usage:**

```bash
# Deploy to current gcloud project
./infra/deploy.sh

# Deploy to specific project
PROJECT_ID=my-project ./infra/deploy.sh

# Deploy with custom settings
CLOUD_RUN_MEMORY=1Gi CLOUD_RUN_MAX_INSTANCES=50 ./infra/deploy.sh
```

**What it does:**

1. Validates prerequisites (gcloud CLI, authentication)
2. Validates configuration values
3. Enables required GCP APIs
4. Creates Artifact Registry repository (if needed)
5. Builds container image with Cloud Build
6. Deploys to Cloud Run

### `setup_fresh.sh`

Creates a new GCP project, links billing, and deploys the application.

**Usage:**

```bash
# Option 1: Set BILLING_ACCOUNT_ID in .env
cp infra/.env.example infra/.env
# Edit .env and set BILLING_ACCOUNT_ID
./infra/setup_fresh.sh

# Option 2: Pass as environment variable
BILLING_ACCOUNT_ID=your-id ./infra/setup_fresh.sh

# Option 3: Resume existing project setup
PROJECT_ID=existing-project BILLING_ACCOUNT_ID=your-id ./infra/setup_fresh.sh
```

**What it does:**

1. Validates prerequisites
2. Creates new GCP project (or uses existing)
3. Links billing account
4. Calls `deploy.sh` to deploy the application

### `config.sh`

Central configuration file loaded by other scripts. Do not execute directly.

## Security

### Secrets Management

- **Never commit `.env`** files (already in `.gitignore`)
- Store secrets in Google Secret Manager for production
- Use service accounts with least-privilege IAM roles

### Public Access

By default, `CLOUD_RUN_ALLOW_UNAUTHENTICATED=true` allows public access.

**To require authentication:**

```bash
# In .env or as environment variable
CLOUD_RUN_ALLOW_UNAUTHENTICATED=false
```

Then configure Cloud Run IAM:

```bash
# Allow specific users
gcloud run services add-iam-policy-binding APP_NAME \
  --region=REGION \
  --member="user:email@example.com" \
  --role="roles/run.invoker"
```

### Service Accounts

**Best practice**: Create a custom service account with minimal permissions.

```bash
# Create service account
gcloud iam service-accounts create muf-runner \
  --display-name="MUF Cloud Run Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:muf-runner@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Use in deployment
CLOUD_RUN_SERVICE_ACCOUNT=muf-runner@PROJECT_ID.iam.gserviceaccount.com ./infra/deploy.sh
```

### Build Context Security

The `.gcloudignore` file prevents sensitive files from being uploaded to Cloud Build:

- `.env` files
- `node_modules/`
- `.git/`
- `infra/` directory

**Always verify** `.gcloudignore` before deploying.

## Troubleshooting

### Common Issues

#### 1. "gcloud CLI is not installed"

**Solution:**
```bash
# Install from: https://cloud.google.com/sdk/docs/install
```

#### 2. "Not authenticated with gcloud"

**Solution:**
```bash
gcloud auth login
gcloud auth application-default login
```

#### 3. "ERROR: Failed to create Artifact Registry repository after 5 attempts"

**Cause:** IAM permissions may not have propagated.

**Solution:**
- Wait a few minutes and try again
- Verify you have `artifactregistry.admin` role
- Check API is enabled: `gcloud services list --enabled`

#### 4. "ERROR: Failed to submit build after 5 attempts"

**Cause:** Cloud Build API not enabled or IAM issues.

**Solution:**
```bash
# Enable API
gcloud services enable cloudbuild.googleapis.com

# Verify service account permissions
gcloud projects get-iam-policy PROJECT_ID
```

#### 5. "Invalid CLOUD_RUN_MEMORY format"

**Cause:** Memory format doesn't match Cloud Run requirements.

**Solution:** Use valid formats: `256Mi`, `512Mi`, `1Gi`, `2Gi`, `4Gi`, `8Gi`

#### 6. Deployment succeeds but service doesn't respond

**Causes:**
- Wrong port configuration
- Application not listening on `0.0.0.0`
- Application crashes on startup

**Solution:**
```bash
# Check Cloud Run logs
gcloud run services logs read APP_NAME --region=REGION --limit=50

# Verify port matches application
echo $CLOUD_RUN_PORT  # Should match your app's listen port
```

### Getting Help

1. **Check Cloud Run logs:**
   ```bash
   gcloud run services logs read APP_NAME --region=REGION
   ```

2. **Verify service status:**
   ```bash
   gcloud run services describe APP_NAME --region=REGION
   ```

3. **List recent revisions:**
   ```bash
   gcloud run revisions list --service=APP_NAME --region=REGION
   ```

4. **Test locally:**
   ```bash
   # Build Docker image
   docker build -t muf-local .

   # Run locally
   docker run -p 8080:8080 muf-local
   ```

### Debugging

Enable verbose output:

```bash
# Set gcloud to verbose mode
export CLOUDSDK_CORE_VERBOSITY=debug
./infra/deploy.sh
```

## Cost Optimization

### Minimize Costs

```bash
# Scale to zero when idle
CLOUD_RUN_MIN_INSTANCES=0

# Reduce memory allocation
CLOUD_RUN_MEMORY=256Mi

# Lower max instances
CLOUD_RUN_MAX_INSTANCES=5
```

### Estimated Costs

Cloud Run pricing (as of 2025):
- **CPU**: ~$0.00002400/vCPU-second
- **Memory**: ~$0.00000250/GiB-second
- **Requests**: $0.40/million requests
- **Free tier**: 2 million requests/month, significant CPU/memory allowance

With `MIN_INSTANCES=0` and low traffic, costs are typically < $5/month.

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
