#!/usr/bin/env bun

// Upload album file to Supabase Storage
// Usage: bun run scripts/upload-album-file.ts <slug> <file-path>
// Example: bun run scripts/upload-album-file.ts Moon_Goddess ./Moon_Goddess.zip

import { createClient } from '@supabase/supabase-js'
import { readFile } from 'node:fs/promises'

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

// Parse arguments
const slug = process.argv[2]
const filePath = process.argv[3]

if (!slug || !filePath) {
  console.error('Usage: bun run scripts/upload-album-file.ts <slug> <file-path>')
  console.error('Example: bun run scripts/upload-album-file.ts Moon_Goddess ./Moon_Goddess.zip')
  process.exit(1)
}

console.log('======================================================')
console.log('  ALBUM FILE UPLOAD')
console.log('======================================================')
console.log(`Album Slug: ${slug}`)
console.log(`File Path:  ${filePath}`)
console.log('')

async function uploadAlbumFile() {
  console.log('Reading file...')
  const fileBuffer = await readFile(filePath)
  const fileSizeKB = (fileBuffer.byteLength / 1024).toFixed(2)
  const fileSizeMB = (fileBuffer.byteLength / (1024 * 1024)).toFixed(2)

  console.log(`File size: ${fileSizeMB} MB (${fileSizeKB} KB)`)
  console.log('')

  // Storage path: albums/{slug}/release.zip
  const storagePath = `${slug}/release.zip`

  console.log(`Uploading to: albums/${storagePath}`)

  const { data, error } = await supabase.storage
    .from('albums')
    .upload(storagePath, fileBuffer, {
      contentType: 'application/zip',
      upsert: true, // Replace if exists
    })

  if (error) {
    console.error('✗ Upload failed:', error.message)
    process.exit(1)
  }

  console.log('')
  console.log('======================================================')
  console.log('✓ Upload successful!')
  console.log(`  Path: ${data.path}`)
  console.log('======================================================')
}

uploadAlbumFile().catch(err => {
  console.error('Fatal error:', err)
  process.exit(1)
})
