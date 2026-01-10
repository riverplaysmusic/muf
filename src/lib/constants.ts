/**
 * Content type definitions and file patterns
 */

export const FILE_PATTERNS = {
  artwork: /^artwork\.(jpg|jpeg|png|svg|webp)$/i,
  preview: /^preview\.(jpg|jpeg|png|svg|webp)$/i,
} as const;

export const CONTENT_FILES = {
  album: 'album.txt',
  writing: 'writing.txt',
  item: 'item.txt',
  course: 'course.txt',
  video: 'video.txt',
} as const;

export interface ContentTypeConfig {
  filename: string;
  type: 'album' | 'writing' | 'artwork' | 'education';
  imagePattern: RegExp;
}

export const CONTENT_TYPE_CONFIGS: Record<string, ContentTypeConfig> = {
  album: {
    filename: CONTENT_FILES.album,
    type: 'album',
    imagePattern: FILE_PATTERNS.artwork,
  },
  writing: {
    filename: CONTENT_FILES.writing,
    type: 'writing',
    imagePattern: FILE_PATTERNS.artwork,
  },
  artwork: {
    filename: CONTENT_FILES.item,
    type: 'artwork',
    imagePattern: FILE_PATTERNS.preview,
  },
  education: {
    filename: CONTENT_FILES.course,
    type: 'education',
    imagePattern: FILE_PATTERNS.preview,
  },
} as const;
