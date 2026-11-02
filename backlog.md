# Block Fit — backlog.md

Tickets for the current milestone are detailed. Later milestones stay as epics until their gate is in sight.
Format: `ID · title · acceptance`. Size: S ≤ ½ day, M ≤ 2 days, L ≤ 4 days.

---

## M0 — Greybox (current)

**Status:** BF-001…009 implemented (code + unit tests written; not yet compiled or run — needs a Mac/Xcode). BF-010 (capture the clip) is a human step: Debug menu → "3-line combo setup", record with Comet off/on.

| ID | Ticket | Size | Acceptance |
|---|---|---|---|
| **BF-001** | **Core: `Board` model**. 8×8 `[[Cell]]` (`empty / brick(color) / steel(hits) / gold`), `canPlace(piece, at:)`, `place`, `linesToClear()`, `clear()` returning a `ClearResult` (rows, cols, cells, gold collected, steel cracked) | M | Pure Swift, no UIKit/SpriteKit import. Unit tests: placement bounds, overlap, row + column simultaneous clear, intersecting-cell counted once, steel two-hit, gold collection |
| BF-002 | Core: `Piece` catalog | S | All v1 shapes (incl. rotation variants as separate pieces), fixed color per shape, weights loaded from JSON. Test: every shape's cell offsets are normalized to the origin |
| BF-003 | Core: `TrayGenerator` (seeded) | M | `SeededRNG` (SplitMix64); same seed → same trays. `trayGuarantee` flag ensures ≥1 piece fits. Tests: determinism, guarantee holds over 10k random boards |
| BF-004 | Core: `hasAnyMove(tray, board)` and game-over | S | Tests incl. 3×3 vs. 2×2 hole near-miss case; returns the closest-fit gap for the lose card |
| BF-005 | Core: `Scoring` | S | Cell points, `10·n(n+1)/2` lines, streak multiplier capped at ×3, Perfect Clear +300; all constants from config. Table-driven tests |
| BF-006 | Gameplay: `BoardScene` greybox | M | Board + tray render using `TextureFactory` bricks; drag with 1.5-cell lift offset, grid snap, ghost preview, invalid tint, spring-back. 120fps on device |
| BF-007 | Gameplay: ball-smash clear (rough) | M | Ball launches from the paddle, travels each cleared line, bricks burst into shards. Sequential lines for combos. No polish yet |
| BF-008 | Gameplay: Comet Clear behind a debug toggle | S | On 2+ line clears, preview diagonal, break up to 3 bricks. Toggle in the debug menu stub |
| BF-009 | Classic loop end to end | S | Endless play, score, game over → restart. No menus |
| BF-010 | Capture the Gate 0 clip | S | 10–15s screen recording of a 3-line combo (set up via debug seed). Two versions: Comet on/off |

**Gate 0 check:** BF-010 clip reviewed; Comet decision recorded in product.md §8.

---

## M1 — Feel (epics)
- BF-100 Juice pass per design.md §2 (particles, squash, shake, COMBO bar, Reduce Motion variants)
- BF-110 `HapticsService` + Core Haptics combo patterns; `AudioService` with per-color pitched brick SFX
- BF-120 Level data format (JSON) + `LevelLoader`; gold/steel pre-placement; par + stars
- BF-130 Levels 1–10 hand-built (FTUE per design.md §5)
- BF-140 Level generator from a param table + greedy solver bot; reject outside win-rate band; generate L11–20
- BF-150 FTUE hint system (single pointer, never blocking, never repeated)
- BF-160 Playtest kit: TestFlight build, 5-person script, observation sheet

## M2 — Meta v1 (epics)
- BF-200 ProgressionKit integration: emit `PlayEvent`s, register content, wallet, Day Streak
- BF-210 Level map screen + chests every 5 levels
- BF-220 Home screen (SwiftUI) per design.md §4
- BF-230 Mode unlock gates (Classic L5, Daily L8, Time Attack L20)
- BF-240 Daily Puzzle (date-seeded board) + calendar
- BF-250 Themes as DesignTokens override sets: 3 themes, 2 trails, 2 board skins + preview
- BF-260 Versioned `SaveGame` (Codable, `schemaVersion`, migration test)

## M3 — Economy + Monetization (epics)
- BF-300 Coin faucets + sinks wired to config; economy sim script (30-day casual/light player)
- BF-310 Boosters Undo / Smash / Reroll (effect handlers; first-time free grants)
- BF-320 Rewarded placements: continue, 2× coins, daily free booster
- BF-330 Interstitial policy object (level ≥ 6, every 3, ≥ 90s, result-card only) + tests
- BF-340 RevenueCat SKUs, Remove Ads, starter pack trigger rules, restore
- BF-350 Shop screens incl. booster inventory tab

## M4 — Instrumented (epics)
- BF-400 `AnalyticsEvent` enum → PostHog; verify every event in CLAUDE.md fires
- BF-410 Remote Config for every tunable, local JSON defaults bundled
- BF-420 Sentry + debug menu (jump level, add coins, toggle ads, reset save, force config, set seed)

## M5 / M6
- BF-500 Soft-launch build, ASO (reuse BlockBreaker kit), App Privacy label review
- BF-600 Seasonal theme pipeline, weekly events, GinRummy hub cross-promo
