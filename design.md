# Block Fit — design.md

> Visual system: **Brick Breaker theme**, carried over as-is. Same tokens as Brick Breaker and Color Sort, so players read the portfolio as one family.
> Opens with the shared **One Bit motion splash** (black → "One Bit" → the bit drops in → "spread joy").

---

## 1. Visual direction

**Mood:** a bright arcade toy box at night. A deep purple field, chunky beveled bricks, cream panels, a yellow call-to-action. Pixel type, never pixel art for the bricks themselves (bricks are crisp vector bevels at any size).

### Tokens (shared `Theme`, from Brick Breaker)

| Token | Hex | Use |
|---|---|---|
| `bgTop` → `bgBottom` | `#221A37` → `#3A2A5E` | Vertical gradient background |
| `ink` | `#1F2340` | Brick outlines, board grid lines, dark text, text outlines |
| `cream` | `#F8EFD8` | HUD header bar, panels, cards |
| `purple` | `#8E7FB5` | Secondary buttons, panel drop edge |
| `yellow` | `#F2C72B` | Primary button, COMBO bar, selection, coins |
| `blue` / `green` | `#2B9BDB` / `#3DB54A` | Info / success states |
| Board well | `#1A1430` (`tubeFill`) | Empty cells |
| `mutedInk` | `#8A7F9E` | Empty-cell grid dots, disabled |

**Brick colors (12):** red `#E03A3A`, orange `#F08A24`, yellow `#F2C72B`, green `#3DB54A`, blue `#2B9BDB`, violet `#8A4AD6`, pink `#E85DAA`, teal `#1FA58A`, steel `#9AA0A8`, sky `#6FD8EE`, lime `#A6D93A`, cream `#F8EFD8`.
- Each **piece shape gets a fixed color** (e.g., 3×3 = violet, big L = orange), so shape recognition becomes color recognition after a few minutes.
- **Steel** is reserved for steel bricks (gameplay meaning). **Gold** bricks use yellow plus a coin glyph.
- **Colorblind mode** (Settings): each color also carries a small glyph (●▲■◆✚★…), reusing Color Sort's symbol set.

**Brick rendering:** `TextureFactory` from Color Sort/Brick Breaker. Ink border, light top-left bevel, dark bottom-right bevel, cached per color and size.

**Type:** **Departure Mono** (single weight). Sizes snap to its 11px grid: 11 / 22 / 33 / 44. Emphasis via ink outline, never fake bold. The One Bit wordmark (Londrina Solid Black) appears only in the splash.

**Layout (portrait, iPhone first):**
```
┌───────────────────────────┐
│ ☰   ★ 1,240   ● 320  🔥4 │  cream header bar: pause · score/goal · coins · streak
│      LEVEL 12 · 4/6 gold  │  goal chip
│ ┌───────────────────────┐ │
│ │      8 × 8 board      │ │  square, centered, ~92% width
│ └───────────────────────┘ │
│     ▔▔▔▔ paddle ▔▔▔▔      │  decorative paddle; the ball launches from here
│  [ piece ] [ piece ] [ piece ]  tray, pieces at 60% scale
│   ↶ Undo  ✦ Smash  ⟳ Reroll  │  booster row (counts as badges)
└───────────────────────────┘
```
iPad: the board is capped at ~640pt; the tray moves to the side in landscape (later).

---

## 2. Juice list (feel spec)

Haptics: `UIImpactFeedbackGenerator` unless noted. Every effect respects **Reduce Motion** (shake → none, particles → 30%, ball → fade) and the haptics toggle.

