# [Community Research] Repo-wide Modularization Progress Review + Early Risk Signals

## Context and intent
This is an independent, volunteer, free-of-charge architecture review prepared with coding-agent support (Codex 5.3 extra high) as a research assistant.

It is shared in a collaborative spirit:
- findings may be useful, partially useful, or not useful for your roadmap;
- some conclusions may be wrong and should be validated by maintainers;
- there are no expectations attached to this report.

If helpful, this can be treated as an early risk scan while modularization is still at a stage where directional corrections are relatively low-cost.

## Why this report exists
This is a consolidated, repo-wide summary of modularization progress across all reviewed threads:
- public interfaces and boundary quality (with detailed analysis of auth API boundary)
- DI/dependencies composition strategy
- Example features (messaging/calling) locality
- routing model
- shared/common module ownership
- data model ownership and anti-corruption layers
- tooling and DX guardrails

Goal: highlight potentially high-impact structural risks early, before they turn into large integration boilerplate and long-lived tech debt.

Source subreports consolidated in this master report:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md)
- [DI Container Subreport](./2026-02-24-di-container-subreport.md)
- [WireAuthenticationAPI Boundary Subreport](./2026-02-24-authentication-api-boundary-subreport.md)
- [WireMessaging/WireCalling Locality Subreport](./2026-02-24-messaging-calling-locality-subreport.md)
- [Routing Flow Capabilities Subreport](./2026-02-25-routing-flow-capabilities-subreport.md)
- [Shared/Common Modules Subreport](./2026-02-25-shared-modules-subreport.md)
- [Data Model Ownership Subreport](./2026-02-25-data-model-ownership-subreport.md)
- [Tooling and DX Subreport](./2026-02-25-tooling-dx-subreport.md)

---

