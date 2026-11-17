# V1 plan — photo-cleanup

Source: competitor research 2026-11-17
(`research_notes/photo-cleanup-competitors-20261117-0219/report.md`,
full plan page: artifact “相册清理第一版方案”).

## Positioning (four principles)

1. **Fully offline.** No account, no server, no ads, no analytics.
   Works in airplane mode; privacy label “Data Not Collected”.
2. **One-time purchase, no subscription.** No trial, no auto-renew.
   Price undecided: candidates $19.99 / $29.99–$39.99 (competitor
   lifetime benchmark $29.99–$49.99, indie one-time $14.99).
3. **Honest free tier.** Full scan, exact duplicates, up to 100
   deletes a day. No “scan free, delete paywalled” theatre.
4. **Never auto-delete.** Review before delete, Best-keeper pick,
   keep at least one per group, OS trash (30 days) as the safety net.

## Why it can win

- Cleanup (4.7★, ~765K ratings, #3 Utilities): Pro $5.95–$11.99/week
  or $29.99/year, 7-day trial, no lifetime on its store page.
  Top complaints are billing, not detection.
- Built-ins (iOS Duplicates album, Files by Google) already find
  exact duplicates free. The winnable ground is similars, bursts,
  edited/resized copies, screenshots, blurry shots, large videos.
- Strongest free rival Clever Cleaner (4.78★, lifetime $39.99) proves
  the category rewards a clean, colour-coded, front-and-centre UI.

## V1 scope (0.1.0 — this package)

- Scan: exact duplicates (SHA-256) + similar photos (dHash,
  adjustable threshold, default 10) + screenshots (system album) +
  blurry (variance heuristic) + large videos (size-ranked).
- Review: groups with Best-keeper pre-pick, tap to change keeper,
  flat lists for screenshots/blurry/videos with per-item toggle,
  confirm dialog, daily free cap (100), Pro unlimited.
- Settings: similarity slider, Pro preview toggle (test only,
  remove before release), offline/about note.
- i18n: English + Chinese, language follows system.
- Tests: detection unit tests (hash, grouping, keeper, blur).

## Out of V1

- Store purchase wiring (in_app_purchase), Live Photo → still,
  compression, contact merge, swipe review, embeddings-based
  similarity, Android WhatsApp/media folders. See `docs/expansion.md`.

## Milestones

- M0 (done, 0.1.0): repo initialised, scaffold, detection core,
  scan + review + settings UI, ARB EN=ZH, tests, docs, CI workflow.
- M1: upload to GitHub dev, CI green (analyze + test + debug APK
  builds), fix whatever CI finds.
- M2: store purchase wiring, price decision, privacy label,
  icon + store screenshots, test checklist.
- M3: first test APK — only when content, features and visuals are
  stable, or on the user's command (APK rule in README).
- M4: expansion batch from `docs/expansion.md`, ranked by value.

## Tech

Flutter, `photo_manager` (read-only library access),
`image` (thumbnail decode for dHash), `crypto` (SHA-256),
`shared_preferences` (settings, Pro flag, daily cap).
No network permission, no analytics SDK, no ads SDK.
