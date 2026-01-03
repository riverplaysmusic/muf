#!/bin/bash
set -euo pipefail

# Deploy storage bucket and RLS policies to Supabase

echo "======================================================"
echo "  STORAGE BUCKET & RLS POLICIES DEPLOYMENT"
echo "======================================================"

# Load environment
if [ ! -f ".env" ]; then
  echo "ERROR: .env file not found in project root."
  echo "Copy .env.example to .env and configure it."
  exit 1
fi

# Source .env file
set -a
source .env
set +a

if [ -z "${SUPABASE_CONNECTION_STRING:-}" ]; then
  echo "ERROR: SUPABASE_CONNECTION_STRING not set in .env"
  exit 1
fi

echo "Deploying storage policies to Supabase..."
echo ""

# Deploy storage policies
psql "$SUPABASE_CONNECTION_STRING" -f schema/storage-policies.sql

echo ""
echo "======================================================"
echo "✓ Storage bucket and policies deployed successfully"
echo "======================================================"
