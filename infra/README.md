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

## DNS Configuration

### Supabase Custom Domain

Configure `api.musicaluniversefactory.com` as a custom domain for Supabase to improve email deliverability and provide a branded API endpoint.

**DNS Record (Configure in your DNS provider):**
```
Type: CNAME
Name: api
Value: aydvoswbhwniqrsgzwbm.supabase.co
TTL: 300 (as low as possible)
Proxy: OFF (if using Cloudflare, disable proxy)
```

**What This Handles:**
- All Supabase API requests (REST, GraphQL)
- Authentication services (magic links, OAuth, sessions)
- Storage bucket access
- Realtime subscriptions
- Edge Functions

**Supabase Configuration:**
1. Go to Supabase Dashboard → Project Settings → API
2. Under "Custom Domain", enter: `api.musicaluniversefactory.com`
3. Wait for DNS verification and SSL certificate issuance
4. Update `PUBLIC_SUPABASE_URL` to `https://api.musicaluniversefactory.com`
5. Redeploy application with updated environment variable

**Important:** After activation, the original `*.supabase.co` URL will no longer work for auth services.

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
