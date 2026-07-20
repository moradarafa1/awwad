// Builds the SECOND marketing kit: 50 ad posts about what shipped after the
// first kit (2026-07-14). The first kit is NOT touched; this writes a new file.
//
// Path: Node -> RTL HTML -> Chrome headless print. That is the reliable way to
// get correct Arabic shaping and right-to-left layout into a PDF on this
// machine (there is no python/reportlab here, and Arabic in most PDF libraries
// comes out disconnected or reversed).
//
// Fonts are the CURRENT brand faces, read from the repo as base64 data URIs:
// Tajawal for headings, IBM Plex Sans Arabic for body. They are embedded
// rather than linked so the PDF renders identically anywhere, and so the build
// makes no network request.
//
//   node ops/marketing/build_pdf_v2.mjs
import fs from 'node:fs';
import path from 'node:path';
import { POSTS, ANGLES } from './posts_v2.js';

const { default: puppeteer } = await import(
  'file:///D:/Claude/awwad/ops/shotgen/node_modules/puppeteer-core/lib/puppeteer/puppeteer-core.js'
);

const ROOT = 'D:/Claude/awwad';
const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = path.join(ROOT, 'docs/marketing/Awwad_Marketing_Kit_v2_50_posts.pdf');
const WEB_APP = 'https://moradarafa1.github.io/app/';
const SITE = 'https://moradarafa1.github.io';

const b64 = (p) => fs.readFileSync(path.join(ROOT, p)).toString('base64');
const fontFace = (family, file, weight) => `
  @font-face {
    font-family: '${family}';
    font-weight: ${weight};
    font-style: normal;
    src: url(data:font/ttf;base64,${b64(file)}) format('truetype');
  }`;

const fonts = [
  fontFace('Tajawal', 'app/assets/fonts/Tajawal-Bold.ttf', 700),
  fontFace('Tajawal', 'app/assets/fonts/Tajawal-ExtraBold.ttf', 800),
  fontFace('Plex', 'app/assets/fonts/IBMPlexSansArabic-Regular.ttf', 400),
  fontFace('Plex', 'app/assets/fonts/IBMPlexSansArabic-Medium.ttf', 500),
  fontFace('Plex', 'app/assets/fonts/IBMPlexSansArabic-Bold.ttf', 700),
].join('\n');

const logo = b64('web/public/icon-512.png');

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const para = (s) => esc(s).split('\n').map((l) => `<p>${l}</p>`).join('');

const byAngle = ANGLES.map((a) => ({
  ...a,
  posts: POSTS.filter((p) => p.angle === a.id),
}));

// Sanity: the owner asked for 50, and a silently short deck is worse than a
// loud failure.
const total = POSTS.length;
if (total !== 50) throw new Error(`expected 50 posts, found ${total}`);
const orphan = POSTS.filter((p) => !ANGLES.some((a) => a.id === p.angle));
if (orphan.length) throw new Error(`posts with an unknown angle: ${orphan.length}`);
if (JSON.stringify(POSTS).includes('—')) throw new Error('an em-dash slipped into the copy');

let n = 0;
const sections = byAngle.map((a, ai) => `
  <section class="angle">
    <div class="angle-head">
      <div class="angle-num">${String(ai + 1).padStart(2, '0')}</div>
      <div>
        <h2>${esc(a.name)}</h2>
        <div class="angle-note">${esc(a.note)}</div>
      </div>
    </div>
    ${a.posts.map((p) => {
      n += 1;
      return `
      <article class="post">
        <div class="post-num">${n}</div>
        <div class="post-body">
          <div class="hook">${esc(p.hook)}</div>
          <div class="text">${para(p.body)}</div>
          <div class="cta">${esc(p.cta)}</div>
          <div class="meta">
            <span class="tags">${p.tags.map((t) => '#' + esc(t)).join('  ')}</span>
            <span class="feat">الميزة: ${esc(p.feature)}</span>
          </div>
        </div>
      </article>`;
    }).join('')}
  </section>`).join('');

