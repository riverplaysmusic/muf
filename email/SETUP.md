# Supabase Email Template Setup

This guide walks you through configuring the custom magic link email template with Supabase.

## Option 1: Via Supabase Dashboard (Recommended)

### Step 1: Access Email Templates

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **Email Templates**

### Step 2: Configure Magic Link Template

1. Click on **Magic Link** in the email templates list
2. Replace the default template with the contents of `magic-link.html`
3. Click **Save**

### Step 3: Test the Email

1. In your app, trigger a magic link request (sign in)
2. Check your email to verify the new template is being used
3. Verify the link works and styling displays correctly

---

## Option 2: Via Supabase CLI (Advanced)

If you want to manage email templates through infrastructure as code:

### Step 1: Initialize Supabase Project (if not already done)

```bash
supabase init
```

### Step 2: Link to Your Project

```bash
supabase link --project-ref YOUR_PROJECT_REF
```

You can find your project ref in the Supabase Dashboard URL or in your project settings.

### Step 3: Create Email Template Configuration

Create a file at `supabase/templates/magic-link.html` with the contents of our custom template.

### Step 4: Deploy Email Templates

```bash
supabase db push
```

Note: As of now, the Supabase CLI has limited support for email template deployment. You may need to use the Dashboard method above.

---

## Option 3: Custom SMTP Server (Full Control)

For complete control over email delivery and templates, you can configure a custom SMTP server.

### Prerequisites

- An SMTP service (e.g., Resend, SendGrid, Postmark)
- SMTP credentials

### Step 1: Disable Supabase Auth Emails

1. Go to **Authentication** → **Settings**
2. Under **Email Settings**, disable "Enable email confirmations"

### Step 2: Implement Custom Email Handler

Create an API endpoint that handles authentication and sends custom emails:

```typescript
// src/pages/api/send-magic-link.ts
import { Resend } from 'resend';
import { supabase } from '@/lib/supabase-server';
import { readFile } from 'fs/promises';
import { join } from 'path';

export async function POST({ request }: { request: Request }) {
  const { email } = await request.json();

  // Generate magic link via Supabase
  const { data, error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: 'https://musicaluniversefactory.com/auth/callback'
    }
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400
    });
  }

  // Send custom email via Resend
  const resend = new Resend(import.meta.env.RESEND_API_KEY);

  // Read the HTML template
  const template = await readFile(
    join(process.cwd(), 'email-templates', 'magic-link.html'),
    'utf-8'
  );

  // Replace template variables
  const html = template.replace(
    /{{ .ConfirmationURL }}/g,
    data.properties?.confirmation_url || ''
  );

  await resend.emails.send({
    from: 'Musical Universe Factory <noreply@musicaluniversefactory.com>',
    to: email,
    subject: 'Your Magic Link',
    html
  });

  return new Response(JSON.stringify({ success: true }), {
    status: 200
  });
}
```

---

## Testing Email Appearance

### Email Client Testing

Test your email template across different email clients:

- Gmail (web, mobile)
- Apple Mail
- Outlook
- Yahoo Mail
- ProtonMail

### Tools

- [Litmus](https://litmus.com/) - Email testing platform
- [Email on Acid](https://www.emailonacid.com/) - Email testing
- [MailTrap](https://mailtrap.io/) - Email sandbox for testing

---

## Troubleshooting

### Email not displaying correctly

- Check that all CSS is inline (email clients don't support external stylesheets)
- Test in multiple email clients
- Verify image URLs are absolute and accessible

### Template variables not working

- Ensure you're using the correct Supabase template syntax: `{{ .ConfirmationURL }}`
- Check Supabase logs for template rendering errors

### Emails going to spam

- Configure SPF, DKIM, and DMARC records for your domain
- Use a custom domain for sending emails
- Ensure email content doesn't trigger spam filters

---

## Additional Configuration

### Custom Domain

To send emails from your own domain (e.g., noreply@musicaluniversefactory.com):

1. Go to **Authentication** → **Settings** → **Email Settings**
2. Configure custom SMTP settings
3. Add DNS records (SPF, DKIM, DMARC) to your domain

### Email Rate Limiting

Configure rate limiting to prevent abuse:

1. Go to **Authentication** → **Rate Limits**
2. Set appropriate limits for email OTP requests
3. Consider implementing additional rate limiting in your application

---

## Support

If you encounter issues:
- Check [Supabase Documentation](https://supabase.com/docs/guides/auth/auth-email-templates)
- Visit [Supabase Discord](https://discord.supabase.com/)
- Review [Supabase GitHub Discussions](https://github.com/supabase/supabase/discussions)
