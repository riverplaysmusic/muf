import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";
import { CONTENT_TYPE_CONFIGS, type ContentTypeConfig } from "./constants";

export interface ContentItem {
  type: 'album' | 'writing' | 'artwork' | 'education';
  slug: string;
  title: string;
  date: string;
  priceCents: number;
  image: string | null;
  url: string;
}

interface Frontmatter {
  title: string;
  date: string;
  priceCents: number;
  published: boolean;
}

/**
 * Extracts frontmatter string from content
 */
export function extractFrontmatter(content: string): string | null {
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  return frontmatterMatch ? frontmatterMatch[1] : null;
}

/**
 * Extracts body content (everything after frontmatter)
 */
export function extractBody(content: string): string {
  return content.replace(/^---\n[\s\S]*?\n---\n/, '').trim();
}

/**
 * Gets a string field from frontmatter
 */
export function getField(frontmatter: string, field: string, defaultValue: string = ''): string {
  const match = frontmatter.match(new RegExp(`${field}:\\s*(.+)`));
  return match ? match[1] : defaultValue;
}

/**
 * Gets an integer field from frontmatter
 */
export function getIntField(frontmatter: string, field: string, defaultValue: number = 0): number {
  const match = frontmatter.match(new RegExp(`${field}:\\s*(\\d+)`));
  return match ? parseInt(match[1]) : defaultValue;
}

/**
 * Gets a boolean field from frontmatter
 */
export function getBoolField(frontmatter: string, field: string, defaultValue: boolean = false): boolean {
  const match = frontmatter.match(new RegExp(`${field}:\\s*(true|false)`));
  return match ? match[1] === 'true' : defaultValue;
}

/**
 * Parses YAML frontmatter from content string
 */
export function parseFrontmatter(content: string): Frontmatter | null {
  const frontmatter = extractFrontmatter(content);
  if (!frontmatter) return null;

  const title = getField(frontmatter, 'title', 'Untitled');
  const date = getField(frontmatter, 'date');
  const priceCents = getIntField(frontmatter, 'price_cents');
  const published = getBoolField(frontmatter, 'published');

  return { title, date, priceCents, published };
}

/**
 * Finds image file matching pattern
 */
export function findImage(files: string[], pattern: RegExp): string | null {
  const image = files.find((f) => pattern.test(f));
  return image || null;
}

/**
 * Generic content item parser - consolidates parseAlbum, parseWriting, parseArtwork, parseEducation
 */
async function parseContentItem(
  itemPath: string,
  slug: string,
  files: string[],
  config: ContentTypeConfig
): Promise<ContentItem | null> {
  if (!files.includes(config.filename)) return null;

  try {
    const content = await readFile(join(itemPath, config.filename), 'utf-8');
    const frontmatter = parseFrontmatter(content);
    if (!frontmatter || !frontmatter.published) return null;

    const image = findImage(files, config.imagePattern);
    const imageFile = image ? `/slugs/${slug}/${image}` : null;

    return {
      type: config.type,
      slug,
      title: frontmatter.title,
      date: frontmatter.date,
      priceCents: frontmatter.priceCents,
      image: imageFile,
      url: `/${slug}`
    };
  } catch {
    return null;
  }
}

/**
 * Parses all content types from a slug directory
 */
export async function parseSlugContent(slugsDir: string, slug: string): Promise<ContentItem[]> {
  const itemPath = join(slugsDir, slug);
  const files = await readdir(itemPath);

  const items: ContentItem[] = [];

  // Parse each content type using the generic parser
  for (const config of Object.values(CONTENT_TYPE_CONFIGS)) {
    const item = await parseContentItem(itemPath, slug, files, config);
    if (item) items.push(item);
  }

  return items;
}
