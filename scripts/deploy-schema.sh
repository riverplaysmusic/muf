#!/bin/bash
set -euo pipefail

# Deploy database schema to Supabase

echo "======================================================"
echo "  DATABASE SCHEMA DEPLOYMENT"
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

echo "Deploying schema to Supabase..."
echo ""

# Deploy schema
psql "$SUPABASE_CONNECTION_STRING" -f schema/products-schema.sql

echo ""
echo "======================================================"
echo "✓ Schema deployed successfully"
echo "======================================================"
