// Site + store icons, all derived from the SAME plant image as the app icon
// (app/assets/logo/sprout.png). See gen.mjs: never redraw the plant.
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const iconFull = join(root, 'assets', 'icons', 'icon-1024.png');   // plant on tile
const plant = join(root, 'app', 'assets', 'logo', 'sprout.png');   // plant alone
const site = join(root, 'web', 'public');
const store = join(root, 'assets', 'store');

const out = async (src, dest, size) => {
  await sharp(src).resize(size, size).png().toFile(dest);
  console.log('wrote', dest.replace(root, ''), size);
};

await out(iconFull, join(site, 'favicon.png'), 64);
await out(iconFull, join(site, 'icon-192.png'), 192);
await out(iconFull, join(site, 'icon-512.png'), 512);
await out(iconFull, join(site, 'apple-touch-icon.png'), 180);
await out(plant, join(site, 'logo-mark.png'), 64);     // transparent mark in the nav
await out(iconFull, join(store, 'play-icon-512.png'), 512);
console.log('done');
