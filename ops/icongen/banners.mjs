// og-image (1200x630) + Play feature graphic (1024x500): brand background,
// the SAME plant image (never a redraw), the wordmark and the slogan.
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const plant = join(root, 'app', 'assets', 'logo', 'sprout.png');

// Reem Kufi is not installed system-wide; the wordmark is drawn as text in the
// SVG layer with a generic Arabic-capable family, which renders via fontconfig.
const layer = (w, h, plantW) => Buffer.from(`
<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="g" cx="78%" cy="0%" r="80%">
      <stop offset="0%" stop-color="#2dd4bf" stop-opacity="0.16"/>
      <stop offset="100%" stop-color="#0a0e14" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="${w}" height="${h}" fill="#0a0e14"/>
  <rect width="${w}" height="${h}" fill="url(#g)"/>
  <text x="${w / 2}" y="${h * 0.66}" text-anchor="middle"
        font-family="Cairo, Tahoma, DejaVu Sans, sans-serif"
        font-size="${Math.round(h * 0.16)}" font-weight="800" fill="#f3f8ff">عوّاد</text>
  <text x="${w / 2}" y="${h * 0.80}" text-anchor="middle"
        font-family="Cairo, Tahoma, DejaVu Sans, sans-serif"
        font-size="${Math.round(h * 0.062)}" fill="#2dd4bf">رفيقُ مَن زانَ عُمرَهُ، وحَسُنَ عملُهُ</text>
</svg>`);

async function banner(w, h, dest) {
  const plantW = Math.round(h * 0.34);
  const leaf = await sharp(plant).resize(plantW, plantW, { fit: 'contain',
    background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
  await sharp(layer(w, h))
    .composite([{ input: leaf, top: Math.round(h * 0.10), left: Math.round((w - plantW) / 2) }])
    .png()
    .toFile(dest);
  console.log('wrote', dest.replace(root, ''));
}

await banner(1200, 630, join(root, 'web', 'public', 'og-image.png'));
await banner(1024, 500, join(root, 'assets', 'store', 'play-feature-1024x500.png'));
console.log('done');
