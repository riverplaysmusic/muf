-- MUSICAL UNIVERSE FACTORY - STORAGE RLS POLICIES
-- Controls access to album files in Supabase Storage
-- Philosophy: Database enforces all security, not middleware

-- ============================================================
-- CREATE STORAGE BUCKET (if not exists)
-- ============================================================
-- Note: You can also create this manually in the Supabase dashboard
INSERT INTO storage.buckets (id, name, public)
VALUES ('albums', 'albums', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STORAGE RLS POLICIES
-- ============================================================

-- Allow authenticated users to download albums they've purchased
-- Files are stored at: albums/{slug}/release.zip
-- Access is granted via purchase record in database
CREATE POLICY "Download purchased albums"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'albums'
  AND auth.uid() IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM products p
    JOIN purchases pur ON pur.product_id = p.id
    WHERE pur.user_id = auth.uid()
      AND storage.foldername(name)[1] = p.slug
  )
);

-- Allow service role (server) to upload files
-- This is for admin operations and scripts
CREATE POLICY "Service role can upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'albums' AND auth.role() = 'service_role');

-- Allow service role to delete files (for maintenance)
CREATE POLICY "Service role can delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'albums' AND auth.role() = 'service_role');
