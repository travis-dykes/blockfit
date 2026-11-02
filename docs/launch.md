# M5 soft launch / M6 live ops checklist

## M5
- TestFlight public cohort, then CA/AU/NZ. Reuse BlockBreaker ASO kit.
- Name check (App Store collisions/trademarks) before submission; never use "1010" / "Block Blast" in name or keywords.
- App Privacy label review: non-personalized ads, no ATT, analytics = PostHog events in CLAUDE.md.
- Targets: D1 ≥ 35%, D7 ≥ 12%, rewarded ≥ 30% of DAU, LTV:CPI trending > 1.
- Before shipping: run `swift test` (economy sim = Gate 3), play-test ads are non-intrusive (Gate 4 prep).

## M6 (not built)
- Seasonal themes pipeline (time-boxed cosmetics via ProgressionKit), weekly Daily Puzzle events.
- Level packs via Remote Config (`LevelData` JSON is already the wire format).
- Time Attack mode (tile shows SOON), GinRummy hub cross-promo, One Bit membership.
