# Block Fit — roadmap.md

Rule: **prove the core loop before the meta, the meta before the economy. Never polish what hasn't passed its gate.**

| Milestone | Build | Gate to pass | Status |
|---|---|---|---|
| **M0 Greybox** | `Core` (board, pieces, placement, line clear, scoring, seeded tray generator, fit check) + minimal SpriteKit scene with drag/snap. Brick textures from `TextureFactory` (free, already exists). Ball-smash clear as a rough effect. Comet Clear behind a debug toggle | **Gate 0:** a 10–15s capture of a 3-line combo Travis would stop scrolling for. Comet Clear on vs. off judged by 3+ people | **← current** — Core + greybox built (uncompiled/untested on device); Gate 0 clip + Comet verdict pending |
| **M1 Feel** | Full juice list, audio, haptics, Reduce Motion, 20 hand-tuned + generated levels (gold, steel), solver bot, FTUE L1–L9 | **Gate 1:** 5+ cold playtesters understand in <5s, play 10+ levels unprompted, ask for "one more" | |
| **M2 Meta v1** | Level map, stars, home screen, Classic/Daily unlock gates, themes via DesignTokens overrides (3 themes, 2 trails, 2 boards), ProgressionKit integration (wallet, collection, Day Streak), versioned save | **Gate 2:** D7 lift vs. Classic-only build in a TestFlight cohort (target ≥ 12–15%) | |
| **M3 Economy + Monetization** | Coins faucets/sinks, boosters (Undo/Smash/Reroll, earned + rewarded), map chests, rewarded placements, capped interstitials, RevenueCat SKUs, Remove Ads, starter pack, restore | **Gate 3:** 30-day economy sim clean (no dead zones). **Gate 4 prep:** ads verified non-intrusive by playtesters | |
| **M4 Instrumented** | Full event taxonomy to PostHog, Firebase Remote Config for every tunable, Sentry, debug menu, A/B hooks | Full funnel visible end to end on a dev dashboard (FTUE → L20 → first purchase/ad) | |
| **M5 Soft launch** | TestFlight public cohort, then a small market (e.g., CA/AU/NZ). ASO kit reused from BlockBreaker | D1 ≥ 35%, D7 ≥ 12%, rewarded ≥ 30% of DAU, LTV:CPI trending > 1 | |
| **M6 Live ops** | Seasonal themes, weekly Daily Puzzle events, level packs via Remote Config, Time Attack, GinRummy hub cross-promo, One Bit membership | Retention holds and revenue grows month over month | |

### Reuse map (don't rebuild)

| Need | Source |
|---|---|
| Splash | One Bit motion splash (shared) |
| Brick textures, Theme tokens, Departure Mono setup | Brick Breaker / Color Sort `Theme` + `TextureFactory` |
| Wallet, collection, streaks, objectives | ProgressionKit (Block Fit = forcing function before its v1 API freeze) |
| Ads + StoreKit | BlockBreaker's AdService + RevenueCat setup |
| Themes | DesignTokens override sets |
| Shell, settings, onboarding, paywalls | AppShell, Settings, Onboarding, Paywalls packages |
| Seeded generator + solver pattern | Color Sort's generator/solver approach |
| Launch marketing | BlockBreaker marketing starter kit (ASO, creators, Reddit) |

### Kill / pivot criteria
- Gate 0 fails twice → the ball-smash hook isn't enough; revisit the differentiator before writing more code.
- Gate 1 fails → tune pieces/generator for 1 more week max; if "one more" still doesn't show up, shelve and move on to the next portfolio candidate.
