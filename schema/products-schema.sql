-- MUSICAL UNIVERSE FACTORY - PRODUCTS SCHEMA
-- Designed for selling digital content: albums, tracks, books, essays, poems, videos
-- Philosophy: Braindead simple. Lifetime ownership. No subscriptions.

-- ============================================================
-- CREATORS (Artists, Writers, Directors)
-- ============================================================
CREATE TABLE creators (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  bio         text,
  avatar_url  text,
  created_at  timestamptz DEFAULT now()
);

-- ============================================================
-- PRODUCTS (What people buy)
-- ============================================================
CREATE TABLE products (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title           text NOT NULL,
  type            text NOT NULL,  -- 'album' | 'track' | 'book' | 'essay' | 'poem' | 'video'
  description     text,
  price_cents     integer NOT NULL,
  creator_id      uuid REFERENCES creators(id) ON DELETE CASCADE,
  cover_image_url text,
  release_date    date,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_products_type ON products(type);
CREATE INDEX idx_products_creator ON products(creator_id);

-- ============================================================
-- PRODUCT_FILES (The actual downloadable content)
-- ============================================================
CREATE TABLE product_files (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id       uuid REFERENCES products(id) ON DELETE CASCADE,
  format           text NOT NULL,  -- 'flac' | 'pdf' | 'epub' | 'mp4'
  file_url         text NOT NULL,  -- Supabase Storage URL
  file_size_bytes  bigint,
  created_at       timestamptz DEFAULT now()
);

CREATE INDEX idx_product_files_product ON product_files(product_id);

-- ============================================================
-- PURCHASES (Who owns what - lifetime ownership)
-- ============================================================
CREATE TABLE purchases (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id       uuid REFERENCES products(id) ON DELETE CASCADE,
  price_paid_cents integer NOT NULL,
  purchased_at     timestamptz DEFAULT now(),

  UNIQUE(user_id, product_id)  -- One purchase per user per product
);

CREATE INDEX idx_purchases_user ON purchases(user_id);
CREATE INDEX idx_purchases_product ON purchases(product_id);

-- ============================================================
-- RLS POLICIES - Trust the database, not the middleware
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE creators ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Anyone can view creators and products (public catalog)
CREATE POLICY "Public creators" ON creators
  FOR SELECT USING (true);

CREATE POLICY "Public products" ON products
  FOR SELECT USING (true);

-- Only buyers can access file URLs (lifetime ownership)
CREATE POLICY "Purchased files only" ON product_files
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM purchases
      WHERE purchases.product_id = product_files.product_id
        AND purchases.user_id = auth.uid()
    )
  );

-- Users can view their own purchases
CREATE POLICY "Own purchases" ON purchases
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own purchases (via Stripe webhook or checkout flow)
CREATE POLICY "Create own purchase" ON purchases
  FOR INSERT WITH CHECK (auth.uid() = user_id);
