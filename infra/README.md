# Infrastructure

Scripts to deploy Musical Universe Factory to Google Cloud Run.

## Prerequisites

- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- Authenticated: `gcloud auth login`
- Billing account ID

## Initial Setup

Creates a new GCP project and deploys:

```bash
# Set BILLING_ACCOUNT_ID in .env or pass directly
BILLING_ACCOUNT_ID=your-id ./infra/setup_fresh.sh
```

## Deploy Updates

Builds and deploys to current project:

```bash
./infra/deploy.sh
```

## Configuration

Override defaults by creating `infra/.env`:

```bash
cp infra/.env.example infra/.env
# Edit as needed
```

Key settings:
- `APP_NAME` - Cloud Run service name (default: musical-universe-factory)
- `REGION` - GCP region (default: us-central1)
- `CLOUD_RUN_MEMORY` - Memory allocation (default: 512Mi)
- `CLOUD_RUN_MAX_INSTANCES` - Max instances (default: 10)

See `config.sh` for all options.

## Philosophy

- **No CI/CD**: Manual deployment for direct control
- **No staging**: Production only
- **Simple**: Just bash scripts and gcloud
- **Minimal**: Zero unnecessary complexity
