# Email Templates

This folder contains email templates for Musical Universe Factory.

## Quick Start

**To configure with Supabase:**

1. Run the configuration helper:
   ```bash
   ./scripts/configure-supabase-email.sh
   ```

2. Or manually:
   - Go to [Supabase Dashboard](https://supabase.com/dashboard) → **Authentication** → **Email Templates**
   - Select **Magic Link** template
   - Copy contents of `magic-link.html` and paste into the editor
   - Click **Save**

**For detailed setup instructions, see [SETUP.md](./SETUP.md)**

---

## Templates

### magic-link.html
Magic link authentication email template that matches the home page aesthetic.

**Design Features:**
- Pure black background (#000000)
- Vibrant gradient text (pink → yellow → cyan)
- Retro-style button with offset box shadow (light blue with orange shadow)
- Clean, uppercase typography
- Minimal glass-style borders
- Logo with yellow border and orange shadow

**Color Palette:**
- Primary Pink: #E91E8C
- Primary Yellow: #FFF066
- Primary Cyan: #66D9EF
- Accent Blue: #A8D5FF
- Accent Orange: #FFB366
- White: #FFFFFF
- Mid Gray: #A6A6A6
- Black: #000000

**Template Variables:**
- `{{ .ConfirmationURL }}` - The magic link URL for authentication

## Usage

This template is designed to be used with Supabase Auth or similar authentication services that support Go template syntax.
