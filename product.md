# Block Fit — product.md

> Working title. One Bit Holding · "spread joy" · Target rating **4+** (general audience, *not* Kids Category).
> Framework: hybrid-casual. Hyper-casual first 60 seconds, a meta layer underneath.
> Visual source of truth: Brick Breaker theme (see design.md). Prototype: 14-screen clickable flow (Block Fit canvas artifact).

---

## 1. Concept (Phase 0)

**Hook (verb + object + outcome):**
*Drop bricks onto the board, fill a line, and watch the ball smash it to pieces.*

**Genre:** block-fit puzzle (1010!-style). 8×8 board, tray of 3 pieces, drag to place, no rotation, no timer in Classic.

**Reference set**

| Game | What it does best | What we take |
|---|---|---|
| 1010! | Purity. Zero UI between you and the board; instantly readable | The 8×8 + 3-piece tray rule set and the calm, no-timer pace |
| Block Blast! | Combo juice and an Adventure (goal-based level) mode on top of endless play | Multi-line combo celebration; a level mode with collect goals as the hybrid-casual meta |
| Woodoku | A strong material/theme identity on a commodity mechanic | Proof that *theme + feel* is the differentiator, not a new rule |

**Differentiator: the Brick Breaker crossover.** Every brick is a beveled Brick Breaker brick. A cleared line doesn't just vanish: the **ball launches from a paddle under the board and smashes along the line**, cracking each brick into shards. It's the same art and feel players know from Brick Breaker, and it gives the portfolio an ownable look. A second differentiator is the honest monetization (the Play Promise, §6), which is the brand.

**Twist under test (M0 A/B, not committed):** **Comet Clear**. Clearing 2+ lines at once lets the ball keep going and break up to 3 extra bricks along a previewed diagonal. That's a small strategic payoff for setting up big combos. Ship it only if playtesters say it feels like a reward, not randomness. If it doesn't pass, the ball stays pure juice.

**Ad moment (the 3 seconds):** a 3-line combo. The ball rips across three rows in sequence, the bricks shatter in rainbow shards, the screen kicks, and a yellow **COMBO ×3** bar slams in with a rising arpeggio. If that capture doesn't stop a scroll, Gate 0 fails.

**Fail state that invites retry:** the board locks with one 2×2 hole left and a 3×3 in the tray. Show the near-miss on screen: highlight the one gap where a piece *almost* fit, plus "So close! 1 line from a new best." Then one tap to retry or (rewarded) **Continue**.

**Gate 0:** a 10–15s greybox-plus-brick-art capture of a 3-line combo that Travis would personally stop scrolling for. Optional creative test: compare CTR between the ball-smash clip and a plain-clear clip.

---

## 2. Core loop (Phase 1)

- **Input:** one gesture, **drag** a piece from the tray onto the board. The piece lifts above the thumb (offset ~1.5 cells) so the finger never hides the target. A ghost preview snaps to the grid; invalid placement shows a red tint and returns the piece to the tray.
  - Secondary input: **tap** on boosters only (Undo / Smash / Reroll). Justified: boosters are optional and outside the board.
- **Loop (≈2–4s per move):** pick piece → drag → snap → place (thunk) → line check → clear + ball smash → score pop → tray refills when all 3 are used → repeat.
- **Lose:** no piece in the tray fits anywhere. **Win (Levels mode only):** goal met (§3).
- **Session target:** Levels 30–90s each; Classic 2–5 min runs (the genre norm, and the place to put a natural interstitial break).

**Modes (from the prototype; reach and timing gated):**

| Mode | Unlock | Role |
|---|---|---|
| Levels (map) | Default, from launch | Hybrid-casual spine; goals, stars, coins |
| Classic (endless) | Level 5 | Pure 1010! high-score chase |
| Daily Puzzle | Level 8 | One fixed seeded board per day; streak feeds ProgressionKit Day Streak |
| Time Attack | Level 20 (Completion→Mode unlock) | Fast variant; a reason to keep progressing |

**Scoring**
- +1 per cell placed.
- Lines cleared in one move *n*: `10 × n × (n+1) / 2` (1 → 10, 2 → 30, 3 → 60, 4 → 100).
- **Streak:** consecutive moves that each clear ≥1 line multiply the clear score by `1 + 0.5 × (streak−1)`, capped at ×3.
- **Perfect Clear** (empty board): +300 and a full-screen ball rally.

**Piece set (v1, 1010!-like, weighted):** 1×1; 1×2 / 1×3 / 1×4 / 1×5 (horizontal + vertical); 2×2; 3×3; small L (3 cells, 4 rotations); big L (5 cells, 4 rotations). T and S/Z shapes are held back as a later difficulty lever. All weights live in config.

