# fontgen

Regenerates the self-hosted `@font-face` block for the site. The unicode-range
strings are far too long to retype by hand without introducing a typo, so they
are always generated, never edited.

```bash
# 1. get the Google Fonts CSS (a modern UA is required, or you get ttf URLs)
curl -sSL -H "User-Agent: Mozilla/5.0 Chrome/126" \
  "https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap" \
  -o ipsa.css

# 2. download the woff2 subsets + emit ops/fontface.generated.css
node ops/fontgen/fetch_fonts.mjs ipsa.css web/public/fonts
```

Then paste `ops/fontface.generated.css` into the `<style>` block in
`web/src/layouts/Base.astro`.

The family is IBM Plex Sans Arabic, SIL OFL 1.1. Keep `OFL-IBMPlexSansArabic.txt`
next to the font files: the licence requires the copy to travel with them.
