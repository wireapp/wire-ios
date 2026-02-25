# Research Question
Verify whether `WireAuthenticationAPI` currently acts primarily as an external interface boundary or as an internal seam between authentication targets.

## Summary
- Current evidence indicates: `WireAuthenticationAPI` exists, but it is used mostly as an intra-feature contract inside `WireAuthentication` targets, not as a primary external API.
- In imports, `WireAuthenticationAPI` appears **100 times inside** `WireAuthentication/*` and only **11 times outside** that package.
- `WireAuthenticationAPI` declares 47 public symbols, but in external files importing it, usage is concentrated to **5 symbols**: `AuthenticationResult`, `RegistrationAnalyticsTrackingConsent`, `RegistrationAnalyticsTrackerProtocol`, `AuthenticationType`, and `WireAuthenticationBridge`.
- `WireAuthenticationAPI` also contains **package-scoped declarations** (`ValidateEmailOrSSOCode*`) that are explicitly not public outside the Swift package, which reinforces that it serves sibling targets first.
- The app integration imports both `WireAuthentication` and `WireAuthenticationAPI`, meaning the feature does not present one cohesive façade module.
- Across all `Wire*/Package.swift`, only `WireAuthentication` exports a `*API` product; most other feature packages expose `Domain`/`Assembly`/`UI` products instead.
- Those other feature “public” boundaries are mostly concrete assembly modules and re-exports (e.g. `public import`), not dedicated API-contract modules.
- `package import` usage in `WireMessaging` and `WireCalling` indicates boundaries are often enforced at package scope, not at fine-grained public module boundaries.

## Detailed Findings

### 1) Entrypoints and exposed products
- `WireAuthentication` is split into four products (`WireAuthentication`, `WireAuthenticationAPI`, `WireAuthenticationLogic`, `WireAuthenticationUI`), with the root target depending on all three sibling targets.
- `WireMessaging` and `WireCalling` use `Domain`/`Assembly`/`UI` split, but do not define dedicated `*API` products.
- Repo-wide, `WireAuthenticationAPI` is the only exported product ending in `API`.

### 2) `WireAuthenticationAPI` as boundary vs internal seam
- Package-level dependency wiring shows `WireAuthenticationLogic` and `WireAuthenticationUI` both depend on `WireAuthenticationAPI`, making it the main shared contract between sibling targets.
- Internal import volume is high (`WireAuthenticationUI` + `WireAuthenticationLogic` + `WireAuthentication` all import it heavily).
- External consumers are few and concentrated in app auth flow glue code.
- The app uses both `WireAuthentication` and `WireAuthenticationAPI`, suggesting the “public interface” is split between modules.
- The API target contains package-only declarations (`package protocol/enum`) used by sibling targets, which is useful internally but not part of a public module contract.

### 3) What external code actually consumes
- External auth coordinator/event code uses only a narrow subset of API types:
  - flow result + analytics consent payload
  - analytics tracker protocol
  - authentication type for assembly input
  - bridge type
- Several external files import `WireAuthenticationAPI` but do not reference any of its public symbols directly, which suggests import sprawl / weak boundary definition.

### 4) Project-wide pattern check
- Feature packages commonly expose assembly modules with concrete constructors/factories, and often `public import` dependent modules.
- App code frequently imports multiple products from a feature package (`WireMessagingAssembly` + `WireMessagingDomain`) and adds retroactive conformances to domain protocols.
- This is a workable modular setup, but it is not a strict “one stable public interface module per feature” architecture.

## Code References
- `WireAuthentication` product split and target dependencies:
  - `WireAuthentication/Package.swift:12`
  - `WireAuthentication/Package.swift:13`
  - `WireAuthentication/Package.swift:27`
  - `WireAuthentication/Package.swift:50`
  - `WireAuthentication/Package.swift:63`
- `WireAuthentication` root assembly depends on API + internal modules:
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:23`
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:28`
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:31`
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:40`
- App auth integration requires both modules:
  - `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:22`
  - `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:23`
  - `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:128`
  - `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:301`