**Fairness rules (Core):**
- **Tray guarantee:** in Levels 1–10 and Classic's first 3 trays, at least one piece in every tray must fit. After that it's standard random generation from the weight table.
- **Seeded RNG** everywhere (daily boards must be identical for everyone; also makes bugs reproducible).

**FTUE:** playable within 3s of launch (One Bit splash ≤1.5s, then straight into Level 1, no menu). Level 1 is a near-full board with one obvious gap and a single hand-pointer hint. Level 2 teaches a 2-line combo by setup alone. No text tutorial screens.

**Difficulty curve:** Levels 1–10 hand-built (L1–4 easy wins, L5 first steel brick, L6–8 first real squeeze). After that, a generator driven by a param table (`fillRatio`, `goalCount`, `steelRatio`, `pieceWeights`, `trayGuarantee`), validated by a solver bot that plays each generated level N times with a greedy policy and rejects levels outside the target win rate band.

**Gate 1:** 5+ people, no explanation. They understand it in <5s, play 10+ levels unprompted, and ask for "one more." D1 ≥ 35% once in soft launch.

---

## 3. Meta layer (Phase 2)

Two systems for v1, one cheap habit layer. All run on **ProgressionKit** (wallet, collection registry, streaks, Remote Config objectives). Block Fit is its next consumer, so the seam gets exercised.

| Meta | Why for Block Fit | Build cost |
|---|---|---|
| **1. Level map (Levels mode)** | Visible journey; gives the endless mechanic a finish line every 60s | Low–Med |
| **2. Themes & cosmetics** | Brick palettes, board skins, ball trails. Art is mostly token swaps on the Brick Breaker system | Low |
| **3. Daily Puzzle + Day Streak** (habit layer) | Already designed in ProgressionKit; nearly free | Low |

**Level goals (the core stays the same, the meta changes what a clear means):**
- **Gold bricks:** pre-placed bricks with a coin icon. Clear their line to collect. Goal: "Collect 6 gold."
- **Steel bricks:** a Brick Breaker nod. Need two clears to break (first crack, then shatter). They show up from L5.
- **Score target:** used sparingly as a variety level.
- Stars: 1 = goal met, 2 = goal met with ≥1 piece of the tray budget left / under par, 3 = no boosters used and under par. Par lives in level data.

**Home screen shows:** the current map node with a big PLAY, the coin balance in the cream header bar, the Day Streak flame, and the Daily Puzzle card. The next cosmetic unlock is shown as a progress bar ("Comet Trail: 40 / 80"), so every level visibly moves something.

**Tie-back to the core:** themes recolor the actual bricks and the ball you clear with. Gold and steel bricks change *which* lines are worth clearing, giving the endless mechanic intent without new inputs.

**Completion → Modes** (ProgressionKit unlock gate): Classic at L5, Daily at L8, Time Attack at L20. A gameplay-changing carrot beats any cosmetic.

**Gate 2:** D7 ≥ 12–15% and sessions/day up vs. a core-only (Classic-only) build.

---

## 4. Economy (Phase 3)

**Currencies:** one soft currency, **coins**. No hard currency (simplicity, family audience, brand).

**Faucets:** level complete (base + stars), Daily Puzzle, Day Streak multiplier (ProgressionKit: +2%/day, cap +50%), Remote Config objectives ("Clear 20 lines with steel bricks"), rewarded video (2× level coins), map chests every 5 levels.

**Sinks:** cosmetics (themes, board skins, ball trails). That's it for v1. **Coins never buy boosters** (keeps the lanes clean, see §6 and Open Decision #1).

**Boosters (3 max):**

| Booster | Effect | Earned via | First-time |
|---|---|---|---|
| Undo | Revert last placement (not across a tray refill) | Map chests, objectives, rewarded | 2 free at L4 |
| Smash | Tap one brick to break it (the ball fires at it) | Map chests, rewarded continue | 1 free at L6 |
| Reroll | Swap the current tray for 3 new pieces | Map chests, Day Streak milestones | 1 free at L9 |

**Pacing table (starting values, all in Remote Config).** Assumes no rewarded 2× and no dailies; those only accelerate it.

| Levels | Coins / level (avg, ~2 stars) | Cumulative earned | Unlock target | Price | Afford at ≈ |
|---|---|---|---|---|---|
| 1–10 | 20 (10 base + 5/star) | 200 | Ball trail "Spark" | 80 | L4 |
| | | | Board skin "Night" | 100 | L9 |
| 11–30 | 25 | 700 | Theme "Neon" | 250 | L20 |
| | | | Ball trail "Comet" | 150 | L26 |
| 31–60 | 30 | 1,600 | Theme "Candy" | 400 | L40 |
| | | | Board skin + trail pair | 300 each | ~L50, ~L60 |
| 61+ | 35 | — | New theme every ~20 levels | 600–800 | stretching |

