export const meta = {
  name: 'awwad-logo-concepts',
  description: 'Generate 5 distinct professional SVG logo concepts for Awwad',
  phases: [{ title: 'Concepts', detail: 'five independent design directions' }],
}

const BRIEF = `
You are a senior brand-identity designer (10+ years) specializing in Arabic lettermarks and
app icons. Design ONE logo concept for "عوّاد" (Awwad), a habit-change app (break bad habits,
build good ones; Islamic-values-aligned; warm, dignified, modern).

THE ASK (from the founder): the current icon is a generic sprout 🌱 - NOT unique. The new mark
must CREATIVELY MERGE two things into ONE professional mark:
  (a) the growth/sprout heritage (a leaf / growth gesture), and
  (b) the Arabic letterforms of the name: ع (Ain), ا (Alef), د (Dal) - or the full word عواد.

HARD TECHNICAL CONSTRAINTS (violating any = rejected):
- Return a COMPLETE standalone SVG: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">.
- VECTOR PATHS ONLY. Absolutely NO <text> elements (fonts won't render). Draw every letterform
  as <path>/<circle>/<rect> geometry. No <image>, no external refs, no filters, no <style> blocks -
  inline fill/stroke attributes only. Gradients via <linearGradient>/<radialGradient> in <defs> are allowed.
- Layer 1: a rounded-square background (rx about 230) filling the canvas, dark navy
  (#0F1420 solid, or a subtle radial to #182235).
- Layer 2: the mark, centered, inside a 20% safe margin (content roughly within 200..824).
- Palette ONLY: navy bg, teal #2dd4bf, green gradient #34d399 -> #22c55e, blue #4f8ef7 (sparingly),
  off-white #f3f8ff (sparingly). 2-3 colors max for the mark itself.
- Must stay legible and distinct when scaled to 48x48. Bold shapes, no thin hairlines under 12 units.

CRAFT BAR (what "professional" means here):
- Modern GEOMETRIC KUFI sensibility: clean horizontals/verticals, consistent stroke weight
  (pick one module, e.g. 72-96 units, and stick to it), deliberate negative space, optical balance.
- The Arabic must actually READ (an Arabic speaker should recognize the letter(s)/word).
  Remember Arabic runs right-to-left: for the word عواد the ع starts on the RIGHT.
  Letter anatomy you may stylize but not destroy: ع has an open bowl/eye; ا is a vertical stroke;
  د is an open right-facing bracket sitting on the baseline; و has a round head with a descender tail.
- The leaf/growth element must be INTEGRATED (replacing a letter part, growing from a stroke,
  or forming counter-space), not pasted next to the letters.
- One clear idea, executed cleanly. No clutter, no more than one decorative flourish.

Also return: name (short concept name), idea (2-3 sentences: the design story + how the letters
and leaf merge), and letters_used.
`

const SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['name', 'idea', 'letters_used', 'svg'],
  properties: {
    name: { type: 'string' },
    idea: { type: 'string' },
    letters_used: { type: 'string' },
    svg: { type: 'string', description: 'complete standalone SVG markup' },
  },
}

const DIRECTIONS = [
  'DIRECTION 1 - Kufi wordmark: the full word عواد drawn as ONE continuous geometric Kufi ribbon (single stroke weight, right-to-left), where exactly one element (the head of the ا or the ع opening) resolves into a single leaf. Horizontal composition.',
  'DIRECTION 2 - Ain monogram: a large geometric ع as the hero mark, its inner counter-space or its tail forming a rising stem with one leaf. The ع bowl doubles as soil/roots gesture. Compact, icon-first.',
  'DIRECTION 3 - Negative space: a solid rounded organic shape (leaf or seed silhouette) where the letters ع ا د are CARVED OUT as negative space in geometric Kufi, reading right-to-left.',
  'DIRECTION 4 - Growth ligature: the letters ع و ا د stacked/arranged so their baseline forms soil and the ا rises as the tallest element sprouting one leaf at its apex; think of the word literally growing upward. Vertical-ish composition.',
  'DIRECTION 5 - Circular emblem: a circular/arc gesture (halo of habit-cycle / returning, from the root of عوّاد = the one who keeps returning) containing a minimal ع + leaf ligature at its center; the arc breaks where the leaf emerges.',
]

phase('Concepts')
const concepts = await parallel(DIRECTIONS.map((d, i) => () =>
  agent(`${BRIEF}\n\nYOUR ASSIGNED DIRECTION (follow it, but make it excellent):\n${d}`,
    { label: `concept:${i + 1}`, phase: 'Concepts', schema: SCHEMA })))

return concepts.filter(Boolean)