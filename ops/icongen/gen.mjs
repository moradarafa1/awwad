// Rasterize the brand assets into the PNGs that flutter_launcher_icons and
// flutter_native_splash consume. Run: cd ops/icongen && npm i && node gen.mjs
//
// THE MASTER IS THE PLANT IMAGE, NOT A DRAWING OF IT.
// app/assets/logo/sprout.png is the plant the owner approved (the one shown
// next to «أبني عادة جديدة» inside the app). The owner asked for that exact
// artwork as the icon ("هي هي دي، مش تصنعها من جديد"), so every icon below
// COMPOSITES that PNG onto the brand tile instead of re-drawing it in SVG.
// Do not replace this with a hand-written SVG seedling again.
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { writeFile } from 'node:fs/promises';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const icons = join(root, 'assets', 'icons');
const plant = join(root, 'app', 'assets', 'logo', 'sprout.png');

const BG = '#12161F'; // brand tile
const TILE = 1024;
const RADIUS = 230;

const roundedTile = (size, radius) => Buffer.from(
  `<svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
     <rect width="${size}" height="${size}" rx="${radius}" fill="${BG}"/>
   </svg>`);

/// The plant resized to [inner] px, centered on a [size] px canvas.
async function plantOn(size, inner, { tile = false } = {}) {
  const leaf = await sharp(plant)
    .resize(inner, inner, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
  const base = tile
    ? sharp(roundedTile(size, Math.round((RADIUS / TILE) * size)))
    : sharp({
        create: {
          width: size,
          height: size,
          channels: 4,
          background: { r: 0, g: 0, b: 0, alpha: 0 },
        },
      });
  const off = Math.round((size - inner) / 2);
  return base.composite([{ input: leaf, top: off, left: off }]).png().toBuffer();
}

const write = async (buf, out) => {
  await writeFile(join(icons, out), buf);
  console.log('wrote', out);
};

// Full app icon: the plant on the dark rounded tile.
await write(await plantOn(TILE, 700, { tile: true }), 'icon-1024.png');
// Android adaptive foreground: plant only, inside the 66% safe zone.
await write(await plantOn(TILE, 580), 'icon-foreground-1024.png');
// Splash: plant only, transparent.
await write(await plantOn(512, 400), 'splash-logo.png');
console.log('done');
