# Expansion — bonus features, ranked

Ranked by (value to the user) × (how often competitors are
complained about) ÷ (build cost). V1 is the floor; these are the
reasons to pay once and to recommend the app.

## V1.1 — do next, all cheap and on-device

1. **Swipe review** (like Slidebox / Cleanup's swipe). One photo at
   a time, swipe left to delete, right to keep. Best for the final
   pass through a month of photos. Effort: low. Value: high — it is
   the interaction reviewers praise most.
2. **Live Photo → still.** Convert Live Photos to stills, keep the
   key frame, drop the motion clip. Saves the most space per item
   after large videos. Effort: low-medium (PhotoKit / MediaStore).
3. **Smart Cleanup, one tap.** One button that runs duplicates +
   similars + screenshots + blurry in order and shows a single
   before/after total. Effort: low (it is a preset over V1).
4. **Before/after report.** After a clean, a shareable card: photos
   scanned, groups merged, space freed, biggest win. System share
   sheet only, offline. Effort: low.
5. **Similarity slider on the review screen** (not only Settings),
   with live regrouping. Effort: low-medium (re-group cached hashes).

## V1.2 — medium effort, real differentiation

6. **Embeddings-based similarity.** On-device Vision feature prints
   (iOS) / ML Kit (Android) for bursts and same-scene-different-angle
   shots that dHash misses. Keep dHash as the fast first pass.
   Effort: medium. Value: high — this is the gap vs. the built-ins.
7. **Video duplicates, not just large videos.** Frame-sampled
   perceptual fingerprints for lookalike videos. Effort: medium.
8. **Android media folders.** WhatsApp / Telegram / Downloads
   coverage with visual matching — Files by Google cannot do this.
   Effort: medium.
9. **Compression (keep, smaller).** Lossless-ish recompress for
   screenshots and Live Photos the user wants to keep. Never lossy
   by surprise: always show old vs. new size first. Effort: medium.
10. **Monthly clean reminder, local only.** A local notification
    once a month, no server, no account. Effort: low.

## Pro-only, later

11. **Contact duplicate merge** in the one-time price (cheap to
    build, high perceived value; the all-in-one apps use it to
    justify subscriptions — we include it in the buy-once price).
12. **Calendar cleanup** (duplicate / past events). Same logic.
13. **Exclude / protect albums.** Favourites and Hidden are never
    suggested; a protected folder the user picks is skipped.
14. **Export scan report as PDF** for the “I cleaned 12 GB”
    bragging card. Effort: low.

## Deliberately NOT doing

- “Boost / RAM / junk” cleaners: fake on iOS, and users now
  recognise them as scare screens.
- Cloud backup, cloud AI analysis, account/login: breaks the
  offline promise and the privacy label.
- Email cleaning: useful, but it needs mail access and it pulls
  the app into a different permission story. Revisit only if users
  ask for it.
- Subscriptions, trials, weekly pricing: the category's #1 complaint.
