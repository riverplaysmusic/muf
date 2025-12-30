# Musical Universe Factory

Astro web application with Supabase integration.

## Prerequisites
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
- [Node.js (LTS)](https://nodejs.org/)
- Active GCP Billing Account ID

## Deployment

### Initial Setup (One-time)
Creates a new GCP project, links billing, enables APIs, and deploys.
```bash
BILLING_ACCOUNT_ID="your-id" ./infrastructure/setup_fresh.sh
```

### Regular Deployment
Builds and deploys updates to the current project.
```bash
./infrastructure/deploy.sh
```

## Local Development
```bash
npm install
npm run dev
```
