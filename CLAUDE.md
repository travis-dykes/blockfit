# CLAUDE.md — Block Fit

Agent-facing guide for this repo. Read product.md, design.md, roadmap.md and backlog.md before changing behavior. **Current milestone: M0 Greybox. Do not build meta, economy or monetization until roadmap.md says the earlier gate passed.**

## Stack
- Swift 6, Swift Concurrency. **SpriteKit** for gameplay, **SwiftUI** for menus, meta and shop.
- Shared One Bit packages: `AppShell`, `DesignTokens`, `Onboarding`, `Paywalls`, `Settings`, `ProgressionKit` (and `GameFlowKit` where it fits).
- Services: **RevenueCat** (IAP), **Firebase Remote Config**, **PostHog** (analytics), **Sentry** (crashes). Ads via BlockBreaker's `AdService`.
- Minimum iOS: match BlockBreaker.

## Module map
```
App/            Entry, AppState, scene routing, One Bit splash
Core/           Board, Cell, Piece, PieceCatalog, TrayGenerator, SeededRNG, Scoring,
                LevelGoal, GameSession. PURE SWIFT. No SpriteKit/SwiftUI/UIKit imports.
Gameplay/       BoardScene, TrayNode, PieceNode, BallSmashEffect, DragController, Juice/
Levels/         levels/*.json, LevelLoader, LevelGenerator, Solver (greedy bot)
Meta/           ProgressionKit adapter (PlayEvent emission, content registry, mode gates), Map
Economy/        Booster effect handlers, pricing tables (config-backed)
Monetization/   AdService (protocol + mediation impl + NoAds debug), StoreService (RevenueCat), InterstitialPolicy
Analytics/      AnalyticsService protocol, PostHogAnalytics, AnalyticsEvent enum
Config/         RemoteConfig wrapper, Defaults.json (bundled)
Persistence/    SaveGame (Codable, schemaVersion), migrations
Feedback/       HapticsService, AudioService
UI/             Theme (shared Brick Breaker tokens), TextureFactory, fonts, SwiftUI components
Debug/          DebugMenu (DEBUG builds only)
```

## Rules
1. **Core is pure and tested.** Every rule change in `Core/` ships with a unit test. Gameplay reads Core state; it never owns rules.
2. **Determinism.** All randomness goes through `SeededRNG`. Never call `Int.random` / `.shuffled()` without the injected RNG. Daily Puzzle seed = `yyyyMMdd` + salt.
3. **Services behind protocols** (`AdService`, `StoreService`, `AnalyticsService`, `ConfigService`, `HapticsService`, `AudioService`) with mock implementations for previews/tests. DEBUG builds default to `NoAdsService`.
4. **All tunables in config.** Piece weights, scoring constants, generator params, economy prices, booster grants, ad caps. Local defaults in `Config/Defaults.json`; Remote Config overrides. No magic numbers in Gameplay or Economy.
5. **Theme tokens only.** Colors and fonts come from `Theme` / DesignTokens. Departure Mono sizes are 11/22/33/44 only. No hex literals outside `Theme`.
6. **Play Promise.** Boosters are earned or rewarded, never sold for money and never bought with coins. No interstitial before level 6 or mid-move. No dark-pattern copy. If a task seems to require breaking this, stop and ask.
7. **Reduce Motion and haptics toggles** are respected by every effect. New juice must include its reduced variant.
8. **Save versioning.** Bump `schemaVersion` and add a migration test for any persisted shape change.
9. **ProgressionKit seam.** Emit `PlayEvent`s and conform to adapters; never branch inside ProgressionKit on "is Block Fit." If the seam doesn't fit, flag it. Block Fit is the forcing function for its v1 API.
10. **Single analytics enum.** No string event names outside `AnalyticsEvent`.

## Analytics events (snake_case, `AnalyticsEvent`)
| Event | Params |
|---|---|
| `app_open` | `session_index` |
| `ftue_step` | `step` |
| `level_start` | `level`, `mode`, `attempt` |
| `level_complete` | `level`, `mode`, `duration_s`, `attempts`, `stars`, `moves`, `boosters_used` |
| `level_fail` | `level`, `mode`, `duration_s`, `attempts`, `goal_progress` |
| `classic_end` | `score`, `best`, `duration_s`, `lines_total`, `max_combo` |
| `daily_complete` | `date`, `duration_s`, `streak_days` |
| `piece_place` *(sampled 10%)* | `shape`, `lines_cleared` |
| `lines_clear` | `count`, `combo`, `streak`, `comet` |
| `perfect_clear` | `mode`, `level` |
| `currency_earn` / `currency_spend` | `type`, `amount`, `source` / `sink` |
| `booster_use` | `type`, `level` |
| `ad_offer` / `ad_show` / `ad_reward` | `placement`, `format` |
| `iap_view` / `iap_purchase` | `sku`, `price`, `placement` |
| `meta_unlock` | `item`, `category` |
| `mode_unlock` | `mode` |

## Debug menu (DEBUG only)
Jump to level · set seed · add coins · grant boosters · toggle ads · toggle Comet Clear · force Remote Config value · reset save · show solver win-rate overlay.

## Do NOT
- Don't add a hard currency, banners, or an ATT prompt without a product.md decision.
- Don't build cross-game shared wallet/streaks (ProgressionKit rule).
- Don't polish anything in a milestone whose gate hasn't been passed.
- Don't use "1010", "Block Blast" or similar names in code-facing App Store metadata or keywords.
