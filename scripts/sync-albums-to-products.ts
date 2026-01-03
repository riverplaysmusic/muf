#!/usr/bin/env bun

// Sync albums from filesystem to database
// Reads public/albums/*/album.txt files and creates/updates products

import { createClient } from '@supabase/supabase-js'
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'

// Load environment
const supabaseUrl = process.env.PUBLIC_SUPABASE_URL
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('ERROR: Missing Supabase environment variables')
  console.error('Required: PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_KEY')
  process.exit(1)
}

// Create admin client (bypasses RLS)
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
})

console.log('======================================================')
console.log('  ALBUM TO PRODUCTS SYNC')
console.log('======================================================')
console.log('')

async function syncAlbums() {
  const albumsDir = join(process.cwd(), 'public', 'albums')
  const folders = await readdir(albumsDir, { withFileTypes: true })

  let synced = 0
  let failed = 0

  for (const folder of folders) {
    if (!folder.isDirectory()) continue

    const slug = folder.name
    const albumPath = join(albumsDir, slug)

    try {
      // Read album.txt
      const albumContent = await readFile(join(albumPath, 'album.txt'), 'utf-8')
      const frontmatterMatch = albumContent.match(/^---\n([\s\S]*?)\n---/)

      if (!frontmatterMatch) {
        console.log(`⚠ Skipping ${slug}: No frontmatter found`)
        continue
      }

      const frontmatter = frontmatterMatch[1]

      // Parse metadata using regex (following existing pattern)
      const title = frontmatter.match(/title:\s*(.+)/)?.[1]?.trim() || 'Untitled'
      const artist = frontmatter.match(/artist:\s*(.+)/)?.[1]?.trim() || 'Unknown Artist'
      const priceCents = parseInt(frontmatter.match(/price_cents:\s*(\d+)/)?.[1] || '0')
      const date = frontmatter.match(/date:\s*(.+)/)?.[1]?.trim() || null

      // Extract description (everything after frontmatter)
      const body = albumContent.replace(/^---\n[\s\S]*?\n---\n/, '').trim()

      console.log(`Processing: ${slug}`)
      console.log(`  Title: ${title}`)
      console.log(`  Artist: ${artist}`)
      console.log(`  Price: $${(priceCents / 100).toFixed(2)}`)

      // Find or create creator
      let { data: creator, error: creatorError } = await supabase
        .from('creators')
        .select('id')
        .eq('name', artist)
        .single()

      if (!creator) {
        console.log(`  Creating creator: ${artist}`)
        const { data: newCreator, error } = await supabase
          .from('creators')
          .insert({ name: artist })
          .select('id')
          .single()

        if (error) {
          console.error(`  ✗ Failed to create creator:`, error.message)
          failed++
          continue
        }

        creator = newCreator
      }

      // Upsert product
      const { data: product, error: productError } = await supabase
        .from('products')
        .upsert({
          slug,
          title,
          type: 'album',
          description: body,
          price_cents: priceCents,
          creator_id: creator.id,
          release_date: date,
        }, {
          onConflict: 'slug',
          ignoreDuplicates: false, // Update if exists
        })
        .select('id')
        .single()

      if (productError) {
        console.error(`  ✗ Failed to upsert product:`, productError.message)
        failed++
        continue
      }

      // Create product_files record for FLAC download
      // Path convention: albums/{slug}/release.zip
      const { error: fileError } = await supabase
        .from('product_files')
        .upsert({
          product_id: product.id,
          format: 'flac',
          file_url: `${slug}/release.zip`,
        }, {
          onConflict: 'product_id,format',
          ignoreDuplicates: false,
        })

      if (fileError) {
        console.error(`  ⚠ Failed to create file record:`, fileError.message)
      }

      console.log(`  ✓ Synced successfully`)
      synced++

    } catch (err: any) {
      console.error(`  ✗ Failed to sync ${slug}:`, err.message)
      failed++
    }

    console.log('')
  }

  console.log('======================================================')
  console.log(`✓ Sync complete: ${synced} synced, ${failed} failed`)
  console.log('======================================================')
}

syncAlbums().catch(err => {
  console.error('Fatal error:', err)
  process.exit(1)
})