| Event | Visual | Audio | Haptic |
|---|---|---|---|
| Pick up piece | Scales 60% → 100%, lifts with a soft shadow, offset above the thumb | soft "tik" | `.light` |
| Hover valid spot | Ghost at 35% opacity; lines that *would* clear glow on the edges | — | `UISelectionFeedbackGenerator` on each new cell snap |
| Hover invalid | Ghost tinted red, no glow | — | none |
| Place piece | Squash 1.0 → 0.9 → 1.05 → 1.0 (120ms), small dust puff | brick "thunk" (pitch varies by piece size) | `.medium` |
| Invalid drop | Piece springs back to the tray | low "bonk" | `.soft` |
| Line clear (1) | Ball launches from the paddle, travels the line (~180ms), each brick cracks then bursts into 6–8 shards in its color; "+10" pops | brick-break SFX per brick, rising pitch along the line | `.rigid` |
| Combo ×2–×3 | Lines resolve in sequence; COMBO ×N bar slams in from the left (yellow, ink outline); 4pt screen kick | arpeggio stinger, one note higher per line | `.heavy` + Core Haptics transient per line |
| Combo ×4+ | Same + a quick white flash and slow-mo (0.6× for 250ms) | full stinger + crowd "woo" | Core Haptics pattern |
| Streak | Flame chip on the score counts up; the ball trail gets longer per streak level | layer a hi-hat per streak | — |
| Steel brick first hit | Cracks (texture swap), sparks, stays put | metallic "clank" | `.rigid` |
| Gold collected | Coin flies to the goal chip; the chip pulses | coin "ding" | `.light` ×2 |
| Perfect Clear | Ball rally: bounces around the empty board 3×, confetti in brick colors | fanfare | success notification |
| Tray refill | 3 pieces drop in staggered (60ms), with bounce | "whoosh-tok" | — |
| Near-miss / lose | Board dims; the closest-fit gap pulses yellow; "So close!" | descending 3-note | warning notification |
| Win | Bricks rain into the star slots; stars stamp in one by one | star "chunk" ×N | `.medium` per star |
| Coin count-up | Odometer roll in the header | rapid ticks | — |

**Feel targets:** input-to-snap latency < 16ms; placement + clear resolve in < 400ms total (fast players must never wait); 120fps on ProMotion.

---

## 3. Audio direction

Short, warm, toy-like. Brick hits are the signature: a small set of woody/plastic "tock" samples pitched per color row, so combos accidentally sound musical. Music: one mellow lo-fi chiptune loop for Levels, one brighter loop for Time Attack; music and SFX each have their own toggle. Reuse Brick Breaker's SFX where it fits.

---

## 4. Screens (map to the existing 14-screen prototype)

1. **Splash:** One Bit sting (shared asset; Reduce Motion variant).
2. **First launch → straight into Level 1** (no home screen on the first session).
3. **Home:** map node + PLAY, header (coins, Day Streak), Daily Puzzle card, mode tiles (locked ones show the unlock level), next-unlock progress bar.
4. **Level map:** vertical path, chest every 5 levels, stars per node.
5. **Gameplay:** Levels / Classic / Daily / Time Attack variants (one scene, mode-driven HUD).
6. **Pause:** resume, restart, settings, home.
7. **Win card:** stars, coins earned, [Collect] and [2× ▶] rewarded, next.
8. **Lose card:** near-miss message, [Continue ▶] rewarded (choose Smash 3 or new tray), [Retry]. One continue per level.
9. **Classic game over:** score, best, new-best celebration, [Play again].
10. **Shop:** Themes · Trails · Boards tabs + Coins. (The prototype's "Items" tab becomes the booster inventory: counts plus "Watch for +1".)
11. **Theme preview:** live board with the theme applied before buying.
12. **Daily Puzzle calendar:** month view filled by Day Streak.
13. **Settings:** sound, music, haptics, colorblind glyphs, reduce motion (follows the system by default), restore purchases, privacy, credits.
14. **Starter pack / Remove Ads offer:** single calm card, clear price, a "No thanks" with equal visual weight.

---

## 5. FTUE (teach by doing)

| Step | Board setup | Teaches | Hint |
|---|---|---|---|
| L1 | Row 4 full except 3 cells; tray has a 1×3 | Drag + place + clear | One hand-pointer, drag path animated once |
| L2 | Two rows each missing the same 2×2 | Combos | none (setup teaches it) |
| L3 | Open board, goal "Collect 3 gold" | Level goals | Goal chip pulses once |
| L4 | — | Undo (2 free granted) | Booster glows after the first bad placement |
| L5 | First steel bricks | Multi-hit | Steel brick sparkles once |
| L6 | — | Smash (1 free) | — |
| L9 | — | Reroll (1 free) | — |

Rule: never more than one hint on screen; hints never block input; a skipped hint is never repeated.

---

## 6. Accessibility

Colorblind glyphs; Reduce Motion; haptics toggle; Dynamic Type for menus (gameplay HUD fixed to the 11px grid with a large-HUD option); VoiceOver labels for all menus. Board VoiceOver is out of scope for v1 (documented, not faked).
