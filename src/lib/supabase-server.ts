// Server-side Supabase client with service role key
// This client bypasses RLS and should only be used in server contexts
// (API routes, webhooks, scripts)

import { createClient } from '@supabase/supabase-js'
import { SUPABASE_SERVICE_KEY } from 'astro:env/server'
import { PUBLIC_SUPABASE_URL } from 'astro:env/client'

// Create admin client (bypasses RLS)
export const supabaseAdmin = createClient(PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
})
