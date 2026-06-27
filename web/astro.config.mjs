import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// NOTE: update `site` to the real apex domain once the domain is purchased.
// The Flutter web app lives on a separate subdomain (app.<domain>) with noindex,
// so it is intentionally NOT part of this marketing site's sitemap.
export default defineConfig({
  site: 'https://awwad.app',
  trailingSlash: 'ignore',
  i18n: {
    defaultLocale: 'ar',
    locales: ['ar', 'en', 'fr'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [sitemap()],
});
