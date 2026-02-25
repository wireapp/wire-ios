# Research Question
Verify whether the current package boundary design addresses the shared/common-module pain point:
- avoid broad `Shared/Common/Foundation` dumping-ground modules,
- keep shared modules narrow and explicitly owned,
- keep shared contracts stable/context-agnostic,
- keep feature-specific models/logic local,
- avoid centralized model/utility modules that create transitive coupling or leak domain types across feature boundaries.

## Summary
- Current evidence indicates shared-module boundaries still rely on broad modules with mixed responsibilities.
- `WireFoundation` is a high fan-in module (9 local package dependents) and mixes primitives with feature-specific contracts (backup, analytics), so it is not a narrow shared kernel.
- `WireData` is generic by name but currently hosts a feature-specific entity (`WireCellsLocalAsset`), which centralizes feature persistence in a shared package.
- `WireUI` acts as an umbrella package containing many feature-level products (settings, folder flows, migration, navigation) in one shared module boundary.
- New assembly surfaces re-export dependencies (`public import`) and expose shared module types, which increases transitive coupling for consumers.
- `WireMessagingFactory` publicly exposes `WireData`/`WireFoundation` and requires shared contracts (`ManagedObjectContextProvider`) at the integration seam.
- App-side integration needs explicit adapters/retroactive conformances to satisfy package contracts, indicating leakage of internals across boundaries.
- Positive signal: newest feature modules still keep important core models local (`WireDriveNode`, `Meeting`) and do not centralize all feature data in shared modules.

## Detailed Findings

### Thread 1: Shared-module topology in the current package graph
- High fan-in shared packages:
  - `WireFoundation`: 9 local package dependents.
  - `WireLogging`: 8 local package dependents.
  - `WirePlugins`: 10 local package dependents.
- `WireMessaging` and `WireCalling` depend on `WireFoundation` and `WireUI` products, so shared modules remain central in new package composition.

Evidence:
- `WireMessaging/Package.swift:20`
- `WireMessaging/Package.swift:23`
- `WireCalling/Package.swift:17`
- `WireCalling/Package.swift:20`
- `WireFoundation/Package.swift:12`
- `WireFoundation/Package.swift:14`
- `WireFoundation/Package.swift:15`

### Thread 2: `WireFoundation` is broad, not narrow shared kernel
- `WireFoundation` exports multiple distinct concerns from one package: crypto, foundation helpers, testing package, utilities package.
- Source includes context-agnostic primitives (`QualifiedID`) but also feature-oriented contracts:
  - backup use cases/progress/error types,
  - analytics event/analytics tracker contracts,
  - UI-adjacent accent color primitive used across UI/features.
- This mixed semantic ownership in a central module increases coupling risk when adding new cross-cutting types.

Evidence:
- `WireFoundation/Package.swift:11`
- `WireFoundation/Package.swift:12`
- `WireFoundation/Package.swift:14`
- `WireFoundation/Package.swift:15`
- `WireFoundation/Sources/WireFoundation/WirePrimitives/QualifiedID.swift:23`
- `WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/CreateBackupUseCaseProtocol.swift:21`
- `WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/ImportBackupUseCaseProtocol.swift:20`
- `WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEventTrackerProtocol.swift:21`
- `WireFoundation/Sources/WireFoundation/WirePrimitives/AnalyticsEvent.swift:19`
- `WireFoundation/Sources/WireFoundation/WirePrimitives/WireAccentColor.swift:21`

### Thread 3: `WireData` centralizes feature-specific persistence
- `WireData` currently exposes one generic Core Data provider contract and one feature-specific entity:
  - `ManagedObjectContextProvider`
  - `WireCellsLocalAsset`
- `WireMessagingData` aliases and persists directly against `WireData.WireCellsLocalAsset`, so Wire Drive feature persistence is not fully local to the feature package.
- The feature assembly also re-exports `WireData`, which broadens dependency visibility to consumers.

