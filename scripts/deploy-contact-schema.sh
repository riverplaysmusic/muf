#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found in project root."
  exit 1
fi

echo "Deploying contact form schema..."
psql "$SUPABASE_CONNECTION_STRING" < schema/contact-schema.sql
echo "Schema deployment complete."
