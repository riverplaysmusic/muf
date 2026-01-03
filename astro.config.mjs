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
      SUPABASE_CONNECTION_STRING: envField.string({
        context: 'server',
        access: 'secret',
        optional: true,
      }),
      SUPABASE_SERVICE_KEY: envField.string({
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
      STRIPE_SECRET_KEY: envField.string({
        context: 'server',
        access: 'secret',
      }),
      STRIPE_WEBHOOK_SECRET: envField.string({
        context: 'server',
        access: 'secret',
      }),
    },
  },
  vite: {
    server: {
      allowedHosts: ['honeycomb'],
    },
  },
});