Evidence:
- `WireData/Package.swift:6`
- `WireData/Sources/WireData/ManagedObjectContextProvider.swift:23`
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:22`
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:26`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:22`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:25`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:61`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`

### Thread 4: `WireUI` is an umbrella shared package containing multiple feature contracts
- `WireUI` product list spans multiple feature contexts (account image, folder picker, move-to-folder flow, settings, migration, main navigation, sidebar, multibackend, design/reusable).
- Some UI targets depend on domain/foundation/logging, reinforcing a central shared package that carries both base UI and feature-specific UI contracts.
- `WireMoveToFolderUI` defines domain-like models/protocols (`Conversation`, `Folder`, folder use cases) and app code maps/adapts local data-model types to those shared UI contracts.

Evidence:
- `WireUI/Package.swift:12`
- `WireUI/Package.swift:16`
- `WireUI/Package.swift:18`
- `WireUI/Package.swift:22`
- `WireUI/Package.swift:70`
- `WireUI/Package.swift:113`
- `WireUI/Sources/WireMoveToFolderUI/Models/Conversation.swift:21`
- `WireUI/Sources/WireMoveToFolderUI/Models/Folder.swift:22`
- `WireUI/Sources/WireMoveToFolderUI/Protocols/UpdateConversationFolderUseCaseProtocol.swift:22`
- `wire-ios/Wire-iOS/Sources/UserInterface/Folders/Mappers/Conversation+ZMConversation.swift:22`
- `wire-ios/Wire-iOS/Sources/UserInterface/Folders/Mappers/WireFolderDirectoryMapper.swift:22`

### Thread 5: Assembly surfaces create transitive coupling
- `WireMessagingFactory` re-exports `WireData`, `WireFoundation`, `WireMessagingDomain`, `WireMessagingUI` through `public import`, then takes shared dependencies (`ManagedObjectContextProvider`, `FileCache`, `AccessTokenProvider`) in its public initializer.
- App integration imports multiple module layers and adds adapters/retroactive conformances to satisfy package protocols.
- This means feature consumption is not fully shielded by a narrow facade boundary; shared module contracts leak into the host.

Evidence:
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:23`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:26`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:46`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:51`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:21`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:25`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:105`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/DefaultManagedObjectContextProvider.swift:22`

### Thread 6: Positive counterexamples (where locality is good)
- New feature modules still keep key feature domain models local:
  - Messaging: `WireDriveNode`
  - Calling: `Meeting`
- This is aligned with bounded-context ownership, but shared-module leakage still appears at integration/shared boundaries.

Evidence:
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift:30`
- `WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift:28`

### Thread 7: Known vs unknown
Known:
- Shared modules are not purely narrow primitives; several contain feature contracts/models.
- At least one generic shared package (`WireData`) currently carries a feature-specific model.
- Assembly-level public imports expose transitive dependencies.

Unknown:
- No explicit ownership metadata (for example `CODEOWNERS`) was found for module boundaries in this workspace snapshot.
- It is not documented in-code which shared contracts are intentionally “shared kernel” vs temporary convenience boundaries.

## Code References
- `WireFoundation/Package.swift:12`
- `WireFoundation/Package.swift:14`
- `WireFoundation/Sources/WireFoundation/WirePrimitives/QualifiedID.swift:23`
- `WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/CreateBackupUseCaseProtocol.swift:21`
- `WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEventTrackerProtocol.swift:21`
- `WireData/Package.swift:6`
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:26`
- `WireMessaging/Package.swift:24`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:22`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:46`
- `WireUI/Package.swift:11`
- `WireUI/Package.swift:70`
- `WireUI/Sources/WireMoveToFolderUI/Models/Conversation.swift:21`
- `wire-ios/Wire-iOS/Sources/UserInterface/Folders/Mappers/Conversation+ZMConversation.swift:22`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:105`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/DefaultManagedObjectContextProvider.swift:22`
- `WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift:28`

