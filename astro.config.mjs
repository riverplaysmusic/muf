// @ts-check
import { defineConfig, envField } from 'astro/config';
import node from '@astrojs/node';

// https://astro.build/config
export default defineConfig({
  output: 'server',
  adapter: node({
    mode: 'standalone',
  }),
  env: {
    schema: {
      PUBLIC_SUPABASE_URL: envField.string({ context: 'client', access: 'public', optional: false }),
      PUBLIC_SUPABASE_ANON_KEY: envField.string({ context: 'client', access: 'public', optional: false }),
    },
  },
});
