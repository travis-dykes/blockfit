# Integrations still to wire (need packages / keys / a Mac)

Everything below has a protocol seam in `Core/` and a mock; the real SDK goes behind it.

| Seam | Real implementation | Needs |
|---|---|---|
| `StoreService` | RevenueCat (`Purchases`) in `Monetization/` — SKUs in `SKU` | RevenueCat API key, products in App Store Connect, SPM `purchases-ios` |
| `AdService` | BlockBreaker `AdService` (mediation, G-rated, non-personalized, no ATT) | Copy from BlockBreaker; rewarded placements: `RewardedPlacement` |
| `AnalyticsService` | PostHog, event names from `AnalyticsEvent.name` only | PostHog key, SPM `posthog-ios`; sample `piece_place` at 10% in caller |
| `ConfigService` | Firebase Remote Config → JSON → `ConfigMerge.apply` over `Defaults.json` | `GoogleService-Info.plist`, SPM `firebase-ios-sdk` |
| Crashes | Sentry | DSN, SPM `sentry-cocoa` |
| `ProgressionAdapter` | ProgressionKit (`PlayEvent` forwarding) | Shared One Bit package; flag any seam mismatch (Block Fit is the v1 forcing function) |
| Splash / shell / settings | One Bit splash, AppShell, Settings, Onboarding, Paywalls packages | Shared packages |
| Fonts | Departure Mono (11/22/33/44) bundled; `Theme.fontName` swap | Font file |
| Audio | `AudioService` with per-colour pitched brick SFX | Sample assets |

Decisions recorded: booster lane = Play Promise (earned/rewarded only, never sold, never bought with coins);
no ATT in v1; Comet Clear stays behind the debug toggle until the Gate 0/1 playtest decides.
