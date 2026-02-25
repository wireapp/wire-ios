# Research Question
Verify whether current public-interface practices across extracted feature packages (excluding the already-known `WireAuthenticationAPI` case) satisfy critical modular-interface quality criteria:
- pure interface boundaries,
- stable/minimal contracts,
- design-token-driven styling,
- no upstream knowledge,
- and swappability of interface layer?

## Summary
- Current evidence indicates that, outside `WireAuthenticationAPI`, public-interface practice is mostly not interface-first.
- The interface strategy is inconsistent across packages: Auth has a dedicated `*API` product, while Messaging/Calling expose `Domain`/`Assembly`/`UI` products.
- Boundary modules frequently mix presentation, composition, and infrastructure wiring.
- Messaging has the strongest boundary leakage: assembly re-exports many modules and UI imports data internals.
- Contracts are not consumer-flat; many public entrypoints use domain protocols/types directly.
- App integration is broad (imports and links multiple products per feature), so interface swapping is not localized.
- A design-token system exists (`WireDesign` + `WireAccentColor`), but some feature APIs still accept raw styling inputs (`Color` closures/parameters).
- Calling is narrower at app boundary than Messaging, but `WireMeetingsFactory` still wires a concrete repository in the boundary.
- Overall assessment: the current public-interface model does not yet address key pain points of strict modular-boundary design.

## Detailed Findings

### Thread 1: Public interface pattern across extracted packages
- `WireAuthentication` exposes a dedicated API product (`WireAuthenticationAPI`) (`WireAuthentication/Package.swift:13`).
- `WireMessaging` and `WireCalling` expose `Domain` + `Assembly` + `UI`, not a single integration API (`WireMessaging/Package.swift:12`, `WireMessaging/Package.swift:13`, `WireMessaging/Package.swift:14`, `WireCalling/Package.swift:12`, `WireCalling/Package.swift:13`, `WireCalling/Package.swift:14`).
- `WireUI` exports many feature/UI products and directly depends on domain/logging packages (`WireUI/Package.swift:12`, `WireUI/Package.swift:22`, `WireUI/Package.swift:31`, `WireUI/Package.swift:116`, `WireUI/Package.swift:118`).

Assessment:
- Interface strategy is not unified; different features expose different boundary shapes.

### Thread 2: Pure boundary layer (presentation-only) check
- `WireMessagingFactory` (assembly boundary) performs infrastructure wiring and use-case construction (`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:46`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:54`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:59`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:113`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:170`).
- `WireMessagingUI` imports `WireMessagingData` and composes domain/data use cases inside UI containers (`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:73`).
- `WireCallingAssembly` wires `MeetingsRepository.demo()` in the public factory path (`WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:40`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:45`).
- `WireSettingsUI` backup module includes workflow/state-machine style logic and file coordination in view-model layer (`WireUI/Sources/WireSettingsUI/Account/BackupImportExport/Import/ImportBackupViewModel.swift:62`, `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/Import/ImportBackupViewModel.swift:152`, `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/Import/ImportBackupViewModel.swift:238`, `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/Import/ImportBackupViewModel.swift:266`).
- `WireIndividualToTeamMigrationUI` controller owns transition orchestration and directly executes use case (`WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:178`, `WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:266`, `WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:270`).

Assessment:
- "Pure presentation boundary" is mostly not met.

### Thread 3: Stable contracts (flat props vs domain coupling)
- `ChannelViewFactory` public API uses domain permission + repository contract (`WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:27`, `WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:29`, `WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:44`).
- `ConversationTypePickerFactory` public API takes/returns domain enum (`WireMessaging/Sources/WireMessagingAssembly/ConversationTypePickerFactory.swift:29`, `WireMessaging/Sources/WireMessagingAssembly/ConversationTypePickerFactory.swift:30`).
- `ConversationsAssembly` takes domain repository protocols in boundary signature (`WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:28`, `WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:29`).
- `BackupImportExportBuilder` boundary requires domain use-case and logging contracts (`WireUI/Sources/WireSettingsUI/Account/BackupImportExport/BackupImportExportBuilder.swift:28`, `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/BackupImportExportBuilder.swift:39`, `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/BackupImportExportBuilder.swift:41`).
- `IndividualToTeamMigrationViewController` boundary requires domain use case (`WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:112`, `WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:121`).

Assessment:
- Contracts are not flat/view-data-first; domain contracts are part of public integration signatures.

### Thread 4: Minimal public surface
- `WireMessagingAssembly` re-exports dependencies via `public import` (`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:19`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:23`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:26`).
- App target links all messaging products plus calling UI/assembly (`wire-ios/Wire-iOS.xcodeproj/project.pbxproj:943`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:944`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:948`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:950`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:979`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1392`).
- App source import scan:
  - `WireMessagingDomain` 43,
  - `WireMessagingUI` 13,
  - `WireMessagingAssembly` 12,
  - `WireCallingAssembly` 3,
  - `WireCallingDomain` 0,
  - `WireCallingUI` 0.