## Current progress (facts)
- Feature extraction to SPM is real and substantial.
  - Messaging/Calling follow `Domain/Data/Assembly/UI` packaging ([`WireMessaging/Package.swift#L12`](WireMessaging/Package.swift#L12), [`WireCalling/Package.swift#L12`](WireCalling/Package.swift#L12)).
  - Auth follows a different package shape (`WireAuthentication` + `WireAuthenticationAPI/Logic/UI`) ([`WireAuthentication/Package.swift#L12`](WireAuthentication/Package.swift#L12)).
- Modern Swift package visibility is being used (`package`, `InternalImportsByDefault`) in newer modules.
- Strong bounded-context data modeling exists in parts of the repo (for example messaging/calling local domain models):
  - [`WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift#L25`](WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift#L25)
  - [`WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift#L28`](WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift#L28)
- Anti-corruption patterns exist where external APIs are mapped into feature-local DTO/domain types:
  - [`WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift#L88`](WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift#L88)

This is meaningful progress. The central observation is not "no modularization"; it is that boundary and composition rules are not yet consistent enough to keep integration cost flat as modules grow.

---

## What the current approach is optimizing for
- Incremental migration and shipping continuity.
- Feature package extraction without forcing immediate rewrite of host app composition.

This strategy is pragmatic. The tradeoff is that without strong guardrails, complexity shifts from "inside modules" to "between modules and app composition".

---

## Early risk radar (repo-wide, high leverage, to validate)

### Top Priority

## 1) Integration interface layer is not yet consistent across features
Subreport links:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md)
- [WireAuthenticationAPI Boundary Subreport](./2026-02-24-authentication-api-boundary-subreport.md)
- [WireMessaging/WireCalling Locality Subreport](./2026-02-24-messaging-calling-locality-subreport.md)

### Observation
Defining multiple products is not the issue by itself. The issue is that there is no consistent host-facing integration interface rule. Some features require app code to integrate across multiple internal layers, while others are closer to assembly/facade usage.

### Evidence
- Messaging integration from app currently requires direct imports of multiple feature layers in host screens:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L27`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L27)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L28`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L28)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L29`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift#L29)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L25`](wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L25)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L26`](wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L26)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L27`](wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift#L27)
- App defines a local messaging integration protocol that spans assembly/domain/ui types, indicating missing stable external interface:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L23`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L23)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L24`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L24)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L25`](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift#L25)
- App target links multiple messaging products directly:
  - [`wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1383`](wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1383)
  - [`wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1390`](wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1390)
  - [`wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1391`](wire-ios/Wire-iOS.xcodeproj/project.pbxproj#L1391)
- Auth integration is different: host imports both auth modules and calls assembly seam directly:
  - [`wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L22`](wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L22)
  - [`wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L23`](wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L23)
  - [`wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L305`](wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift#L305)
- Calling integration is narrower in app (assembly-only imports in observed host files), which further shows inconsistency:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L19`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L19)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift#L24`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift#L24)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Calling/Meetings/WireMeetingsFactoryProtocol.swift#L21`](wire-ios/Wire-iOS/Sources/UserInterface/Calling/Meetings/WireMeetingsFactoryProtocol.swift#L21)

### Potential impact if unchanged
Without a consistent integration interface layer, each feature develops custom host-integration patterns (imports, wrappers, adapters). That compounds app-boundary boilerplate and slows module evolution.

### Early warning signal
- New host call sites importing multiple internal feature layers.
- Growth in app-defined feature wrapper protocols (for example `*FactoryProtocol`) to bridge inconsistent boundaries.

### Suggested next step
Define and enforce a host-facing integration interface policy using `FeatureInterface` naming (intentionally not proposing `*API` naming):
- multiple internal products are allowed,
- but each feature exposes one explicit host integration interface product (for example `WireCallingInterface`),
- app consumer code imports only the interface product,
- implementation modules (for example `WireCallingAssembly`) are imported only in global DI/composition bootstrap.

Concrete pilot (smallest practical scope):
- start with `WireCalling` (`WireCallingInterface`) as the first migration target,
- move host-facing contract to interface module,
- keep dependencies hidden from interface (resolved in global DI),
- migrate app call sites from assembly imports to interface imports.

Detailed implementation sketch and acceptance criteria are documented in:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md), section `Suggested Next Step (Detailed Example)`.

Scope note:
- this step standardizes host integration boundaries,
- it does **not** yet solve flow-capability routing design (still tracked separately in issue 2).

---

## 2) Routing contracts are screen-factory oriented, not flow-capability oriented
Subreport links:
- [Routing Flow Capabilities Subreport](./2026-02-25-routing-flow-capabilities-subreport.md)
- [WireAuthenticationAPI Boundary Subreport](./2026-02-24-authentication-api-boundary-subreport.md)

### Observation
Cross-feature routing capabilities are not first-class public contracts.

### Evidence
- Auth public entrypoint returns assembled view + bridge:
  - [`WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift#L40`](WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift#L40)
- Internal routing abstraction remains package scoped:
  - [`WireAuthentication/Sources/WireAuthenticationUI/Views/Root/Router.swift#L25`](WireAuthentication/Sources/WireAuthenticationUI/Views/Root/Router.swift#L25)
- Bridge provides typed events but not a generic capability contract:
  - [`WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift#L54`](WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift#L54)

### Potential impact if unchanged
Host apps remain coupled to implementation-level flow assembly and lifecycle handling.

### Early warning signal
More feature callers requiring UI/assembly knowledge to start flows.

### Suggested next step
Introduce explicit flow-capability contracts via `FeatureInterface` boundary modules (not screen-factory assembly contracts):
- define `AuthenticationFlowCapability` in `WireAuthenticationInterface`,
- callers start flow via typed request and observe typed outcomes,
- auth implementation adapts current assembly/bridge internally,
- enforce policy: non-auth feature callers must not import `WireAuthenticationAssembly`/`WireAuthenticationUI`.

Concrete pilot:
- start with one auth-gated caller path (for example a messaging login gate),
- route via `AuthenticationFlowCapability` and remove direct auth assembly usage from that path.

Detailed implementation sketch and acceptance criteria are documented in:
- [Routing Flow Capabilities Subreport](./2026-02-25-routing-flow-capabilities-subreport.md), section `Suggested Next Step (Detailed Example)`.

Scope note:
- this step standardizes routing capability contracts at feature boundaries,
- it does **not** require immediate rewrite of internal auth routing internals,
- DI standardization remains tracked in issue 3 and is intentionally not prescribed in this issue.

---

## 3) App-boundary DI/composition cost is growing at use-case granularity
Subreport links:
- [DI Container Subreport](./2026-02-24-di-container-subreport.md)
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md)

### Observation
The app composition layer wires many feature internals directly, including adapters/retroactive conformances, creating recurring DI boilerplate.

### Evidence
- Manual feature composition in app builder:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L83`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L83)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L105`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L105)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L115`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L115)
- App-side adapter/conformance seams:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L146`](wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift#L146)
- Needle exists but only in selected scopes:
  - [`WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift#L36`](WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift#L36)
  - [`WireDomain/Sources/WireDomain/Notifications/NotificationServiceExtension.swift#L64`](WireDomain/Sources/WireDomain/Notifications/NotificationServiceExtension.swift#L64)

### Potential impact if unchanged
Even with Needle usage in selected modules, host-level integration debt grows if composition remains fine-grained per use case/module.

### Early warning signal
Per feature PRs keep touching app composition files and adding adapter extensions.

### Suggested next step
Adopt centralized DI with module self-registration to reduce app-boundary boilerplate:
- introduce shared app container abstraction (`register`/`resolve`, scoped lifetimes),
- introduce module registrar contract implemented in feature implementation modules (for example `WireCallingRegistrar`),
- register feature interfaces once in global composition bootstrap,
- resolve/inject feature interfaces in app consumers (`container.resolve(WireCallingFeatureInterface.self)` or `@Dependency var wireCallingFeature: WireCallingFeatureInterface`),
- enforce policy: app consumers import interface modules only; implementation modules can be imported only in composition-root code.

Concrete pilot:
- start with `WireCalling` and move `WireMeetingsFactory(...)` construction into module self-registration,
- remove direct feature-factory construction from `ZClientControllerBuilder` and similar UI composition files.

Detailed implementation sketch and acceptance criteria are documented in:
- [DI Container Subreport](./2026-02-24-di-container-subreport.md), section `Suggested Next Step (Detailed Example)`.

Scope note:
- this step focuses on DI ownership/boilerplate reduction and centralized reuse,
- it does **not** yet solve flow-capability routing design (tracked separately in issue 2).

---

## 4) Tooling and module DX are underpowered for scale (metadata drift + missing automation)
Subreport links:
- [Tooling and DX Subreport](./2026-02-25-tooling-dx-subreport.md)

### Observation
Adding/editing modules currently requires manual synchronization across multiple systems (`Package.swift`, workspace refs, schemes/test plans, CI path filters, fastlane framework mapping). There is no single automated module scaffold/update path.

### Evidence
- Workspace-level package references are manually maintained:
  - [`wire-ios-mono.xcworkspace/contents.xcworkspacedata#L206`](wire-ios-mono.xcworkspace/contents.xcworkspacedata#L206)
  - [`wire-ios-mono.xcworkspace/contents.xcworkspacedata#L227`](wire-ios-mono.xcworkspace/contents.xcworkspacedata#L227)
  - [`wire-ios-mono.xcworkspace/contents.xcworkspacedata#L233`](wire-ios-mono.xcworkspace/contents.xcworkspacedata#L233)
  - [`wire-ios-mono.xcworkspace/contents.xcworkspacedata#L236`](wire-ios-mono.xcworkspace/contents.xcworkspacedata#L236)
- Manual CI path filters:
  - [`/.github/workflows/test_pr_changes.yml#L33`](.github/workflows/test_pr_changes.yml#L33)
  - [`/.github/workflows/test_pr_changes.yml#L57`](.github/workflows/test_pr_changes.yml#L57)
- Manual fastlane framework map:
  - [`/fastlane/framework.rb#L5`](fastlane/framework.rb#L5)
  - [`/fastlane/framework.rb#L143`](fastlane/framework.rb#L143)
- Plugin-specific convention hardcoded:
  - [`WirePlugins/Plugins/SwiftGenPlugin/SwiftGenPlugin.swift#L46`](WirePlugins/Plugins/SwiftGenPlugin/SwiftGenPlugin.swift#L46)
- Scheme/test-plan drift examples:
  - [`wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireCallingAll.xcscheme#L46`](wire-ios-mono.xcworkspace/xcshareddata/xcschemes/WireCallingAll.xcscheme#L46)
  - [`WireCalling/Tests/TestPlans/AllTests.xctestplan#L20`](WireCalling/Tests/TestPlans/AllTests.xctestplan#L20)
- Setup/build docs are focused on environment bootstrap and opening workspace, not module scaffolding automation:
  - [`setup.sh#L24`](setup.sh#L24)
  - [`setup.sh#L135`](setup.sh#L135)
  - [`README.md#L52`](README.md#L52)
  - [`README.md#L54`](README.md#L54)

### Potential impact if unchanged
- Module onboarding/editing has high cognitive load and many manual steps.
- Architecture drift shows up as CI misses or inconsistent integration behavior instead of explicit, fast feedback.
- Contributor DX degrades as module count grows.

### Early warning signal
- PRs that add/rename modules consistently touch many infra files.
- Adding new module takes more than 60 seconds.
- Frequent CI exceptions/manual fixes when new modules are added.
- Repeated discussions about whether to adopt project generation tooling (Tuist/XcodeGen) because current manual graph upkeep is too costly.

### Suggested next step
Run a Tuist/XcodeGen decision spike now, then choose automation path:
- preferred path: adopt generated-project single-source graph if spike confirms workflow/CI compatibility and acceptable migration cost,
- fallback path: keep current stack only if blockers are explicit, then enforce `doctor` + `sync` + `scaffold` harness.

Concrete rollout:
- run a 1-2 week Tuist/XcodeGen evaluation and publish adopt/defer decision with concrete arguments,
- first fix current `WireMessaging` manifest/source-layout inconsistency,
- run `doctor` as non-blocking in CI for one week, then make it blocking,
- add dedicated `WirePlugins` trigger path in PR tests so plugin-only changes always run validation.

Detailed implementation sketch and acceptance criteria are documented in:
- [Tooling and DX Subreport](./2026-02-25-tooling-dx-subreport.md), section `Suggested Next Step (Detailed Example - Module Lifecycle Automation Harness)`.

Scope note:
- this step addresses module DX and metadata drift guardrails,
- it prioritizes evaluating Tuist/XcodeGen now, but does **not** force adoption when blockers are material,
- it does **not** replace architecture dependency-direction checks (separate guardrail track).

---

### Mid Priority

## 5) Internal layer leakage: `WireMessagingUI -> WireMessagingData`
Subreport links:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md)
- [WireMessaging/WireCalling Locality Subreport](./2026-02-24-messaging-calling-locality-subreport.md)

### Observation
UI target directly imports data target and creates use-case graphs in UI containers.

### Evidence
- [`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift#L23`](WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift#L23)
- [`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift#L113`](WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift#L113)
- [`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift#L22`](WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift#L22)

### Potential impact if unchanged
Presentation and infrastructure concerns blend; test seams and substitution points get harder to maintain.

### Early warning signal
More UI files requiring direct data-layer imports.

### Suggested next step
Run a focused internal-layering pilot in Messaging (WireDrive files screens):
- enforce `WireMessagingUI` must not import `WireMessagingData`,
- introduce a UI-facing view-model factory protocol in `WireMessagingUI`,
- move `WireDrive*UseCase` graph composition from UI containers to `WireMessagingAssembly` (or assembly-internal composer),
- keep runtime behavior unchanged during migration ("move first, optimize second"),
- add guardrail checks to prevent new `WireMessagingUI -> WireMessagingData` imports.

Concrete pilot:
- migrate `FilesViewContainer` and `RecycleBinContainer` to consume `WireDriveFilesViewModelFactoryProtocol` only,
- implement the factory in assembly and wire it from `WireMessagingFactory.makeFilesView(...)`.

Detailed implementation sketch and acceptance criteria are documented in:
- [WireMessaging/WireCalling Locality Subreport](./2026-02-24-messaging-calling-locality-subreport.md), section `Suggested Next Step (Detailed Example)`.

Scope note:
- this step addresses internal feature layering (`UI -> Data`) and composition ownership only,
- it does **not** replace issue 1 (host-facing integration interface consistency),
- it does **not** replace issue 3 (app-boundary DI/container strategy),
- it does **not** replace issue 2 (flow-capability routing contracts).

---

## 6) Shared-module ownership drift (feature semantics in shared kernels)
Subreport links:
- [Shared/Common Modules Subreport](./2026-02-25-shared-modules-subreport.md)

### Observation
Broad shared modules (`WireFoundation`, `WireUI`) currently aggregate mixed concerns, so ownership boundaries are unclear and feature semantics can leak into shared kernels.

### Evidence
- `WireFoundation` exports many product scopes from one package and mixes primitives with workflow-oriented contracts:
  - [`WireFoundation/Package.swift#L8`](WireFoundation/Package.swift#L8)
  - [`WireFoundation/Package.swift#L12`](WireFoundation/Package.swift#L12)
  - [`WireFoundation/Sources/WireFoundation/WirePrimitives/QualifiedID.swift#L23`](WireFoundation/Sources/WireFoundation/WirePrimitives/QualifiedID.swift#L23)
  - [`WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/CreateBackupUseCaseProtocol.swift#L21`](WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/CreateBackupUseCaseProtocol.swift#L21)
  - [`WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEventTrackerProtocol.swift#L21`](WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEventTrackerProtocol.swift#L21)
- `WireUI` acts as an umbrella with many feature-level products/workflows:
  - [`WireUI/Package.swift#L11`](WireUI/Package.swift#L11)
  - [`WireUI/Package.swift#L18`](WireUI/Package.swift#L18)
  - [`WireUI/Package.swift#L22`](WireUI/Package.swift#L22)
  - [`WireUI/Sources/WireMoveToFolderUI/Models/Conversation.swift#L21`](WireUI/Sources/WireMoveToFolderUI/Models/Conversation.swift#L21)
  - [`WireUI/Sources/WireMoveToFolderUI/Protocols/UpdateConversationFolderUseCaseProtocol.swift#L22`](WireUI/Sources/WireMoveToFolderUI/Protocols/UpdateConversationFolderUseCaseProtocol.swift#L22)
- App-side retroactive adapters are needed for those shared feature workflows:
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Folders/CreateConversationFolderUseCase+CreateConversationFolderUseCaseProtocol.swift#L23`](wire-ios/Wire-iOS/Sources/UserInterface/Folders/CreateConversationFolderUseCase+CreateConversationFolderUseCaseProtocol.swift#L23)
  - [`wire-ios/Wire-iOS/Sources/UserInterface/Folders/UpdateConversationFolderUseCase+UpdateConversationFolderUseCaseProtocol .swift#L23`](wire-ios/Wire-iOS/Sources/UserInterface/Folders/UpdateConversationFolderUseCase+UpdateConversationFolderUseCaseProtocol%20.swift#L23)

### Potential impact if unchanged
Shared modules become long-term dumping grounds, so changes in one feature ripple through central packages and increase cross-team coordination cost.

### Early warning signal
New feature workflows/contracts continue to be added under `WireFoundation`/`WireUI`.

### Suggested next step
Decouple wide-scope shared modules using the new automation:
- with rules + tooling in place, progressively split/decompose broad shared modules (`WireFoundation`, `WireUI`, and next wide-scope candidates),
- start with bounded extraction waves that keep behavior unchanged and are easy to review,
- use automation for module scaffolding, dependency rewiring, and workspace/package updates.

Concrete first wave:
- extract `WireMoveToFolderUI` (+ support/tests) from `WireUI` into a feature-owned package,
- run the same extraction loop on the next narrow `WireFoundation` scope.

Detailed implementation sketch and acceptance criteria are documented in:
- [Shared/Common Modules Subreport](./2026-02-25-shared-modules-subreport.md), section `Suggested Next Step (Detailed Example - Decouple Wide-Scope Shared Modules)`.

Scope note:
- this step addresses broad-module decomposition and ownership convergence first,
- it does **not** redesign flow-capability routing contracts (tracked separately with issue 2),
- it does **not** prescribe a DI framework migration.

Main risk:
- regressions while extracting cross-cutting contracts.

Validation gate:
- fan-in to broad shared modules decreases,
- feature ownership boundaries become clearer.

---


### Low Priority

## 7) Assembly re-exports are widening effective public surface
Subreport links:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md)
- [WireMessaging/WireCalling Locality Subreport](./2026-02-24-messaging-calling-locality-subreport.md)

### Observation
Assembly exposes transitive dependencies through `public import`.

### Evidence
- [`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L22`](WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L22)
- [`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L23`](WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L23)
- [`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L24`](WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift#L24)

### Potential impact if unchanged
Transitive API knowledge leaks to consumers and blocks clean boundary narrowing later.

### Early warning signal
New app code depending on re-exported modules without explicit contract intent.

### Suggested next step
Run an assembly export-hygiene pilot on `WireMessagingAssembly`:
- replace `public import` with plain `import` in assembly public entry files,
- keep public API declarations explicit (declarations are public, transitive modules are not),
- require app consumers to explicitly import `WireMessagingDomain` / `WireMessagingUI` / `WireFoundation` when they use those symbols,
- keep behavior unchanged (this is boundary hardening, not feature redesign),
- add CI guardrail to block new `public import Wire*` inside `WireMessagingAssembly`.

Concrete pilot:
- start with `WireMessagingFactory`, `ConversationsAssembly`, `ChannelViewFactory`, and `ConversationTypePickerFactory`,
- fix resulting compile errors by adding explicit imports at consumer call sites where needed.

Detailed implementation sketch and acceptance criteria are documented in:
- [Public Interface Subreport](./2026-02-24-public-interface-subreport.md), section `Suggested Next Step (Detailed Example - Assembly Export Hygiene)`.

Scope note:
- this step narrows transitive assembly surface only,
- it does **not** replace issue 1 (`FeatureInterface` host-boundary standardization),
- it does **not** replace issue 3 (DI/composition ownership),
- it does **not** replace issue 2 (flow-capability routing contracts).

---

## 8) Data model ownership is split: strong in some modules, centralized in others
Subreport links:
- [Data Model Ownership Subreport](./2026-02-25-data-model-ownership-subreport.md)
- [WireAuthenticationAPI Boundary Subreport](./2026-02-24-authentication-api-boundary-subreport.md)

### Observation
Messaging/calling show bounded-context patterns, but auth/domain still expose or depend on broad shared network/domain models.

### Evidence
- Positive bounded-context examples:
  - [`WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift#L25`](WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift#L25)
  - [`WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift#L28`](WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift#L28)
- Auth API uses `WireNetwork` types in public contracts:
  - [`WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift#L20`](WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift#L20)
  - [`WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift#L20`](WireAuthentication/Sources/WireAuthenticationAPI/Use%20cases/LoginViaEmailUseCaseProtocol.swift#L20)
- Broad shared model surface exists in network:
  - [`WireNetwork/Sources/WireNetwork/Models/Conversation/Conversation.swift#L23`](WireNetwork/Sources/WireNetwork/Models/Conversation/Conversation.swift#L23)
  - [`WireNetwork/Sources/WireNetwork/Models/FeatureConfig/FeatureConfig.swift#L21`](WireNetwork/Sources/WireNetwork/Models/FeatureConfig/FeatureConfig.swift#L21)

### Potential impact if unchanged
Centralized semantic models increase coupling and reduce feature-level evolution freedom.

### Early warning signal
Feature contract changes requiring edits across app + shared modules.

### Suggested next step
Run a full auth token-model separation pilot:
- introduce auth-owned boundary token model in `WireAuthenticationAPI` (`AuthenticationAccessToken`),
- introduce separate network/transport token model in auth network/adaptation layer (`NetworkAuthenticationAccessToken` or equivalent),
- migrate auth API contracts (`LoginViaEmailUseCaseProtocol`, `CreateAuthenticationResultUseCaseProtocol`, `AuthenticationResult`) to auth-owned token model only,
- convert network token model to auth token model at a single explicit adapter boundary,
- remove `WireNetwork.AccessToken` usage from auth API/UI/feature-logic contracts.

Concrete pilot:
- complete `AccessToken` model separation first (including network model separation),
- then apply the same pattern to `BackendEnvironment2` / `ResolvedBackendMetadata` in a tracked follow-up phase.

Detailed implementation sketch and acceptance criteria are documented in:
- [Data Model Ownership Subreport](./2026-02-25-data-model-ownership-subreport.md), section `Suggested Next Step (Detailed Example - Full AccessToken Separation)`.

Scope note:
- this step addresses data-model ownership at auth API boundary,
- it does **not** redesign flow-capability routing contracts (issue 2),
- it does **not** prescribe DI framework/container migration (issue 3),
- it does **not** decompose the entire `WireNetwork` model package in one step.

---


## Immediate high-signal consistency check
`WireMessaging` package manifest/source-layout inconsistency:
- [`WireMessaging/Package.swift#L67`](WireMessaging/Package.swift#L67)
- [`WireMessaging/Sources/WireMessagingDomainSupport/Sourcery/sourcery.yml#L1`](WireMessaging/Sources/WireMessagingDomainSupport/Sourcery/sourcery.yml#L1)
- Repro: `cd WireMessaging && swift package describe` fails.

This is worth fixing before broader architecture policy checks are added.

---

## Suggested phased advise (recommended sequence)

## 1) Lock the target architecture design first
- Agree and document target design before more feature migration:
  - module taxonomy and boundaries
  - host-facing integration interface rules
  - DI composition model and lifetimes
  - routing model (capability contracts, typed outcomes)
  - data ownership/shared-kernel rules
  - dependency direction/forbidden edges
- Output: one approved architecture spec + migration matrix (current -> target).
- Main risk: design discussions without closure.
- Validation gate: maintainers explicitly approve one concrete target design and edge policy.

## 2) Converge already modularized features + app root to that design
- Adapt existing modularized features first (few enough today): primarily messaging/calling/auth, plus app-root integration seams (routing + DI).
- Remove app-boundary integration exceptions that violate the chosen design.
- Main risk: medium migration churn in host integration files.
- Validation gate: selected features integrate through agreed interface layer; app-boundary DI churn metrics trend down.

## 3) Add tooling/automation for smooth and bulletproof DX
- After design convergence starts, add module lifecycle tooling (create/edit/rename) and guardrails.
- Prioritize a Tuist/XcodeGen evaluation now; keep script/manual-first only if there are clear, documented blockers.
- Main risk: committing too early to tooling without clear workflow requirements.
- Validation gate: adding/updating a module becomes a repeatable automated path with CI enforcement.

## 4) Decouple wide-scope shared modules using the new automation
- With rules + tooling in place, progressively split/decompose broad shared modules (for example network stack, shared/common/foundation scopes).
- Main risk: regressions while extracting cross-cutting contracts.
- Validation gate: fan-in to broad shared modules decreases; feature ownership boundaries become clearer.

## 5) Validate design completeness with one new full-scope feature
- Implement one new feature across full vertical slice (contracts/domain/data/ui/assembly + routing/DI/test wiring) using the new design + automation path.
- Main risk: hidden gaps in design or automation discovered late.
- Validation gate: feature delivered without ad-hoc exceptions; postmortem documents any missing rules/tooling.

## 6) Optimize build performance once module count grows
- When modular graph is larger and stable, then invest in build acceleration (Tuist cache, Bazel, or custom strategy).
- Main risk: premature infrastructure complexity if done too early.
- Validation gate: measurable build/test improvements against baseline (local + CI) justify ongoing infra cost.

## Suggested execution mode (coding agent support)
- Use coding agents primarily as harness engineering support:
  - targeted repo research per step
  - explicit implementation plan with measurable checks
  - incremental implementation only after plan/design checkpoint
- Keep each step evidence-backed and reversible to avoid architecture drift.

---

## Validation request to Wire maintainers
- Please treat this report as a hypothesis set, not as ground truth.
- The most useful next step would be a quick lead-engineer validation pass:
  - confirm/refute each risk,
  - mark intentional design choices vs unintended drift,
  - prioritize only the items aligned with your roadmap.
- If most points are not relevant, that is still a useful outcome and helps close external assumptions early.

---

## Non-goals
- No rewrite-all architecture effort.
- No immediate monorepo-wide DI framework migration.
- No forced build-system migration before design + convergence + DX automation are in place.

---