- External auth event handling uses a narrow API subset:
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/AuthenticationCoordinatorAction.swift:20`
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/AuthenticationCoordinatorAction.swift:32`
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/AuthenticationEventResponderChain.swift:20`
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/AuthenticationEventResponderChain.swift:54`
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/WireAuthenticationModuleCompletionHandler.swift:20`
  - `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/WireAuthenticationModuleCompletionHandler.swift:28`
- `WireAuthenticationAPI` includes package-scoped non-public contracts:
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:21`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:27`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:40`
- `WireAuthenticationAPI` public declarations used externally (examples):
  - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:26`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:24`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Utilities/RegistrationAnalyticsTrackerProtocol.swift:24`
- Comparative package shapes (no dedicated API module):
  - `WireMessaging/Package.swift:12`
  - `WireMessaging/Package.swift:13`
  - `WireMessaging/Package.swift:14`
  - `WireCalling/Package.swift:12`
  - `WireCalling/Package.swift:13`
  - `WireCalling/Package.swift:14`
- Assembly-style public surfaces and re-exports:
  - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:19`
  - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`
  - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:46`
  - `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:27`
- App consumption of multiple feature products:
  - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:19`
  - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:25`
  - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:26`
  - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`
  - `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewControllerBuilder.swift:22`
  - `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewControllerBuilder.swift:23`
- Package-scope cross-target coupling examples:
  - `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveNodeUploadManager.swift:21`
  - `WireCalling/Sources/WireCallingUI/Views/WireMeetings/MeetingsView/MeetingsViewModel.swift:20`

## Architecture / Design Insights
- Current module architecture is **feature-sliced but not interface-first**. The architecture favors composing concrete `Assembly`/`UI`/`Domain` targets over publishing a single stable API module per feature.
- `WireAuthenticationAPI` is a hybrid: partly external contract, partly sibling-target contract. The package-scoped declarations and heavy internal usage show it is optimized for internal target collaboration.
- Public boundary ownership is split (e.g. app must import both `WireAuthentication` and `WireAuthenticationAPI`), which weakens discoverability and makes integration contracts less explicit.
- Re-export (`public import`) and package-level sharing (`package import`) are used as convenience mechanisms, but they blur boundary intent and make module contracts less strict.

## Best-Practice Evaluation (Public Interface Design)

### Criteria and assessment
- **Single integration-facing facade per feature**: **Partial**
  - `WireAuthentication` has a facade-like assembly (`WireAuthenticationAssembly`) but app integration still imports `WireAuthenticationAPI` directly, so one-module integration is not achieved.
  - Evidence: `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:33`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:22`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:23`.