Early: something every 4–6 levels, plus a map chest every 5. Later: one meaningful unlock every 10–20 levels, padded by seasonal items (ProgressionKit time-boxed cosmetics).

**Gate 3:** 30-day simulated player (casual: 3 sessions/day, 4 levels each, 30% rewarded opt-in; light: 1 session/day). No stretch longer than ~2 days with nothing affordable, and no stockpile of more than ~2× the next price with nothing to buy.

---

## 5. Monetization (Phase 4)

**Ads** (reuse BlockBreaker's AdService; mediation as already integrated there)
- **Rewarded (opt-in, the engine):** Continue after fail (Smash 3 bricks *or* new tray, player's choice), 2× level coins on the win card, one free booster per day from the home screen. Max one rewarded offer visible at a time.
- **Interstitial:** none before Level 6; then at most every 3 completed levels, ≥90s apart; only on the win/lose card *after* the result is shown; never mid-move, never right after a purchase, never on the first session's last level. Classic: after a run ends, same caps.
- **Banner:** none. The board is the product.
- **Ad content rating:** G / family-safe filtering in mediation (4+ app).
- **Privacy:** non-personalized ads by default, consistent with One Bit's privacy stance → **no ATT prompt** in v1. The trade-off is lower eCPM, accepted on purpose. Revisit only with data (Open Decision #2).

**IAP (StoreKit 2 via RevenueCat)**

| SKU | Type | Price (start) | Notes |
|---|---|---|---|
| `blockfit.remove_ads` | Non-consumable | $3.99 | Removes interstitials; rewarded stays (opt-in). Framed as "support the dad who made this." |
| `blockfit.starter_pack` | Non-consumable, one-time | $2.99 | Remove Ads + "Neon" theme + 300 coins. Shown once, after L10 *or* the first lost Classic run past 1,000 points, never right after a fail with a timer |
| `blockfit.coins_s / m / l` | Consumable | $0.99 / $2.99 / $4.99 | Coins buy cosmetics only |
| `blockfit.theme_bundle_*` | Non-consumable | $1.99 | Seasonal/premium themes, also earnable or not (per item, decided in config) |
| One Bit membership | Auto-renew sub | ~$1.99/mo (exploring) | Portfolio-wide ad-free plus all themes. Post-launch, once 2+ games share it |

Restore purchases, RevenueCat entitlement cache, receipt validation through RevenueCat.

**Gate 4:** ARPDAU tracked; rewarded engagement ≥ 30% of DAU; IAP conversion measurable (benchmark 2–5%).

---

## 6. Play Promise (brand constraints, non-negotiable)

- No dark patterns: no fake countdowns, no "are you sure you want to lose your progress?" guilt screens, no confirm-shaming copy.
- Boosters are **earned or watched for, never sold for money** (pending Open Decision #1).
- No ads in the first 5 levels; no interstitial ever interrupts a move.
- Every level is beatable without boosters (the solver validates this).
- Prices are honest and visible; no currency obfuscation (one currency, coins).

---

## 7. KPIs (Phase 5 targets)

| KPI | Soft-launch target |
|---|---|
| FTUE completion (L1 → L3) | ≥ 90% |
| D1 / D7 / D30 | ≥ 35% / ≥ 12% / ≥ 4% |
| Sessions / day | ≥ 3 |
| Avg session length | 6–10 min |
| Level funnel | No single level with > 8% drop vs. neighbors |
| Rewarded opt-in (of DAU) | ≥ 30% |
| IAP conversion | ≥ 2% |
| ARPDAU | Track; benchmark ~$0.05–0.10 hybrid |
| LTV : CPI | > 1 before any paid UA scales |

---

## 8. Open decisions

1. **Booster lane.** Two existing rules collide: the Play Promise (from Slide Merge) says power-ups are never sold; ProgressionKit's CLAUDE.md says utility power-ups are a RevenueCat IAP lane. **Recommended for Block Fit: Play Promise wins.** Boosters are earned or rewarded only, and IAP is cosmetics, coins and Remove Ads. Update ProgressionKit's rule to "lane is per-game config."
2. **ATT / personalized ads.** Default is no ATT, non-personalized ads. Revisit after soft-launch ARPDAU data.
3. **Comet Clear.** Ship as a mechanic or keep the ball as pure juice. Decided at Gate 0/1 playtest.
4. **Name.** "Block Fit" is the working title. Check App Store name collisions and trademarks before M5. Don't use "1010" or "Block Blast" in name or keywords.
5. **Prototype shop "Items" tab.** If #1 lands as recommended, the Items tab becomes a booster *inventory* view (with rewarded refills), not a store.