const html = `<!doctype html>
<html dir="rtl" lang="ar"><head><meta charset="utf-8">
<style>
${fonts}
  @page { size: A4; margin: 16mm 14mm; }
  * { box-sizing: border-box; }
  body { font-family: 'Plex', sans-serif; color: #16202b; margin: 0; line-height: 1.85; font-size: 11.5pt; }
  h1, h2, .hook, .angle-num, .post-num { font-family: 'Tajawal', sans-serif; }

  .cover { height: 252mm; display: flex; flex-direction: column; justify-content: center;
           align-items: center; text-align: center; page-break-after: always; }
  .cover img { width: 96px; height: 96px; }
  .cover h1 { font-size: 34pt; font-weight: 800; margin: 18px 0 4px; color: #0b3b34; }
  .cover .sub { font-size: 13pt; color: #2f7d6f; font-weight: 700; }
  .cover .rule { width: 70px; height: 4px; background: #2dd4bf; border-radius: 3px; margin: 22px 0; }
  .cover .kicker { font-size: 17pt; font-weight: 700; color: #16202b; }
  .cover .note { font-size: 10.5pt; color: #5c6b7a; max-width: 118mm; margin-top: 14px; }

  .intro { page-break-after: always; }
  .intro h2 { font-size: 18pt; color: #0b3b34; margin-bottom: 2px; }
  .intro ul { padding-inline-start: 18px; }
  .intro li { margin-bottom: 5px; }
  .rulesbox { border: 1.5px solid #2dd4bf; background: #f2fbf9; border-radius: 10px;
              padding: 12px 16px; margin-top: 14px; }

  .angle { page-break-before: always; }
  .angle-head { display: flex; gap: 12px; align-items: center; border-bottom: 2.5px solid #2dd4bf;
                padding-bottom: 8px; margin-bottom: 14px; }
  .angle-num { font-size: 26pt; font-weight: 800; color: #2dd4bf; line-height: 1; }
  .angle h2 { font-size: 16pt; margin: 0; color: #0b3b34; }
  .angle-note { font-size: 9.5pt; color: #5c6b7a; }

  .post { display: flex; gap: 10px; page-break-inside: avoid; margin-bottom: 13px;
          border: 1px solid #dde5ec; border-radius: 10px; padding: 11px 13px; }
  .post-num { flex: none; width: 26px; height: 26px; border-radius: 50%; background: #0b3b34;
              color: #fff; font-size: 11pt; font-weight: 700; display: flex;
              align-items: center; justify-content: center; }
  .post-body { flex: 1; }
  .hook { font-size: 13pt; font-weight: 800; color: #0b3b34; line-height: 1.5; }
  .text p { margin: 5px 0 0; }
  .cta { margin-top: 7px; font-weight: 700; color: #12766a; }
  .meta { margin-top: 7px; padding-top: 6px; border-top: 1px dashed #dde5ec;
          display: flex; justify-content: space-between; gap: 10px; font-size: 8.5pt; }
  .tags { color: #2f7d6f; font-weight: 500; }
  .feat { color: #93a2b1; direction: ltr; text-align: left; }
</style></head><body>

<div class="cover">
  <img src="data:image/png;base64,${logo}" alt="">
  <h1>عوّاد</h1>
  <div class="sub">رفيقُ مَن زانَ عُمرَهُ، وحَسُنَ عملُهُ</div>
  <div class="rule"></div>
  <div class="kicker">خمسون بوستاً إعلانياً, الإصدار الثاني</div>
  <div class="note">
    ملفٌ مستقلّ عن الإصدار الأول ولا يلغيه. كل بوست هنا مبنيّ على ميزةٍ
    استُحدثت بعد إصدار الملف الأول، ومكتوبٌ بعشر زوايا جديدة.
  </div>
</div>

<div class="intro">
  <h2>كيف تستعمل هذا الملف</h2>
  <p>خمسون بوستاً موزّعة على عشر زوايا، خمسة بوستات لكل زاوية. كل بوست مكتوب
  جاهزاً للنشر: سطر أول يوقف التمرير، ثم متن، ثم دعوة، ثم وسوم مقترحة.</p>
  <p>السطر الأخير في كل بوست يذكر الميزة التي يستند إليها. هو للمراجعة الداخلية
  فقط، ولا يُنشر. فائدته أن تتحقق قبل النشر أن ما نَعِد به موجودٌ فعلاً.</p>

  <h2>ما الجديد الذي تدور حوله هذه البوستات</h2>
  <ul>
    <li>مواقيت الصلاة محسوبةً على الجهاز دون إنترنت، مع تعديل دقائق كل صلاة على حدة.</li>
    <li>الأذان بصوتٍ حقيقي في وقته، يعمل والتطبيق مغلق وبلا اتصال، ويمرّ في وضع عدم الإزعاج.</li>
    <li>راديو مباشر للحديث والسنة، مع تسجيل الورد تلقائياً بعد استماعٍ حقيقي.</li>
    <li>القرآن الصوتي، وتسجيل الورد تلقائياً كذلك.</li>
    <li>ودجت على الشاشة الرئيسية تعرض السلسلة وتسجّل اليوم بضغطة.</li>
    <li>مراقبة استخدام الهاتف: الوقت وعدد مرات الفتح لكل تطبيق، وحدود يومية، وتنبيه يعمل والتطبيق مغلق.</li>
    <li>المسبحة، وقوة العادة، وحلقة نتيجة «هُدنة»، والتقرير الشهري.</li>
    <li>حذف الحساب من داخل التطبيق، ووضع الزائر بلا حساب أصلاً.</li>
    <li>هويّة بصرية جديدة: نظام خطّين وأيقونات موحّدة بدل الرموز التعبيرية.</li>
  </ul>

  <div class="rulesbox">
    <h2 style="margin-top:0">قواعد التزمنا بها في الكتابة</h2>
    <ul style="margin-bottom:0">
      <li>لا وعد بما لا يفعله التطبيق اليوم.</li>
      <li>لا ادّعاء طبيّ ولا علاجيّ. عوّاد أداة متابعة ودعم سلوكي.</li>
      <li>لا فتوى ولا حكم شرعي، وكل ما يتصل بالدين اختياريّ في التطبيق.</li>
      <li>لا دعوة للتحميل من المتاجر, لأن النشر عليها لم يتمّ بعد. الدعوة إلى
      إصدار الويب, وهو يعمل اليوم: <span style="direction:ltr;display:inline-block">${WEB_APP}</span></li>
      <li>عربية فصحى، ولا شرطة طويلة.</li>
    </ul>
  </div>
</div>

${sections}

<div class="angle">
  <div class="angle-head"><div class="angle-num">،،</div><div><h2>روابط جاهزة</h2></div></div>
  <p>الموقع: <span style="direction:ltr;display:inline-block">${SITE}</span></p>
  <p>إصدار الويب: <span style="direction:ltr;display:inline-block">${WEB_APP}</span></p>
  <p>ملخّص للمساعدات الذكية: <span style="direction:ltr;display:inline-block">${SITE}/llms.txt</span></p>
</div>

</body></html>`;

const tmp = path.join(ROOT, 'ops/marketing/.build_v2.html');
fs.writeFileSync(tmp, html, 'utf8');

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new' });
const page = await browser.newPage();
await page.goto('file:///' + tmp.replace(/\\/g, '/'), { waitUntil: 'networkidle0' });
await page.evaluate(() => document.fonts.ready);
fs.mkdirSync(path.dirname(OUT), { recursive: true });
await page.pdf({ path: OUT, format: 'A4', printBackground: true });
await browser.close();
if (!process.env.KEEP_HTML) fs.unlinkSync(tmp);

const kb = Math.round(fs.statSync(OUT).size / 1024);
console.log(`wrote ${path.relative(ROOT, OUT)}  (${kb} KB, ${total} posts, ${ANGLES.length} angles)`);
