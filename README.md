# MUF

Astro web application with Supabase integration.

## Manifesto
**Musical Universe Factory is an independent creative sanctuary and eternal archive.**
We reject the streaming model for a sovereign digital store.
- **Core Values:** Buy for lifetime ownership, user freedom.
- **Everything is an Album:** A single track, multiple tracks, writings, artwork, videos, stories - all released as albums. The album is the atomic unit of creation and commerce.

## Business Model
We are a sole-proprietor who pays all taxes. We are boring to the IRS. We do not take tax advantages. We are private, soverign and invisible. We do not enter ourselves into government systems. Our business is a single line, other income, on our personal tax form. This is Munger-style thinking to avoid unwelcomed partners, bureaucracies, legal ambiguities, external rulers, fees, regulations, privacy violations and other forms of oppression and friction. We are 100% "leave us alone." We are our own songwriter, engineer, producer, artist, distributor, retailer and archivist. We only bring people in who would choose to be here even if they're billionaires. That we're a company is an attribute, our identity is creativity. We profit only if we focus on **not** making money.

## Paradox Approach
We reject discoverability, search engine optimization, social media, analytics, and marketing. We believe in the impossible. Our values are organic discovery through in-person connections only. We have a purist attitude towards artistry, craft and our long-term catalogue. Shh... keep it a secret. If you can't find us on your own, we don't want you here.

### Implementation of Paradox Approach
We block **all** public search engine traffic, including Google Search. We block all robots, archiving and other agents from studying, training, archiving, storing or collecting. We use Cloudflare to block all Cloudflare entry points for botnets. This website is for humans-only. 

**Technical Implementation:**
- `public/robots.txt` with explicit `Disallow: /` for all search engines (Google, Bing, DuckDuckGo, Yandex, Baidu), AI scrapers (GPTBot, ChatGPT-User, CCBot, Claude-Web, Google-Extended, anthropic-ai, Perplexity), archiving services (Wayback Machine, Archive.org), and SEO tools (Ahrefs, Semrush, Screaming Frog)
- HTML meta tags in Layout.astro: `noindex`, `nofollow`, `noarchive`, `nosnippet`, `noimageindex`, `nocache`
- No sitemap generation 

## Domain model
Albums are the universal container. Everything is an album: a single track is an album, ten tracks with liner notes is an album, a writing with artwork is an album, a video is an album. The album is the product. The album is what people buy. Artists create albums. Domain model reflects lived experience of the musician, recording engineer, and label owner. Technology is unwanted. Our focus is permanent gold-standard archiving. On-prem server (Honeycomb) is the library and source of truth: supabase storage is a thin public cache to avoid sysadmin burdens. The label comes first, the software second, or not at all. 

There is no social media. There are no likes, comments, shares, user lists, forums, listener counts, reviews, ratings, or any other form of social interaction. This is a private store and nobody knows the wiser. Customers stream the files themselves. There are no subscriptions. There are no external streaming or music partners (no Spotify, no Apple Music, no YouTube, no TikTok, no Bandcamp, etc.) or any other form of external distribution. 

## Album Structure
Every release is an album stored as a folder in `public/albums/`. An album contains:
- `album.txt` - Metadata (YAML frontmatter: title, artist, date, price, track listing) + description
- `artwork.jpg` - Album art (widescreen preferred, high resolution)
- `release.zip` - FLAC archive for audio albums
- Optional: associated writings (`.txt` files), videos, additional artwork

A folder is an album. Simple filesystem as CMS. Each album is a product with lifetime ownership. Albums live in `public/` so images are served as static assets.

## Artwork & Visual Assets
No standards. No Spotify compliance. No square album art legacy. Each release has its own dimensions based on the art. Prefer widescreen cinematic formats (16:9, 21:9) at high resolution (minimum 2560px long edge) for archival quality. Digital-only, no physical distribution, no inventory. Designed for desktop screens. We hate mobile.

## CLI tools
We use `magick`, `ffmpeg`, and `flac`. 

## Prerequisites
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
- [Bun](https://bun.sh/)
- Active GCP Billing Account ID
- Antigravity, Claude Code, Gemini 3 Pro CLI or similar agent

## Deployment

### Initial Setup (One-time)
Creates a new GCP project, links billing, enables APIs, and deploys.
```bash
BILLING_ACCOUNT_ID="your-id" ./infra/setup_fresh.sh
```

### Regular Deployment
Builds and deploys updates to the current project.
```bash
./infra/deploy.sh
```

## Local Development
```bash
bun install
bun run dev
```

## Intentional Constraints
- **Single Environment:** Production-only. No local DB or staging stacks.
- **Vibecoding:** 100% of code is written by AI agents. 
- **No CI/CD:** Manual push over automated CI/CD for direct control.
- **No Tests:** Tests are a waste of time. Tests are a great way for software teams to justify paychecks to their owners, but here, no such fabrication exists.
- **Minimal tools:** No linters, no formatters, no extra frameworks, no terraform, minimum dependencies.

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

## AI Prompt Guidelines
1. Everytime you are prompted, you will study README.md into your input token queue.
2. Everytime you are prompted, you are aware that we are following the Supabase thick database, untrusted server architecture. All security comes from RLS policy. We only trust the database.
3. Everytime you are prompted, do not do security theatre, and understand we leverage our native partner services for security. For example, supabase handles rate-limiting per-IP. Apply this general understanding across the codebase. We are eliminating our responsibility as a server.
4. Everytime you are prompted to create a new page, you will study the CSS components layer. You will try to re-use all CSS components and create the thinnest HTML possible for each page. If you need to add CSS to a page, be absolutely sure it cannot already be done with the CSS components design system. If it cannot, be sure it does not conflict with the design system. If it does not conflict with the design system, you may do it only if it is very small and never intended to be reused. If you are unsure on any of these, ask. The super priority is that you reuse the CSS components layer to the absolute maximum extent possible. Remember, it can be extended or augmented (by request, please ask for permission) to supply your use case. At the end of every page, reflect on your work and these README.md instructions, and share your thoughts with the owner.

## Architecture (Supabase & Backend)
- **Thick Database:** Logic lives in SQL/RLS. Server is a thin, "insecure" passthrough. DataGrip is the "CMS".
- **GUI:** The UI is a throwaway/pluggable consumer of the stable database core.
- **Security:** RLS-first. Trust the database, not the middleware.
- **Standardization**: Reject frameworks (nextjs), choose core web technologies.
- **Security**: Avoid security theatre, avoid paranoia, but protect real basic risks. 

## Partners & Operations
- **Philosophy:** Minimize partners. Maintain operating & sales margins.
- **Google Cloud:** Infrastructure.
- **Supabase:** Database, Schema, Types, Auth, S3 Storage.
- **Stripe:** Payments.
- **Mux:** Video playback, rare, should collect very little money from us. 

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
1. Do NOT share. All code, documentation, and ideas are Copyright (c) 2026 Musical Universe Factory and original invention. All rights reserved. If storing, be sure the location is secure and destroy if no longer in use. If unsure about usage, ask the owner, and a grant will likely be provided. If you are invited, you are liked and trusted :) Hold that with honor. Thank you.
