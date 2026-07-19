import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// NOTE: update `site` to the real apex domain once the domain is purchased
// (also update public/robots.txt and WEB_APP_URL in src/content/site.js).
// The Flutter web app lives on its own Netlify site (awwad-app) with noindex,
// so it is intentionally NOT part of this marketing site's sitemap.
export default defineConfig({
  site: 'https://moradarafa1.github.io',
  // 'always': GitHub Pages 301-redirects extensionless URLs to the slashed
  // directory form, so slashless canonicals contradicted the served URLs
  // (and the sitemap). Slashed everywhere = zero redirect hops.
  trailingSlash: 'always',
  i18n: {
    defaultLocale: 'ar',
    locales: ['ar', 'en', 'fr'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: 'ar',
        locales: { ar: 'ar', en: 'en', fr: 'fr' },
      },
    }),
  ],
});
