/**
 * TypeScript interfaces for content types
 */

export interface Track {
  name: string;
  credits?: string[];
}

export interface Album {
  title: string;
  date: string;
  priceCents: number;
  length: string;
  recordingStudio: string;
  label: string;
  website: string;
  copyright: string;
  body: string;
  tracks: Track[];
  credits: string[];
  artwork: string | null;
}

export interface Writing {
  title: string;
  author: string;
  date: string;
  priceCents: number;
  body: string;
  artwork: string | null;
}

export interface Artwork {
  title: string;
  date: string;
  priceCents: number;
  format: string;
  fileSize: string;
  contents: string;
  dimensions: string;
  copyright: string;
  body: string;
  preview: string | null;
}

export interface Education {
  title: string;
  date: string;
  priceCents: number;
  body: string;
  preview: string | null;
}
