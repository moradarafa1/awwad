// Store-screenshot capture (MANDATE_PLAN SA2). Drives the LIVE web build of
// the app in a real Chrome at Play's phone resolution and writes PNGs to
// assets/screenshots/. These are genuine captures of the shipping app, not
// mockups: store policy requires screenshots to represent the real product.
//
// Usage (Chrome must be installed; puppeteer-core drives it, nothing is
// downloaded):  node ops/shotgen/capture.mjs [--locale ar] [--url ...]
//
// The walk is deliberately explicit rather than clever: onboarding changes
// rarely, and a hard-coded path is easier to repair than a heuristic.

import fs from 'node:fs';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = 'D:/Claude/awwad/assets/screenshots';
const args = process.argv.slice(2);
const argOf = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};
const LOCALE = argOf('locale', 'ar');
const URL_ = argOf('url', 'https://moradarafa1.github.io/app/');

// CSS viewport 375x812 (the aspect the tap fractions below were calibrated
// against) captured at 3x = 1125x2436 PNGs, comfortably inside Play's
// 320-3840px range and a standard tall-phone aspect.
const CSS_W = 375, CSS_H = 812;
const SCALE = 3;
const W = CSS_W * SCALE, H = CSS_H * SCALE;

const LOCALE_BUTTON = { ar: 0, en: 1, fr: 2 };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function shot(page, name) {
  fs.mkdirSync(path.join(OUT, LOCALE), { recursive: true });
  const file = path.join(OUT, LOCALE, `${name}.png`);
  await page.screenshot({ path: file });
  const kb = Math.round(fs.statSync(file).size / 1024);
  console.log(`  saved ${LOCALE}/${name}.png (${kb} KB)`);
}

/// Clicks by visible text using the accessibility-free approach: Flutter web
/// renders to canvas, so text queries do not work. We click by COORDINATES
/// derived from the CSS viewport, which is stable for this layout.
const RTL = LOCALE === 'ar';
/// x-fractions below are written for the ARABIC (RTL) layout; mirror them
/// for LTR locales, where every row is laid out from the other side.
const fx = (f) => (RTL ? f : 1 - f);

async function tap(page, xFrac, yFrac, label) {
  const x = Math.round(CSS_W * xFrac);
  const y = Math.round(CSS_H * yFrac);
  await page.mouse.click(x, y);
  console.log(`  tap ${label} at (${x},${y})`);
  await sleep(900);
}

/// Waits for the Flutter engine to replace the splash with real UI. A fixed
/// sleep is not enough on a cold load and silently produced a whole run of
/// splash-screen captures. The splash is nearly flat dark, so its PNG is tiny
/// (~30 KB) while any real screen is several hundred KB: that size gap is a
/// reliable readiness signal for a canvas we cannot inspect via the DOM.
async function waitForBoot(page, timeoutMs = 90000) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    const buf = await page.screenshot({ encoding: 'binary' });
    if (buf.length > 120 * 1024) {
      await sleep(1200); // let the entry animation settle
      console.log();
      return;
    }
    await sleep(2000);
  }
  throw new Error('app did not finish booting within ' + timeoutMs + 'ms');
}

const main = async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: [`--window-size=${W / SCALE},${H / SCALE}`, '--hide-scrollbars'],
  });
  const page = await browser.newPage();
  await page.setViewport({
    width: CSS_W,
    height: CSS_H,
    deviceScaleFactor: SCALE,
    isMobile: true,
    hasTouch: true,
  });

  console.log(`opening ${URL_} (${LOCALE})`);
  await page.goto(URL_, { waitUntil: 'networkidle2', timeout: 90000 });
  await waitForBoot(page);

  // 1. Language screen (the real first impression).
  await shot(page, '01-language');

  // Pick the language, then walk to the habit catalog.
  const langY = [0.546, 0.628, 0.709][LOCALE_BUTTON[LOCALE]];
  await tap(page, 0.5, langY, 'language');
  await shot(page, '02-welcome');

  await tap(page, 0.5, 0.878, 'continue as guest');
  await sleep(1200);
  await shot(page, '03-survey');

  await tap(page, fx(0.88), 0.169, 'gender');
  await tap(page, 0.5, 0.95, 'next');
  await shot(page, '04-track');

  await tap(page, 0.5, 0.165, 'break track');
  await tap(page, fx(0.38), 0.95, 'next');
  await sleep(700);
  await shot(page, '05-catalog');

  await tap(page, fx(0.73), 0.338, 'quit smoking');
  await tap(page, fx(0.38), 0.95, 'next');
  await sleep(700);
  await shot(page, '06-setup');

  await tap(page, fx(0.38), 0.95, 'start');
  await sleep(1600);
  await shot(page, '07-today');

  // Bottom nav: stats, badges, pomodoro, settings (5 slots).
  const NAV_Y = 0.948;
  await tap(page, fx(0.742), NAV_Y, 'stats');
  await sleep(900);
  await shot(page, '08-stats');

  await tap(page, fx(0.58), NAV_Y, 'badges');
  await sleep(900);
  await shot(page, '09-badges');

  await tap(page, fx(0.258), NAV_Y, 'pomodoro');
  await sleep(900);
  await shot(page, '10-pomodoro');

  await tap(page, fx(0.42), NAV_Y, 'truce (SOS)');
  await sleep(1500);
  await shot(page, '11-sos');

  await browser.close();
  console.log('done');
};

main().catch((e) => {
  console.error('capture failed:', e.message);
  process.exit(1);
});