## Architecture / Design Insights
- The current architecture shows strong feature slicing, but shared-module design is still mixed-purpose at key seams.
- The core issue is semantic ownership: several “shared” packages contain both true shared primitives and feature-specific contracts/models.
- Assembly re-exports amplify this by making consumer boundaries transitively aware of underlying shared modules.
- The most scalable direction from current state is to keep only stable context-agnostic primitives in shared kernels and move feature-specific contracts/models to feature-owned packages with narrow facades.

## Suggested Next Step (Detailed Example - Decouple Wide-Scope Shared Modules)
### Use automation to progressively decompose broad shared modules
- Why this pilot:
  - `WireFoundation` and `WireUI` are still broad aggregation points with mixed concerns and high fan-in.
  - Broad modules are still carrying feature-level workflows/contracts (`WireMoveToFolderUI`) and app adapters.
  - Evidence:
    - `WireFoundation/Package.swift:8`
    - `WireFoundation/Sources/WireFoundation/Protocols/BackupRestore/CreateBackupUseCaseProtocol.swift:21`
    - `WireFoundation/Sources/WireFoundation/Protocols/Analytics/AnalyticsEventTrackerProtocol.swift:21`
    - `WireUI/Package.swift:11`
    - `WireUI/Package.swift:18`
    - `WireUI/Sources/WireMoveToFolderUI/Models/Conversation.swift:21`
    - `wire-ios/Wire-iOS/Sources/UserInterface/Folders/CreateConversationFolderUseCase+CreateConversationFolderUseCaseProtocol.swift:23`

### Recommended direction (aligned with roadmap phase 4)
- With rules + tooling already in place, progressively split/decompose wide-scope shared modules.
- Start with bounded extractions that are easy to validate and review.
- Keep runtime behavior unchanged during each extraction wave.

### Automation-driven extraction loop
1. Select one extraction candidate from broad modules using fan-in/churn signals (for example `WireMoveToFolderUI` in `WireUI`).
2. Use module tooling automation to scaffold target package/targets and wire dependencies/tests.
3. Move feature-scoped files/contracts and related tests from shared module to feature-owned module.
4. Auto-update workspace/package references and import paths via automation.
5. Land with compatibility shims only when needed; remove them in follow-up cleanup PRs.

### Concrete first wave
- Wave 1A: extract `WireMoveToFolderUI` (+ support/tests) from `WireUI` into a feature-owned module.
- Wave 1B: identify the next narrow extraction from `WireFoundation` (for example analytics or backup-related contract scope) and move it into dedicated module scope using the same automation path.

### Main risk
- Regressions while extracting cross-cutting contracts from broad shared modules.

### Scope note (important)
- This step focuses on broad-module decomposition and ownership convergence.
- It does **not** redesign flow-capability routing contracts (issue 5).
- It does **not** prescribe DI framework/container migration (issue 2).
- It does **not** attempt a single-shot rewrite of all shared modules.

### Validation gate
- Fan-in to broad shared modules decreases across extraction waves.
- Feature ownership boundaries become clearer (feature workflows no longer hosted in shared umbrellas).
- Each extraction wave passes build/tests with no behavior regressions.

## Related Notes
- `thoughts/shared/research/2026-02-25-data-model-ownership-subreport.md`
- `thoughts/shared/research/2026-02-24-public-interface-subreport.md`
- `thoughts/shared/research/2026-02-24-messaging-calling-locality-subreport.md`
- `thoughts/shared/research/2026-02-25-routing-flow-capabilities-subreport.md`

## Open Questions / Follow-ups
- Which contracts in `WireFoundation` are intended as long-lived shared kernel (for example `QualifiedID`) versus feature-specific contracts that should be relocated?
- What extraction order for `WireUI` feature-scoped targets gives best risk/impact (for example `WireMoveToFolderUI`, then `WireSettingsUI`, then migration flows)?
- Should `WireMessagingAssembly` stop public re-export of underlying modules and expose a narrower integration facade as part of shared-boundary hardening?
- Should `WireFoundation` be split into smaller shared-kernel packages (for example primitives vs analytics/backup contracts), or kept single-package with strict scope guardrails?
