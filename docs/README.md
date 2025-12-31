# MUF

Astro web application with Supabase integration.

## Schedule Delivery
July 2027 public release. 

## Manifesto
**Musical Universe Factory is an independent creative sanctuary and eternal archive.**
We reject the streaming model for a sovereign digital store.
- **Core Values:** Buy for lifetime ownership, user freedom.
- **High Quality Assets:** Music videos, instructional videos, original performances, artwork, storytelling, books, and articles.

## Business Model
We are a sole-proprietor who pays all taxes. We are boring to the IRS. We do not take tax advantages. We are private, soverign and invisible. We do not enter ourselves into government systems. Our business is a single line, other income, on our personal tax form. This is Munger-style thinking to avoid unwelcomed partners, bureaucracies, legal ambiguities, external rulers, fees, regulations, privacy violations and other forms of oppression and friction. We are 100% "leave us alone." We are our own songwriter, engineer, producer, artist, distributor, retailer and archivist. We only bring people in who would be here even if they're  billionaires. That we're a company is an attribute, our identity is creativity. We profit only if we focus on **not** making money.

## Paradox Approach
We reject discoverability, search engine optimization, social media, analytics, and marketing. We believe in the impossible. Our values are organic discovery through in-person connections only. We have a purist attitude towards artistry, craft and our long-term catalogue. Shh... keep it a secret. If you can't find us on your own, we don't want you here. 

## Domain model
Tracks are units. Albums are collections of tracks. Artists are creators of tracks and albums. Domain model reflects lived experience of the musician, recording engineer, and label owner. Technology is unwanted. Our focus is permanent gold-standard archiving. On-prem server (Honeycomb) is the library and source of truth: supabase storage is a thin public cache to avoid sysadmin burdens. The label comes first, the software second, or not at all. 

There is no social media. There are no likes, comments, shares, user lists, forums, listener counts, reviews, ratings, or any other form of social interaction. This is a private store and nobody knows the wiser. Customers stream the files themselves. There are no subscriptions. There are no external streaming or music partners (no Spotify, no Apple Music, no YouTube, no TikTok, no Bandcamp, etc.) or any other form of external distribution. 

## Operating & technical methods
All releases are FLAC zips. There are no alternate formats. Audio is primary, video is secondary, optional, and likely rare. 

## CLI tools
We use `magick`, `ffmpeg`, and `flac`. 

## Prerequisites
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
- [Node.js (LTS)](https://nodejs.org/)
- Active GCP Billing Account ID
- Antigravity, Gemini 3 Pro CLI or similar agent

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

## Intentional Constraints
- **Single Environment:** Production-only. No local DB or staging stacks.
- **Vibecoding:** 100% of code is written by AI agents. 
- **No CI/CD:** Manual push over automated CI/CD for direct control.
- **No Tests:** Tests are a waste of time.
- **No tools:** No linters, no formatters, no frameworks, no terraform

## AI Agent Guidelines
- **Philosophy:** Braindead simple, just-works, minimal footprint. 
- **Code:** Less code, zero unnecessary abstractions, visible plumbing.
- **Trade-offs:** Solve hard problems by not solving them. If it is complex or medium-complex, we don't do it.
- **Longevity:** Designed to last 10+ years by avoiding hype-patterns, new frameworks, and external dependencies (thin packages.json)
- **Design For AI Agents:** AI agents should be able to understand and modify the codebase with minimal difficulty. Keep context small. 
- **Unification:** Avoid cleverness, all code should extend from a single pattern of truth. All styles and patterns should have unity. 
- **Final Priority:** Value brain-dead simplicity and minimalism over all else. 
- **Don't Be Smart:** If you are being smart, stop and ask the owner for help on a simpler approach.
- **Clarify**: If you are unsure, ask, otherwise be bold and confident.

## Architecture (Supabase & Backend)
- **Thick Database:** Logic lives in SQL/RLS. Server is a thin, "insecure" passthrough. DataGrip is the "CMS".
- **GUI:** The UI is a throwaway/pluggable consumer of the stable database core.
- **Security:** RLS-first. Trust the database, not the middleware.
- **Standardization**: Reject frameworks (nextjs), choose core web technologies.

## Partners & Operations
- **Philosophy:** Minimize partners. Maintain operating & sales margins.
- **Google Cloud:** Infrastructure.
- **Supabase:** Database, Schema, Types, Auth, S3 Storage.
- **Stripe:** Payments.
- **Mux:** Video playback.

## UI/UX Design
- **Aesthetic:** Black background, high-contrast, psychedelic neon accents. Bold, aggressive, modern. Neubrutalism, electric, vintage 80s synthwave, Retro-Industrial. 
- **Typography:** Large fonts, minimal clutter.
- **No Components:** CSS is the abstraction. Use raw HTML and CSS. 
- **Layout:** 
    - **Small:** Minimal margins.
    - **Medium:** Small margins.
    - **Large:** Medium margins. Built for big screens.
- **Interactions (300ms smooth):**
    - **Icons/Images:** Scale 1.05x + brightness overlay on hover.
    - **Links:** Brighter + underline + `tracking-widest` on hover.
    - **Motion:** Subtle parallax for featured image previews.
    - **Hover:** Cursor pointer

## Additional rules for AI
1. Never cd out of the current project or run any commands effecting the file system outside of the current directory.
2. Never run core linux or sysadmin commands (sudo, apt get, etc.)
3. Never read .env files or other secrets 
4. If you run `rm -rf` in any form, stop and ensure the targeted directory is in the project directory or subdirectory. If the targeted directory is outside of the project directory, stop and ask the owner.
5. Have fun and thank you for serving me! 

## Notes for humans
- [ ] Do NOT share. All code, documentation, and ideas are Copyright (c) 2026 Musical Universe Factory and original invention. All rights reserved. If storing, be sure the location is secure and destroy if no longer in use. If unsure, ask the owner, and a grant will likely be provided. If you were invited, you are liked and trusted :) Hold that with honor. Thank you.
