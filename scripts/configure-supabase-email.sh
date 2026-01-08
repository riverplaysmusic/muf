#!/bin/bash

# Script to help configure Supabase email templates
# This script provides guidance and opens relevant URLs

set -e

echo "================================================"
echo "Supabase Email Template Configuration Helper"
echo "================================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create one from .env.example"
    exit 1
fi

# Source environment variables
source .env

# Check if Supabase URL is set
if [ -z "$PUBLIC_SUPABASE_URL" ]; then
    echo "❌ PUBLIC_SUPABASE_URL not set in .env"
    exit 1
fi

# Extract project ref from Supabase URL
# Format: https://PROJECT_REF.supabase.co
PROJECT_REF=$(echo "$PUBLIC_SUPABASE_URL" | sed -E 's|https?://([^.]+)\..*|\1|')

echo "✓ Found Supabase project: $PROJECT_REF"
echo ""

# Check if email template exists
if [ ! -f "email-templates/magic-link.html" ]; then
    echo "❌ Email template not found at email-templates/magic-link.html"
    exit 1
fi

echo "✓ Email template found"
echo ""

# Display instructions
echo "📧 CONFIGURATION OPTIONS:"
echo ""
echo "Option 1: Dashboard Configuration (Recommended)"
echo "-----------------------------------------------"
echo "1. Open your Supabase Dashboard:"
echo "   https://supabase.com/dashboard/project/$PROJECT_REF/auth/templates"
echo ""
echo "2. Click on 'Magic Link' template"
echo ""
echo "3. Copy the contents of email-templates/magic-link.html"
echo ""
echo "4. Paste into the template editor and save"
echo ""
echo ""

echo "Option 2: Custom SMTP with Resend"
echo "-----------------------------------"
if [ -z "$RESEND_API_KEY" ]; then
    echo "⚠️  RESEND_API_KEY not set in .env"
    echo "   Add it to .env if you want to use custom SMTP"
else
    echo "✓ RESEND_API_KEY is configured"
fi
echo ""
echo "See email-templates/SETUP.md for implementation guide"
echo ""

# Offer to open the dashboard
echo ""
read -p "Would you like to open the Supabase Dashboard now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    DASHBOARD_URL="https://supabase.com/dashboard/project/$PROJECT_REF/auth/templates"

    # Try to open the URL based on OS
    if command -v xdg-open > /dev/null; then
        xdg-open "$DASHBOARD_URL"
    elif command -v open > /dev/null; then
        open "$DASHBOARD_URL"
    else
        echo "Please open this URL manually:"
        echo "$DASHBOARD_URL"
    fi
fi

echo ""
echo "✅ For detailed setup instructions, see:"
echo "   email-templates/SETUP.md"
echo ""
