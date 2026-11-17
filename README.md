# photo-cleanup

Fully offline duplicate & similar photo cleaner — iOS / Android.

- 100% on-device: no account, no server, no ads, no analytics, no upload.
- Finds exact duplicates, similar photos, bursts, screenshots, blurry shots and large videos.
- One-time purchase (Pro), no subscription.
- Multilingual from day one, language follows system locale; every test version includes Chinese.

## Backup rule

- Develop on `dev` only; `main` stays stable.
- Every meaningful change is committed and pushed to GitHub the same day; zips are a fallback, not the backup.
- The repo is public (created 2026-11-17 as a public repo). Nothing secret belongs in it: no keys, no signing files, no user data.

## APK rule (2026-11-17, user)

- Every testable version is delivered as an Android APK.
- Do NOT package frequently. Package only when content, features and
  visuals are stable enough to test, or on the user's explicit command.
  When the work reaches that point, ask the user whether to package --
  do not package on your own initiative.
- The CI workflow (`.github/workflows/build-debug-apk.yml`) builds a
  debug APK on every push to `dev`, but a build running is not a
  release: the APK is only handed over when the user asks for it.

## Status — v0.1.0 (2026-11-17)

- V1 plan: `docs/v1-plan.md`. Expansion + art: `docs/expansion.md`,
  `docs/art-direction.md`.
- Tech stack: Flutter (same stack as the party app, reusing its
  offline / i18n / Pro-gating patterns). Detection: SHA-256 exact
  hash + dHash perceptual hash on 64px thumbnails + union-find
  grouping + Best-keeper pick. No native ML in V1; embeddings are an
  expansion item.
- Price: undecided. Candidates $19.99 / $29.99–$39.99. The code carries
  a clearly-marked $19.99 placeholder; set the real store price
  before release.
- NOT compiled / analysed / tested yet (no Flutter SDK here — CI is
  the only verification). NOT packaged as an APK (ask-first rule).

## How to build

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
