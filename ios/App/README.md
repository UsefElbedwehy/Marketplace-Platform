# App (composition root)

The thin app target. Registers concrete Factory implementations, reads the bundled Development Schema, drives the boot sequence, and owns the top-level coordinators. See [docs/planning/02-ios-architecture.md §9](../../docs/planning/02-ios-architecture.md#9-composition-root--white-label-wiring).

**Status:** implemented and verified live in the iOS Simulator (boot → auth → tab shell → sign-out), in light, dark, and RTL (Arabic). Phase 4 wired the Home/Search/Sell tabs to real `Features/Listings`/`Features/Search` content (Chat remains a placeholder — Phase 6) and verified the golden path end-to-end.

## Why this isn't just another SPM package

`ios/Packages/*` are plain Swift packages — buildable/testable with bare `swift build`/`swift test`, no Xcode project needed. The App target is different: it needs to become a real, installable `.app` you can boot in the Simulator. A bare SPM `.iOSApplication` product (`import AppleProductTypes`) **builds** via `xcodebuild build -scheme App` but does **not** get wrapped into a `.app` bundle by the CLI (verified: it only emits a raw Mach-O executable) — that packaging step appears to require Xcode's own IDE build system, not available headlessly here.

[Tuist](https://tuist.dev) (already installed on this machine) generates a real `.xcodeproj`/`.xcworkspace` from `ios/Tuist.swift` + `ios/Tuist/Package.swift` (external/local package resolution) + `ios/Project.swift` (the actual target definitions) — that workspace **does** produce a proper `.app`, installable via `xcrun simctl install` and screenshot-able via `xcrun simctl io ... screenshot`. The packages themselves are untouched by this — Tuist only wraps `ios/App`.

## Building & running

```bash
cd ios
tuist install    # resolves ios/Tuist/Package.swift (Factory, swift-snapshot-testing)
tuist generate --no-open

# Requires the local backend gateway running first (see backend/README.md):
#   cd backend && deno task serve

xcodebuild -workspace MarketplacePlatform.xcworkspace -scheme MarketplacePlatform \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Composition root (`Sources/App/Composition/Container+Registrations.swift`)

Every `DomainKit`/`Networking`/`Configuration` protocol is bound to its concrete implementation exactly once, here — `TokenStore`, `APIClient` (`URLSessionAPIClient` against `AppEnvironment.apiBaseURL`, default `http://localhost:8000`), the `ConfigurationDataSource` chain, and `DesignSystem`'s `ThemeStore` are declared directly (App-only concerns). `registerDependencies()` supplies the concrete implementation for every *cross-module* registration point declared in `DomainKit`'s `DIRegistrationPoints.swift` — `ConfigRepositoryImpl`/`AuthRepositoryImpl`/`CategoryRepositoryImpl`/`ListingRepositoryImpl` and their four use cases — via Factory's `.register(factory:)` override, called once from `MarketplacePlatformApp.init()`. See `ios/Packages/DomainKit/README.md` for why the *declaration* lives in `DomainKit` rather than here (Feature packages need to resolve these too, and can't see anything declared in `App`).

## Boot → Auth → Main (`RootView.swift`, `Coordinators/AppCoordinator.swift`)

`AppCoordinator.start()` fetches config (`BootViewModel`, via the use case) and loads the theme (`ThemeStore.load()`, directly — theme has no `DomainKit` repository) **concurrently** via `async let`, then routes to `.auth` or `.main` depending on whether a session is already in the Keychain. `TabCoordinator` owns tab selection + one `NavigationPath` per tab (Home/Search/Sell/Chat/Profile). Home/Search/Sell render `Features/Listings`' `ListingFeedView`/`MyListingsView` and `Features/Search`'s `SearchView` (Phase 4); Chat is still a placeholder (Phase 6). `SellTabView` derives whether the signed-in identity is a moderator by asking `MyListingsViewModel` (which resolves it itself, fresh, on every load — see that package's README for why it isn't computed here anymore) and pushes `CreateListingView`/`ListingDetailView` via a `ListingsRoute` enum.

## Dev sign-in (`Auth/AuthView.swift`)

There is no real authentication yet (Phase 1's GoTrue-backed flows are unimplemented — ADR-0007). Mirrors the dashboard's `DevIdentitySwitcher` exactly: lists the same five fixed identities seeded by `backend/supabase/seed/02_dev_test_users.sql`, mints a token via `POST /v1/dev-auth` on tap. **Remove when real auth lands.**

## RTL / i18n (`Resources/Localizable.xcstrings`)

A String Catalog covering the App target's own user-facing strings (screen titles, headline sentences, tab labels/messages, Sign out) in English + Arabic. Deliberately does **not** localize the Profile screen's `app_role`/`tenant_id` labels (developer-facing debug data, not product copy) or `DesignSystem`'s own small default-English strings (out of scope for this phase — `DesignSystem` doesn't have per-locale resource wiring yet).

## Verification (`UITests/`)

Real `XCUITest`s drive the actual Simulator app against the real local backend gateway (no mocks) — there is no `xcrun simctl` tap/input primitive, so this is the mechanism for anything beyond a screenshot:

- `BootAndAuthUITests` — boot → tap "Dev Admin" → real `/v1/dev-auth` round trip → tab shell renders → Profile shows the session (`app_role: admin`) → sign out → back to auth. Asserts via accessibility identifiers (`dev-identity.<role>`, `profile.appRole`) — note SwiftUI's `.accessibilityElement(children: .combine)` on a multi-`Text` `Card` surfaces as a `StaticText` element, not `.otherElements`.
- `RTLLocaleUITests` — launches with `-AppleLanguages (ar) -AppleLocale ar_SA`, asserts the Arabic translations render and saves a screenshot confirming the layout actually mirrors (leading-aligned card text flips to the trailing/right edge), not just that strings translated.
- `TabShellSmokeUITests` — confirms Home/Search/Sell render real `Features/Listings`/`Features/Search` content (not Phase 3's placeholders) after being wired in.
- **`GoldenPathUITests`** (Phase 4 ⭐) — the golden-path proof itself: creates a Car, an Apartment, and a Phone through the identical `CreateListingView` code, walks the Car listing through the real moderation pipeline (submit for review → sign in as a moderator → approve), and confirms Search's dynamic filter (`brand = BMW`) surfaces it. Handles a real Keychain-persistence gotcha — `TokenStore`'s Keychain item survives across `app.launch()` within the same Simulator, so `signIn(as:)` always checks whether a session is already active and signs out first if it's the wrong identity, rather than assuming the auth screen is showing.
- **`SchemaLiveEditUITests`** (Phase 4 ⭐) — proves "edit a schema server-side → app reflects it after refresh, no rebuild": adds a new attribute to the Phones category through the real `catalog_editor`-gated write API (via `URLSession`, straight from the test, minting its own dev-auth token — no shell-out, since `Process` isn't available on iOS) while the app is already running, then confirms the field appears in the already-open create-listing form after re-selecting the same category.

Run: `xcodebuild -workspace MarketplacePlatform.xcworkspace -scheme MarketplacePlatform -destination 'platform=iOS Simulator,name=iPhone 17' test` (backend gateway must be running — `deno run --allow-net --allow-env --allow-read backend/scripts/serve-local.ts`). After adding/removing any source file, `tuist generate --no-open` must be re-run — Tuist bakes the file list into the generated `.xcodeproj` at generate time, so a file added directly to disk isn't picked up until then.

## Known finding

The new iOS 26 floating tab bar's selected-tab tint didn't pick up `.tint()` in manual testing, even though the same color renders correctly everywhere else (buttons, cards — confirmed via `DesignSystem`'s snapshot tests). See `ios/Packages/DesignSystem/README.md`'s note — not chased further with a static appearance-proxy hack since that would conflict with the live theme-hot-swap guarantee.