- **Public interface is consumer-driven and minimal**: **Partial**
  - `WireAuthenticationAPI` has broad public surface (47 symbols), but external consumers use only a narrow subset (mainly result/consent/tracker/bridge/auth type).
  - Evidence: `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:24`, `WireAuthentication/Sources/WireAuthenticationAPI/Utilities/RegistrationAnalyticsTrackingConsent.swift:21`, `WireAuthentication/Sources/WireAuthenticationAPI/Utilities/RegistrationAnalyticsTrackerProtocol.swift:24`, `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/AuthenticationEventResponderChain.swift:54`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:128`.
- **No internal-only contracts in public API module**: **Not yet met**
  - `WireAuthenticationAPI` contains `package`-scoped contracts (`ValidateEmailOrSSOCode*`) aimed at sibling targets, indicating mixed external/internal role in one module.
  - Evidence: `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:21`, `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:27`, `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/ValidateEmailOrSSOCodeUseCaseProtocol.swift:40`.
- **Dependency inversion around contracts**: **Pass (inside feature) / Partial (at app boundary)**
  - Inside auth, UI/logic depend on protocol contracts in API target (good).
  - At app boundary, app depends on both facade and API module directly (not ideal).
  - Evidence: `WireAuthentication/Package.swift:50`, `WireAuthentication/Package.swift:63`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:22`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:23`.
- **Stable boundary independent from implementation packaging details**: **Partial**
  - `WireAuthenticationBridge` is a useful stable seam, but app event handling also depends on auth API payload types directly.
  - Evidence: `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:26`, `wire-ios/Wire-iOS/Sources/Authentication/Event Handlers/WireAuthenticationModuleCompletionHandler.swift:28`.
- **Avoid transitive API leakage (`public import`)**: **Partially met (project-wide risk)**
  - Assembly modules in other features expose broad dependencies via `public import`, which inflates effective public surface and weakens explicit contracts.
  - Evidence: `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:19`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:23`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:26`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:22`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:25`.
- **Clear layering and directional boundaries**: **Partial**
  - `package import` usage across sibling modules (`WireMessaging`, `WireCalling`) enforces package-level direction, but still couples modules tightly at package scope.
  - Evidence: `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveNodeUploadManager.swift:21`, `WireCalling/Sources/WireCallingUI/Views/WireMeetings/MeetingsView/MeetingsViewModel.swift:20`.
- **Consistent interface strategy across features**: **Not yet met**
  - Auth uses an `API` product; other feature packages expose `Domain/Assembly/UI` without dedicated API contract products, so interface style is inconsistent across the monorepo.
  - Evidence: `WireAuthentication/Package.swift:13`, `WireMessaging/Package.swift:12`, `WireMessaging/Package.swift:13`, `WireMessaging/Package.swift:14`, `WireCalling/Package.swift:12`, `WireCalling/Package.swift:13`, `WireCalling/Package.swift:14`.

### Overall best-practice assessment
- `WireAuthenticationAPI` is a **useful architectural artifact**, but by public-interface best-practice standards it is currently a **mixed-purpose boundary** (internal seam + external interface), not a clean external contract module.
- Across the repository, interface-boundary quality is **functional but inconsistent** with strict public-interface architecture patterns.

## Suggested Next Step (Detailed Example)
### Split host-facing interface from internal sibling contracts
- Keep `WireAuthenticationAPI` focused on intra-feature contracts between auth targets.
- Add a host-facing `WireAuthenticationInterface` product for app consumers.
- Route app integration through one interface boundary, not direct `WireAuthenticationAPI` imports.

### Incremental migration plan
1. Introduce `WireAuthenticationInterface` with minimal host contracts (`startAuthentication` + typed result).
2. Keep current auth internals unchanged (`WireAuthentication`, `WireAuthenticationLogic`, `WireAuthenticationUI`, `WireAuthenticationAPI`).
3. In `WireAuthentication` assembly layer, adapt internal API/bridge types to interface types.
4. Migrate app call sites to import `WireAuthenticationInterface` and stop importing `WireAuthenticationAPI`.
5. After migration, reduce `WireAuthenticationAPI` public surface to sibling-target needs only.

### Scope note (important)
- This step standardizes boundary ownership and import shape for auth.
- It does not require immediate rewrite of auth internals.
- Routing-capability API shape can evolve in the routing subreport track without blocking this boundary cleanup.

### Validation criteria for this pilot
- App auth integration files import `WireAuthenticationInterface` without `WireAuthenticationAPI`.
- `WireAuthenticationAPI` public declarations used by app drop to zero.
- Auth flow behavior remains unchanged for existing login/registration paths.

## Related Notes
- `README.md:22` (high-level layering: sync engine + UI)
- No dedicated interface-boundary design note was found under `thoughts/*` in this workspace snapshot.

## Open Questions / Follow-ups
- Should each feature package expose exactly one integration-facing product (facade) and keep `Domain/UI/Data/Logic` internal?
- For authentication specifically: should `WireAuthentication` re-export or wrap the required API types so app code only imports one product?
- Should package-scoped contracts currently inside `WireAuthenticationAPI` move to a non-public internal target to keep the API target strictly external?
- Which external consumers (if any) outside this repository must be supported by these modules? This affects how stable and minimal public API must be.
