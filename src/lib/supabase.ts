import { createClient } from '@supabase/supabase-js'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PKEY } from 'astro:env/client'

export const supabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PKEY)
