# Product Schema

**Status:** Proposed schema for selling digital content
**Date:** January 2026
**Philosophy:** Braindead simple. Lifetime ownership. RLS-first security.

---

## What This Enables

Sell any digital content with lifetime ownership:
- ✓ Albums (FLAC zips)
- ✓ Individual tracks
- ✓ Books (PDF + ePub)
- ✓ Essays (standalone PDFs)
- ✓ Poems
- ✓ Videos (MP4s)
- ✓ Anything digital

---

## Design Decisions

### 1. **Flat Structure**
No complex hierarchies. A product is a product. An album is a product. A book is a product. Simple.

### 2. **Type Field Instead of Separate Tables**
```sql
type: 'album' | 'track' | 'book' | 'essay' | 'poem' | 'video'
```
One table, multiple types. Easier to query, easier to extend.

### 3. **Separate Files Table**
Products can have multiple formats:
- Book → PDF + ePub
- Album → FLAC + MP3 (future)
- Video → 4K + 1080p (future)

But keep the relationship simple: product → files.

### 4. **RLS-First Security**
File URLs are protected by Row Level Security. Only buyers can access their purchased files. No middleware needed.

### 5. **Lifetime Ownership**
`UNIQUE(user_id, product_id)` - You buy it once, you own it forever. No subscriptions. No recurring charges.

---

## Example Usage

### Creating a Book
```sql
-- Insert creator
INSERT INTO creators (name, bio) VALUES
  ('Hunter S. Thompson', 'Gonzo journalist and writer');

-- Insert product
INSERT INTO products (title, type, description, price_cents, creator_id, release_date) VALUES
  ('Fear and Loathing in the Studio', 'book', 'Gonzo journalism meets music production', 2000, creator_id, '2026-03-01');

-- Insert files
INSERT INTO product_files (product_id, format, file_url, file_size_bytes) VALUES
  (product_id, 'pdf', 'storage/books/fear-loathing.pdf', 5242880),
  (product_id, 'epub', 'storage/books/fear-loathing.epub', 2097152);
```

### Creating an Album
```sql
INSERT INTO products (title, type, description, price_cents, creator_id, release_date) VALUES
  ('Neon Dystopia', 'album', 'Synthwave recorded in isolation', 1500, creator_id, '2026-02-01');

INSERT INTO product_files (product_id, format, file_url, file_size_bytes) VALUES
  (product_id, 'flac', 'storage/albums/neon-dystopia.zip', 524288000);
```

### Recording a Purchase
```sql
INSERT INTO purchases (user_id, product_id, price_paid_cents) VALUES
  (auth.uid(), product_id, 2000);
```

### User's Library Query
```sql
SELECT p.*, pf.format, pf.file_url
FROM purchases pur
JOIN products p ON p.id = pur.product_id
JOIN product_files pf ON pf.product_id = p.id
WHERE pur.user_id = auth.uid()
ORDER BY pur.purchased_at DESC;
```

---

## Future Extensions (If Needed)

### Collections (Optional)
If you want to sell essays individually AND as part of a book:
```sql
CREATE TABLE product_relationships (
  parent_id uuid REFERENCES products(id),
  child_id  uuid REFERENCES products(id),
  position  integer
);
```

But **not recommended initially**. Keep it flat. A book is a book. An essay is an essay.

### Previews/Samples (Optional)
```sql
ALTER TABLE products ADD COLUMN preview_url text;
```
Free preview file for products.

---

## Migration Path

When ready to implement:
1. Run `products-schema.sql` in Supabase SQL editor
2. Create storage buckets for files
3. Build simple product catalog UI
4. Integrate Stripe for payments
5. Handle purchase flow with RLS protection

---

**Remember:** The label comes first, the software second, or not at all.
