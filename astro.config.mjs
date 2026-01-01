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
      RESEND_API_KEY: envField.string({
        context: 'server',
        access: 'secret',
      }),
      SUPABASE_CONNECTION_STRING: envField.string({
        context: 'server',
        access: 'secret',
      }),
      PUBLIC_SUPABASE_URL: envField.string({
        context: 'client',
        access: 'public',
      }),
      PUBLIC_SUPABASE_PUBLISHABLE_KEY: envField.string({
        context: 'client',
        access: 'public',
      }),
    },
  },
  vite: {
    server: {
      allowedHosts: ['honeycomb'],
    },
  },
});
