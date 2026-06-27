// Rasterize the brand SVGs into the PNGs that flutter_launcher_icons and
// flutter_native_splash consume. Run: cd ops/icongen && npm i && node gen.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const icons = join(here, '..', '..', 'assets', 'icons');

async function render(svg, out, size, bg) {
  let img = sharp(join(icons, svg)).resize(size, size);
  if (bg) img = img.flatten({ background: bg });
  await img.png().toFile(join(icons, out));
  console.log('wrote', out);
}

await render('icon-full.svg', 'icon-1024.png', 1024);
await render('icon-foreground.svg', 'icon-foreground-1024.png', 1024);
// splash logo: foreground on transparent, smaller export
await render('icon-foreground.svg', 'splash-logo.png', 512);
console.log('done');
