# Art direction — "Clean Light"

## What the competitors look like

| App | Look | What works | What to avoid |
|---|---|---|---|
| Cleanup (Codeway) | Dark, bold, game-like; big before/after meter (“250 GB → 50 GB” in the listing, a demo number) | The meter: one honest number is why people keep it. Swipe-to-decide is engaging. | Scare-red warnings, aggressive paywall, weekly-billing chrome everywhere. |
| Clever Cleaner (CleverFiles) | Light, clean, **colour-coded categories**: Similars green, Screenshots yellow, Lives blue, Heavies red; every tool front and centre, large icons | The best UI in the category. You always know which tool you are in; nothing is buried. | Nothing structural — copy this shape, soften the colours. |
| CleanMyPhone (MacPaw, ex-Gemini) | Modern, polished, pastel | Visually tidy at first glance | Bloated: Declutter / Organize / Health / security / speed-test tabs distract from the one job. Reviewers call it slow and laggy vs. Gemini. |
| Slidebox | Minimal, swipe-first, calm | Undo, iPad support, no tracking label | No automatic detection; recent reviews report lost progress. |

## Chosen direction: Clean Light

Light, airy, trustworthy. The photo is the visual; the chrome gets
out of the way. One calm teal accent, colour-coded categories
borrowed from Clever Cleaner, the honest meter borrowed from
Cleanup, swipe review borrowed from Cleanup/Slidebox (V1.1).

- Background `#F7F8F7` (soft warm white), surface white, ink
  `#14201D`, muted `#5C6B66`, hairline `#E3E8E5`.
- Accent teal `#0E7C6B`, soft tint `#E3F2EE`, dark ink `#0A5C50`.
  Used for the scan button, the keeper mark, the storage meter.
- Categories: duplicates teal `#0E7C6B`, similars green `#2E9E5B`,
  screenshots amber `#D9930D`, blurry slate `#64748B`, videos
  coral `#D95D4E`. One colour per category, icon chip + card edge.
- Type: system font in V1 (no bundled font, keeps the build light
  and the CJK fallback correct). Large tabular numbers for the
  meter; 16dp cards, 8dp grid, 12dp gaps.
- No scare-red, no fake “junk” numbers, no dark game chrome, no
  confetti. A cleaning tool should feel like a tidy room, not a slot
  machine.

Tokens live in `lib/theme.dart` (`CleanTokens` + `cleanTheme()`).

## Icon (v0.1 draft)

`assets/icons/app_icon_1024.png` — teal rounded square, two
overlapping white photo frames, a check mark. Generated locally
(see `tools/make_icon.py` in the workspace, not shipped). Before
store submission: redraw at 1024px with a proper vector source,
check at 48px that the check is still legible, and produce the
adaptive-icon foreground/background split for Android.

## Store screenshots (spec, 5 screens, EN + ZH)

1. Home with the meter: “1.2 GB you can free” + five category cards.
2. Similar group review: Best badge on the keeper, the rest marked
   for deletion.
3. Screenshots bulk list, one-tap clear.
4. Large videos ranked by size.
5. Pro screen: one price, “Pay once. No subscription.” + offline
   note. No demo numbers, no fake storage figures — every number on
   a screenshot must come from a real scan.

## What “user-preferred” means here

The direction above is the synthesis of the two best-liked
competitor UIs (Clever Cleaner's colour-coded clarity + Cleanup's
meter and swipe), minus the two most-complained-about patterns
(weekly-billing chrome, scare screens). If the user prefers a
different accent or a dark variant, the tokens are the only file
that changes — the layout does not depend on any colour.
