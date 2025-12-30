# MUF

Astro web application with Supabase integration.

## Manifesto
**Musical Universe Factory is an independent creative sanctuary and eternal archive.**
It rejects the streaming model entirely for a sovereign digital store.
- **Core Values:** Buy for lifetime ownership, user freedom.
- **High Quality Assets:** Music videos, instructional videos, original performances, artwork, storytelling, books, and articles.

## Business Model
We are a sole-proprietor who pays all taxes. We are boring to the IRS and do not take tax advantages. We are private, soverign and invisible. We are not a company, we are an outlet of creativity. We do not enter ourselves into government systems. Our business is a single line, other income, on our personal tax form. This is Munger-style thinking to avoid unwelcomed partners, bureaucracies, external rulers, fees, regulations, privacy violations and other forms of oppression and friction. We are 100% "leave us alone." 

## Paradox Approach
We reject discoverability, search engine optimization, social media, analytics, and marketing. We believe in the impossible. Our values are organic discovery, discovery through in-person connections only, and a purist attitude to artistry, craft and the long-term fruit of creative labor. We sell but we do not need to profit. If you can't find us on your own, we don't want you here. 

## Domain model
Tracks are units. Albums are collections of tracks. Artists are creators of tracks and albums. Domain model reflects lived experiences of the musician, recording engineer, and label owner. Focus is on permanent gold-standard archiving. On-prem service (Honeycomb) is the library and source of truth: supabase storage is a thin public cache to avoid sysadmin role. The label comes first, the software second. 

There is no social media. There are no likes, comments, shares, user lists, forums, listener counts, reviews, ratings, or any other form of social interaction. This is a private store and nobody knows the wiser.

## Operating & technical methods
All releases are FLAC zips. There are no alternate formats. Audio is primary, video is secondary, optional, and possibly rare. 

## CLI tools
We use `magick`, `ffmpeg`, and `flac`. 

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

## Intentional Constraints
- **Single Environment:** Production-only. No local DB or staging stacks.
- **Vibecoding:** No linting or formatting tools. Trust AI.
- **No CI/CD:** Manual push over automated CI/CD for direct control.
- **No Tests:** Tests are a waste of time.
- **No tools:** No linters, no formatters, no frameworks, no terraform

## AI Agent Guidelines
- **Philosophy:** Braindead simple, just-works, minimal footprint. 
- **Code:** Less code, zero unnecessary abstractions, visible plumbing.
- **Trade-offs:** Sacrifice complexity for elegance. Avoid solving "hard" problems by simplifying the requirements.
- **Longevity:** Designed to last 10 years by avoiding transient dependencies and fragile patterns.
- **Design For AI Agents:** AI agents should be able to understand and modify the codebase with minimal difficulty. Avoid complexity. 
- **Unification:** Avoid cleverness, all code should extend from a single pattern of truth. 
- **Final Priority:** Value brain-dead simplicity and minimalism over all else. 
- **Clarify**: If you are unsure, ask, otherwise be bold and confident.

## Architecture (Supabase & Backend)
- **Thick Database:** Logic lives in SQL/RLS. Server is a thin, "insecure" passthrough.
- **GUI:** The UI is a throwaway/pluggable consumer of the stable database core.
- **Security:** RLS-first. Trust the database, not the middleware.
- **Standardization**: Reject frameworks, choose core web technologies.

## Partners & Operations
- **Philosophy:** Minimize partners. Maintain operating & sales margins.
- **Google Cloud:** Infrastructure.
- **Supabase:** Database, Schema, Types, Auth, S3 Storage.
- **Stripe:** Payments.
- **Mux:** Video playback.

## UI/UX Design
- **Aesthetic:** Black background, high-contrast, psychedelic neon accents. Bold, aggressive, modern.
- **Typography:** Large fonts, minimal clutter.
- **Layout:** 
    - **Small:** Minimal margins.
    - **Medium:** Small margins.
    - **Large:** Medium margins. Built for big screens.
- **Interactions (300ms smooth):**
    - **Icons/Images:** Scale 1.05x + brightness overlay on hover.
    - **Links:** Brighter + underline + `tracking-widest` on hover.
    - **Motion:** Subtle parallax for featured image previews.
    - **Hover:** Cursor pointer
