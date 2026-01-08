# Writings

This folder contains all writings for the Musical Universe Factory website.

## Structure

Each writing lives in its own folder with a `writing.txt` file containing YAML frontmatter and the content.

```
writings/
├── README.md
├── template.txt                          # Template for new writings
└── on-creative-sovereignty/              # Example writing
    └── writing.txt                       # YAML + content
```

## Adding a New Writing

1. Create a new folder with a URL-friendly slug (e.g., `my-new-essay`)
2. Inside the folder, create a `writing.txt` file
3. Use the following format:

```txt
---
title: Your Writing Title
author: Author Name
date: 2026-01-07
category: essay
price_cents: 0
tags:
  - tag1
  - tag2
excerpt: A brief summary or preview of your writing.
---

Your full writing content goes here.

Each paragraph is separated by a blank line.
```

## Metadata Fields

- **title**: The title of your writing (required)
- **author**: The author's name (defaults to "Musical Universe Factory")
- **date**: Publication date in YYYY-MM-DD format (required)
- **category**: Type of writing - essay, poem, story, article, etc.
- **price_cents**: Price in cents (0 for free, 500 for $5.00, etc.)
- **tags**: List of tags for categorization
- **excerpt**: Short preview text shown in listings

## Categories

Common categories:
- `essay` - Long-form essays
- `poem` - Poetry
- `story` - Fiction or narrative
- `article` - Articles or journalism
- `manifesto` - Manifestos or statements
- `note` - Short notes or thoughts

## Pricing

Set `price_cents: 0` for free writings. For paid content:
- $5.00 = `price_cents: 500`
- $10.00 = `price_cents: 1000`
- $0.99 = `price_cents: 99`

## Example

See `on-creative-sovereignty/writing.txt` for a complete example.

## Publishing

After adding a new writing:
1. The writing will automatically appear on `/writings`
2. Individual page will be available at `/writings/your-slug`
3. No rebuild or restart needed in development
4. Run `bun run build` before deploying to production