- App defines a local `WireMessagingFactoryProtocol` mirroring messaging-domain use cases and UI types (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:23`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:30`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:52`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:63`).

Assessment:
- Public boundary is broad for Messaging; calling boundary is narrower but still links extra products in app target.

### Thread 5: No upstream knowledge and swappability
- App must implement/adapt feature contracts and mappings:
  - domain protocol conformances in app (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:147`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:149`),
  - domain<->network mapping in app repository (`wire-ios/Wire-iOS/Sources/ChannelRepository.swift:47`, `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:86`, `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:97`).
- App UI imports multiple messaging layers in single features (example `ConversationViewController`) and uses both assembly factory and UI type directly (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:29`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:175`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:212`).
- Start UI uses domain enum and assembly factory directly (`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:53`, `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:60`).

Assessment:
- Interface layer is not swappable without app-level changes; consumers hold upstream knowledge of domain and implementation seams.

### Thread 6: Theming/tokens contract
- Positive: explicit token layer exists (`WireAccentColor`, design mapping, environment entry) (`WireFoundation/Sources/WireFoundation/WirePrimitives/WireAccentColor.swift:21`, `WireUI/Sources/WireDesign/Colors/UIColor+initWithAccentColor.swift:24`, `WireUI/Sources/WireDesign/Colors/EnvironmentValues+wireAccentColor.swift:24`).
- But interface APIs also expose raw style controls (`Color` / accent closures) (`WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:28`, `WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:42`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:145`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:165`).

Assessment:
- Token system is present, but contract purity around styling is only partial.

## Best-Practice Evaluation Matrix
- Pure boundary layer: **Not yet met** (Messaging assembly/UI, Calling assembly, Settings/migration UI own non-presentation logic).
- Stable input contracts: **Partially met** (public APIs take domain protocols/enums/use cases instead of flat props).
- Minimal public surface: **Not yet met (Messaging) / Partially met (Calling)**.
- Design as contract (theming/tokens): **Partial** (token infrastructure exists; boundary APIs still expose raw style parameters).
- No upstream knowledge: **Not yet met** (app adapters/mappings/protocol conformances required).
- Swappable interface layer: **Not yet met** (app imports multiple feature products and uses mixed contracts directly).

## Code References
- `WireAuthentication/Package.swift:13`
- `WireMessaging/Package.swift:12`
- `WireMessaging/Package.swift:47`
- `WireMessaging/Package.swift:55`
- `WireCalling/Package.swift:12`
- `WireCalling/Package.swift:46`
- `WireUI/Package.swift:70`
- `WireUI/Package.swift:113`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:19`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:46`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:170`
- `WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:27`
- `WireMessaging/Sources/WireMessagingAssembly/ConversationTypePickerFactory.swift:29`
- `WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:28`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`
- `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`
- `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/BackupImportExportBuilder.swift:28`
- `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/Import/ImportBackupViewModel.swift:152`
- `WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:121`
- `WireUI/Sources/WireIndividualToTeamMigrationUI/IndividualToTeamMigrationViewController.swift:270`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:23`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:83`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`
- `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:47`
- `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:86`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:175`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:212`
- `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:53`
- `wire-ios/Wire-iOS/Sources/UserInterface/GroupDetails/GroupDetailsViewController.swift:624`
- `wire-ios/Wire-iOS/Sources/UserInterface/Settings/CellDescriptors/SettingsCellDescriptorFactory+Account.swift:426`
- `wire-ios/Wire-iOS/Sources/UserInterface/SelfProfile/SelfProfileViewController.swift:316`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:943`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:979`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1392`
- `WireFoundation/Sources/WireFoundation/WirePrimitives/WireAccentColor.swift:21`
- `WireUI/Sources/WireDesign/Colors/EnvironmentValues+wireAccentColor.swift:24`
- `WireUI/Sources/WireDesign/Colors/UIColor+initWithAccentColor.swift:24`

## Architecture / Design Insights
- Current module architecture is feature-extraction-first, not contract-first: modules are separated, but boundary ownership is still distributed between app and feature internals.
- Messaging is the main counterexample to "clean interface boundary": app consumes all three products and also implements feature domain contracts.
- Calling demonstrates a narrower consumer boundary pattern, but still composes concrete data sources in the boundary (`WireMeetingsFactory`), which weakens contract purity.
- `WireUI` carries both design-system assets and feature-specific workflow modules, which blurs the line between reusable interface kernel and feature interfaces.

## Suggested Next Step (Detailed Example)
### FeatureInterface pilot on `WireCalling` (smallest practical scope)
- Why this pilot:
  - `WireCalling` is currently the smallest extracted feature package among the three reviewed feature packages.
  - Host integration for calling is already relatively narrow (`WireCallingAssembly` usage in a small number of app files), which keeps migration risk contained.
  - Evidence:
    - `WireCalling/Package.swift:12`
    - `WireCalling/Package.swift:13`
    - `WireCalling/Package.swift:14`
    - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:19`
    - `wire-ios/Wire-iOS/Sources/UserInterface/Calling/Meetings/WireMeetingsFactoryProtocol.swift:21`

### Naming and boundary rule
- Use `FeatureInterface` naming (for example `WireCallingInterface`) instead of `FeatureAPI`.
- Intentional distinction: this is not the same concept as current `WireAuthenticationAPI`.
- `WireCallingInterface` should be strictly host-facing integration contract surface.
- Do not expose dependency-carrier types in the interface module; dependencies should be resolved by global DI composition.
- Internal module split (`Domain/Data/UI/Assembly`) can remain, but host should consume only `WireCallingInterface`.

### Proposed package shape for the pilot
- Add a new product + target:
  - product: `WireCallingInterface`
  - target: `WireCallingInterface`
- Move host-facing contracts into `WireCallingInterface`:
  - feature entry protocol(s),
  - minimal input/output types needed by host integration.
- Keep `WireCallingAssembly` as implementation module:
  - `WireCallingAssembly` conforms to interface contracts,
  - `WireCallingAssembly` keeps internal dependency graph ownership,
  - dependency wiring is handled in global composition/DI bootstrap, not in feature consumer code.

### Incremental migration plan
1. Introduce `WireCallingInterface` with one minimal host contract aligned to current use.
2. Make `WireMeetingsFactory` conform to that interface without changing runtime behavior.
3. Migrate app call sites to import `WireCallingInterface` instead of `WireCallingAssembly`.
4. Keep a temporary allowlist for legacy imports while migration lands.
5. Add a guardrail check in CI to prevent new direct host imports of `WireCallingAssembly`/`WireCallingDomain`/`WireCallingUI` in app production sources.

### Example contract and usage sketch
`WireCallingInterface` (host-facing contract only):

```swift
import UIKit

public struct WireCallingMeetingsOptions: Sendable {
    public let isContextMenuAllowed: Bool

    public init(isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed
    }
}

public protocol WireCallingFeatureInterface {
    @MainActor
    func makeMeetingsView(options: WireCallingMeetingsOptions) -> UIViewController
}
```

`WireCallingAssembly` implementation (dependencies internal to DI/composition):

```swift
import WireCallingInterface

public struct WireMeetingsFactory: WireCallingFeatureInterface {
    private let passwordValidator: any PasswordValidator

    @MainActor
    public init(passwordValidator: any PasswordValidator) {
        self.passwordValidator = passwordValidator
    }

    @MainActor
    public func makeMeetingsView(options: WireCallingMeetingsOptions) -> UIViewController {
        let meetingsViewModel = AllMeetingsViewModel(
            repository: MeetingsRepository.demo(),
            currentDateProvider: .system,
            pastMeetingsUseCase: FetchPastMeetingsUseCase(
                repository: MeetingsRepository.demo(),
                currentDateProvider: .system
            ),
            upcomingMeetingsUseCase: FetchUpcomingMeetingsUseCase(
                repository: MeetingsRepository.demo(),
                currentDateProvider: .system
            ),
            passwordValidator: passwordValidator,
            isContextMenuAllowed: options.isContextMenuAllowed
        )

        return UIHostingController(rootView: AllMeetingsView(viewModel: meetingsViewModel))
    }
}
```

Global app DI bootstrap (implementation import allowed only in composition root):

```swift
import WireCallingInterface
import WireCallingAssembly

@MainActor
func buildAppContainer() -> AppContainer {
    let callingFeature: any WireCallingFeatureInterface = WireMeetingsFactory(
        passwordValidator: AuthenticationPasswordValidator()
    )

    return AppContainer(callingFeature: callingFeature)
}
```

App consumer usage (no `WireCallingAssembly` import):

```swift
import WireCallingInterface

let meetingsUI = callingFeature.makeMeetingsView(
    options: .init(isContextMenuAllowed: SecurityFlags.clipboard.isEnabled)
)
```

### Scope note (important)
- This pilot addresses integration-interface consistency only.
- It does **not** solve routing capability design yet.
- Even with `options` in interface, if the contract is still `makeMeetingsView(...) -> UIViewController`, routing remains screen-factory based.
- Flow-capability routing contracts (`start flow + typed result`) should be handled in a dedicated follow-up track (routing report/issue).

### Validation criteria for the pilot
- App production sources import `WireCallingInterface` and no longer require direct `WireCallingAssembly` imports (outside approved transition allowlist).
- App-local wrapper protocol (`WireMeetingsFactoryProtocol`) can be reduced/removed because the contract is now feature-owned.
- A calling-boundary change is implemented with fewer host adaptation points than before (measured in touched app integration files).
- No behavior regressions in meetings entrypoints.

## Suggested Next Step (Detailed Example - Assembly Export Hygiene)
### Narrow `WireMessagingAssembly` public surface (remove transitive re-exports)
- Why this pilot:
  - It is a low-risk, high-signal boundary hardening step: mostly import-surface cleanup with minimal runtime behavior impact.
  - Re-exporting in assembly currently broadens effective API beyond intentionally-owned contracts.
  - Evidence:
    - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`
    - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:23`
    - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`
    - `WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:21`
    - `WireMessaging/Sources/WireMessagingAssembly/ChannelViewFactory.swift:20`
    - `WireMessaging/Sources/WireMessagingAssembly/ConversationTypePickerFactory.swift:20`

### Boundary rule for this pilot
- `WireMessagingAssembly` publishes public declarations, not transitive module exports.
- In assembly targets, replace `public import` with plain `import` for feature/shared modules.
- App consumers must explicitly import modules they use (`WireMessagingDomain`, `WireMessagingUI`, `WireFoundation`, etc.).
- Keep host behavior unchanged; this is an API-surface hardening step, not a feature rewrite.

### Example refactor sketch
Current import style in assembly (re-exporting transitive modules):

```swift
public import WireData
public import WireFoundation
public import WireMessagingDomain
public import WireMessagingUI
```

Pilot target style (no transitive re-export):

```swift
import WireData
import WireFoundation
import WireMessagingDomain
import WireMessagingUI
```

Consumer usage should be explicit at call sites:

```swift
import WireMessagingAssembly
import WireMessagingDomain
import WireMessagingUI
```

(`StartUIViewController` already follows this explicit import pattern:
`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:25` through `:27`.)

### Incremental migration plan
1. Replace `public import` with `import` in `WireMessagingAssembly` public entry files.
2. Build `WireMessaging` + app target; fix compile errors by adding explicit imports in consumer files where needed.
3. Keep public API declarations unchanged unless a specific symbol must be intentionally narrowed.
4. Add CI guardrail to reject new `public import Wire*` inside `WireMessagingAssembly` sources.
5. Repeat the same policy in other assembly modules after this pilot stabilizes.

### Scope note (important)
- This pilot hardens assembly export boundaries only.
- It does **not** replace issue 1 (`FeatureInterface` integration boundary policy).
- It does **not** replace issue 2 (centralized DI/container strategy).
- It does **not** replace issue 5 (flow-capability routing contracts).

### Validation criteria for this pilot
- No `public import Wire*` remains under `WireMessaging/Sources/WireMessagingAssembly`.
- App/feature builds pass with explicit imports added where required.
- New app code does not gain transitive access to `WireMessagingDomain`/`WireMessagingUI` via assembly imports alone.
- No runtime behavior regressions in Messaging entrypoints (files view, conversation screen, channel settings).

## Related Notes
- `thoughts/shared/research/2026-02-24-authentication-api-boundary-subreport.md`
- `thoughts/shared/research/2026-02-24-di-container-subreport.md`
- `thoughts/shared/research/2026-02-24-messaging-calling-locality-subreport.md`

## Open Questions / Follow-ups
- Should each feature converge to one integration-facing `FeatureInterface` product with `Domain/UI/Data` internal by default?
- For Messaging specifically, should `WireMessagingUI` stop importing `WireMessagingData` and consume only explicit domain interfaces?
- Should `WireMessagingAssembly` drop `public import` re-exports and publish a narrower API surface?
- Should `WireCallingAssembly` compose meetings through injected contracts instead of concrete `MeetingsRepository.demo()` wiring?
- Should routing capability contracts be introduced as a second step after integration-interface convergence (instead of mixing both concerns in one migration)?
- Should `WireUI` split feature workflows (e.g., settings backup, migration) from reusable UI/design modules to enforce cleaner interface boundaries?
