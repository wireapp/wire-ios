# Research Question
Verify whether current boundary design for `WireMessaging` / `WireCalling` preserves locality:

- non-breaking feature edits should stay local to feature modules;
- modules depending on `WireMessaging` / `WireCalling` should not require widespread edits;
- dependencies of those features should not contain feature business logic.

## Summary
- The package pattern is consistent in newer features (`Domain` + `Data` + `UI` + `Assembly`) but not locality-safe by itself.
- `WireMessaging` has broad integration surface: app code imports `WireMessagingDomain`/`UI`/`Assembly` directly in many files and links all products.
- Messaging contracts are app-owned in multiple places (`ConversationCreationRepositoryProtocol`, `ChannelRepositoryProtocol`, message loading protocols), so protocol evolution propagates into app modules.
- `WireMessagingUI` directly imports `WireMessagingData` and constructs data/domain use cases; this is an internal layering leak.
- `WireMessagingAssembly` re-exports multiple modules (`public import`) and depends on `WireData`, widening the effective public boundary.
- Shared dependencies contain feature-specific concerns: `WireData` includes `WireCellsLocalAsset` + `zmessaging` schema entities; `WireUI` hard-codes meetings/files tabs and routes.
- `WireCalling` has a much narrower app boundary (assembly-focused imports) and a smaller public contract surface than Messaging.
- At app composition, feature products are linked as multiple entry points (`Domain` + `UI` + `Assembly`) instead of a single facade, which weakens locality guarantees.
- Overall assessment: feature packaging is strong, but boundary contracts are still too broad for strict "local change stays local" behavior, especially for Messaging.

## Detailed Findings

### Thread 1: Declared package boundary pattern
- `WireMessaging` exports `WireMessagingDomain`, `WireMessagingAssembly`, `WireMessagingUI`; `WireMessagingData` remains internal target (`WireMessaging/Package.swift:12`, `WireMessaging/Package.swift:13`, `WireMessaging/Package.swift:14`, `WireMessaging/Package.swift:36`).
- `WireCalling` exports `WireCallingDomain`, `WireCallingAssembly`, `WireCallingUI` with internal `WireCallingData` (`WireCalling/Package.swift:12`, `WireCalling/Package.swift:13`, `WireCalling/Package.swift:14`, `WireCalling/Package.swift:39`).
- Both packages enable stricter Swift visibility defaults (`WireMessaging/Package.swift:99`, `WireCalling/Package.swift:86`).

Assessment:
- Pattern is directionally correct, but exported product set is still broad (especially Messaging) and app wiring does not enforce facade-only consumption.

### Thread 2: Inbound boundary breadth (who depends on feature modules)
- App target links all messaging products (`WireMessagingUI`, `WireMessagingAssembly`, `WireMessagingDomain`) and both calling products (`WireCallingUI`, `WireCallingAssembly`) (`wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1383`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1392`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1393`).
- In app sources, imports are heavy for messaging and tiny for calling:
  - messaging imports: `WireMessagingDomain` 43 files, `WireMessagingUI` 13 files, `WireMessagingAssembly` 12 files (repo scan).
  - calling imports: `WireCallingAssembly` 3 files; no app imports of `WireCallingDomain`/`WireCallingUI`.
- Example messaging-heavy integration points:
  - `ConversationViewController` imports all three messaging products (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:28`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:29`).
  - `StartUIViewController` imports all three messaging products (`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:25`, `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:26`, `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/StartUIViewController.swift:27`).

Assessment:
- Messaging public boundary is wide in practice; calling boundary is narrower at app entry points.

### Thread 3: Contract ownership and propagation risk
- Messaging domain exposes many public protocols (35 public protocols in scan), including repositories intended for implementation by consumers (`WireMessaging/Sources/WireMessagingDomain/ConversationCreation/ConversationCreationRepositoryProtocol.swift:20`, `WireMessaging/Sources/WireMessagingDomain/ChannelRepositoryProtocol.swift:20`, `WireMessaging/Sources/WireMessagingDomain/Conversation/LoadConversationMessagesUseCase.swift:21`, `WireMessaging/Sources/WireMessagingDomain/Conversation/MonitorMessagesUseCase.swift:29`).
- App implements these contracts directly:
  - `ConversationCreationRepository` in app (`wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/ConversationCreationRepository.swift:22`).
  - `ChannelRepository` in app (`wire-ios/Wire-iOS/Sources/ChannelRepository.swift:25`).
  - `LoadConversationMessagesRepository` in app (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:23`).
- `ConversationCreationRepositoryProtocol` is referenced across many app files (27-file scan), indicating high propagation potential for signature changes.

Assessment:
- For Messaging, many seams are "public protocol contracts owned by app", which breaks locality when contracts evolve.

### Thread 4: Internal feature layering leaks
- `WireMessagingUI` imports `WireMessagingData` directly (`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`).
- Those UI containers construct many use cases directly (not only rendering concerns), e.g. in `makeViewModel()` composition blocks (`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:73`).
- `WireMessagingAssembly` performs broad `public import` re-export and exposes `WireData`/`WireFoundation`/`WireMessagingDomain`/`WireMessagingUI` to consumers (`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:23`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:24`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:26`).

Assessment:
- Messaging layering is porous: UI composes data internals and assembly broadens import surface, increasing coupling surface area.

### Thread 5: Feature logic inside shared dependencies
- `WireData` (shared/generic named package) contains feature-specific entities:
  - `WireCellsLocalAsset` model (`WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:26`).
  - `zmessaging` model contains `Conversation`, `Message`, and `WireCellsLocalAsset` entities (`WireData/Sources/WireData/Schema/zmessaging.xcdatamodeld/zmessaging2.133.0.xcdatamodel/contents:49`, `WireData/Sources/WireData/Schema/zmessaging.xcdatamodeld/zmessaging2.133.0.xcdatamodel/contents:180`, `WireData/Sources/WireData/Schema/zmessaging.xcdatamodeld/zmessaging2.133.0.xcdatamodel/contents:419`).
- `WireUI` (shared UI package) contains meetings/files-specific navigation contracts and behavior:
  - shared protocol includes `meetingsUI` + `filesUI` (`WireUI/Sources/WireMainNavigationUI/Protocols/Containers/MainContainerViewController.swift:35`, `WireUI/Sources/WireMainNavigationUI/Protocols/Containers/MainContainerViewController.swift:37`).
  - coordinator API exposes `showMeetings` + `showFiles` (`WireUI/Sources/WireMainNavigationUI/Protocols/Coordinator/MainCoordinatorProtocol.swift:39`, `WireUI/Sources/WireMainNavigationUI/Protocols/Coordinator/MainCoordinatorProtocol.swift:41`).
  - tab and sidebar include show flags and dedicated items (`WireUI/Sources/WireMainNavigationUI/Containers/MainTabBarController.swift:98`, `WireUI/Sources/WireMainNavigationUI/Containers/MainTabBarController.swift:99`, `WireUI/Sources/WireSidebarUI/Views/SidebarView.swift:148`, `WireUI/Sources/WireSidebarUI/Views/SidebarView.swift:154`).

Assessment:
- This shows an architectural pressure point: feature behavior is embedded in multi-purpose dependency modules, so some Messaging/Calling edits require dependency edits.

### Thread 6: Calling boundary scope vs locality
- `WireCalling` app boundary is comparatively tight (assembly-focused): app imports `WireCallingAssembly` and does not directly import `WireCallingDomain`/`WireCallingUI` in production sources (scan).
- `WireCallingDomain` keeps most contracts package-scoped (three `package protocol`s, no `public protocol`), so external contract churn is minimized.
- `WireMeetingsFactory` currently composes with `MeetingsRepository.demo()` (placeholder/demo-style wiring) (`WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:45`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:49`).

Assessment:
- Calling currently has stronger boundary discipline than Messaging; main open design point is production-grade repository composition behind the same assembly seam.

### Thread 7: App composition model vs facade boundary
- App target links multiple products from the same feature package, including `WireMessagingUI`, `WireMessagingAssembly`, and `WireMessagingDomain` (`wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1383`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`).
- This enables direct imports of all three products in app files (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:28`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:29`).
- Messaging integration adapters are implemented in app composition (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:147`).

Assessment:
- A multi-entry composition model (instead of one facade entry) makes boundary bypass easy and increases cross-module change propagation.

## Code References
- `WireMessaging/Package.swift:12`
- `WireMessaging/Package.swift:36`
- `WireCalling/Package.swift:12`
- `WireCalling/Package.swift:39`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1383`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/WireMessagingFactoryProtocol.swift:23`
- `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/ConversationCreationRepository.swift:22`
- `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:25`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:23`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:83`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:22`
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:26`
- `WireData/Sources/WireData/Schema/zmessaging.xcdatamodeld/zmessaging2.133.0.xcdatamodel/contents:419`
- `WireUI/Sources/WireMainNavigationUI/Protocols/Containers/MainContainerViewController.swift:35`
- `WireUI/Sources/WireMainNavigationUI/Protocols/Coordinator/MainCoordinatorProtocol.swift:39`
- `WireUI/Sources/WireMainNavigationUI/Containers/MainTabBarController.swift:98`
- `WireUI/Sources/WireSidebarUI/Views/SidebarView.swift:148`
- `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`

## Architecture / Design Insights
- The current package extraction emphasizes moving code into packages, but not a strict facade boundary. Consumers still touch domain/UI internals directly (especially Messaging).
- Package-level visibility (`package`) is used, but some layering decisions counteract it (UI -> Data imports, assembly re-exporting broad dependencies).
- Shared "platform" modules (`WireUI`, `WireData`) carry feature-specific decisions, creating bidirectional change pressure.
- Messaging and Calling currently apply the same package template with different boundary strictness outcomes:
  - Messaging: broad externally-consumed contracts and multi-entry imports.
  - Calling: tighter assembly-first boundary and narrower external contract surface.

## Suggested Next Step (Detailed Example)
### Remove `WireMessagingUI -> WireMessagingData` leakage for WireDrive files
- Why this pilot:
  - This is the most concrete internal-layer leakage currently observable in Messaging.
  - It is bounded to a specific UI area (`FilesViewContainer` / `RecycleBinContainer`) and can be migrated incrementally.
  - Evidence:
    - `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`
    - `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`
    - `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`
    - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:142`

### Layering rules for this pilot
- `WireMessagingUI` must not import `WireMessagingData`.
- `WireMessagingUI` should consume precomposed contracts/factories only.
- Use-case graph construction should live in `WireMessagingAssembly` (or assembly-internal composer), not in UI containers.
- Data-layer repositories/APIs remain assembly/data concerns.

### Proposed contract shape
- Introduce a UI-facing factory protocol in `WireMessagingUI`:
  - `WireDriveFilesViewModelFactoryProtocol`
  - returns fully composed `FilesViewModel` for files/recycle-bin contexts.
- `FilesViewContainer` and `RecycleBinContainer` depend on this protocol only.
- `WireMessagingAssembly` implements the protocol using current `WireDrive*UseCase` composition.

### Example refactor sketch
UI module contract + container usage:

```swift
// WireMessagingUI
import Combine
import SwiftUI
package import WireFoundation
package import WireMessagingDomain

package protocol WireDriveFilesViewModelFactoryProtocol {
    @MainActor
    func makeFilesViewModel(
        path: [FilesViewItem],
        setNavigation: @escaping ([FilesViewItem]) -> Void,
        triggerReload: PassthroughSubject<Void, Never>
    ) -> FilesViewModel

    @MainActor
    func makeRecycleBinViewModel(
        path: [FilesViewItem],
        setNavigation: @escaping ([FilesViewItem]) -> Void
    ) -> FilesViewModel
}

package struct FilesViewContainer: View {
    @State private var path: [FilesViewItem] = []
    private let viewModelFactory: any WireDriveFilesViewModelFactoryProtocol

    package init(viewModelFactory: any WireDriveFilesViewModelFactoryProtocol) {
        self.viewModelFactory = viewModelFactory
    }

    private func makeViewModel() -> FilesViewModel {
        viewModelFactory.makeFilesViewModel(
            path: path,
            setNavigation: { path = $0 },
            triggerReload: triggerReloadFiles
        )
    }
}
```

Assembly module composition (current use-case graph moved here):

```swift
// WireMessagingAssembly
import WireMessagingUI
import WireMessagingData
import WireMessagingDomain

final class WireDriveFilesViewModelFactory: WireDriveFilesViewModelFactoryProtocol {
    private let nodesAPI: NodesAPI
    private let nodesRepository: any WireDriveNodesRepositoryProtocol
    private let localAssetStore: any WireDriveLocalAssetStoreProtocol
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let nodeCache: any WireDriveNodeCacheProtocol
    private let nodeRenameNotifier: WireDriveNodeRenameNotifier
    private let fileCache: any FileCache
    private let cellName: String
    private let isCellsStatePending: Bool
    private let accentColorProvider: () -> WireAccentColor

    @MainActor
    func makeFilesViewModel(
        path: [FilesViewItem],
        setNavigation: @escaping ([FilesViewItem]) -> Void,
        triggerReload: PassthroughSubject<Void, Never>
    ) -> FilesViewModel {
        FilesViewModel(
            useCases: .init(
                fetchNodes: WireDriveFetchNodesPageUseCase(
                    configuration: .conversationFileView(
                        root: path.last.map { .id($0.id) } ?? .path(cellName)
                    ),
                    repository: nodesRepository
                ),
                deleteNodes: WireDriveDeleteNodesUseCase(
                    repository: nodesRepository,
                    fileCache: fileCache,
                    localAssetStore: localAssetStore
                )
                // ...remaining use-cases unchanged, moved from UI container...
            ),
            navigationPath: path,
            setNavigation: setNavigation,
            isCellsStatePending: isCellsStatePending,
            localAssetRepository: localAssetRepository,
            nodesRepository: nodesRepository,
            fileCache: fileCache,
            cellName: cellName,
            isBrowsing: false,
            isRecycleBin: false,
            triggerReload: triggerReload,
            accentColorProvider: accentColorProvider
        )
    }
}
```

Factory wiring stays in assembly boundary:

```swift
// WireMessagingFactory.makeFilesView(...)
let vmFactory = WireDriveFilesViewModelFactory(
    nodesAPI: nodesAPI,
    nodesRepository: nodesAPI,
    localAssetStore: localAssetStore,
    localAssetRepository: localAssetRepository,
    nodeCache: nodeCache,
    nodeRenameNotifier: nodeRenameNotifier,
    fileCache: fileCache,
    cellName: cellName,
    isCellsStatePending: isCellsStatePending,
    accentColorProvider: accentColorProvider
)

return UIHostingController(
    rootView: FilesViewContainer(viewModelFactory: vmFactory)
)
```

### Incremental migration plan
1. Add `WireDriveFilesViewModelFactoryProtocol` in `WireMessagingUI`.
2. Update `FilesViewContainer` and `RecycleBinContainer` to use the protocol and remove `WireMessagingData` imports.
3. Implement assembly-side `WireDriveFilesViewModelFactory` by moving existing use-case composition code from UI.
4. Keep runtime behavior identical; move code first, optimize second.
5. Add guardrail checks to block `WireMessagingData` imports in `WireMessagingUI`.

### Scope note (important)
- This pilot addresses internal layer leakage (`UI -> Data`) and composition ownership.
- It does **not** by itself solve app-facing interface consistency.
- It does **not** by itself solve routing-capability contracts.
- It does **not** prescribe DI-container strategy.

### Validation criteria for this pilot
- `WireMessagingUI/WireDrive/Components/Files/*` has no `WireMessagingData` imports.
- `FilesViewContainer` / `RecycleBinContainer` no longer construct `WireDrive*UseCase` graphs directly.
- Use-case composition for those screens exists in `WireMessagingAssembly` (or assembly-internal composer) only.
- No behavior regressions in files and recycle-bin flows.

## Related Notes
- `thoughts/shared/research/2026-02-25-shared-modules-subreport.md`
- `thoughts/shared/research/2026-02-24-di-container-subreport.md`
- `thoughts/shared/research/2026-02-24-authentication-api-boundary-subreport.md`

## Open Questions / Follow-ups
- Is the intended integration rule "assembly-only imports for app code" for Messaging/Calling? If yes, current Messaging imports violate it heavily.
- Should `WireMessaging` expose a single facade product and keep `Domain`/`UI`/`Data` internal where possible?
- Should meetings/files navigation concerns stay in `WireUI`, or move behind feature-level route contracts so shared UI is feature-agnostic?
- Should feature-specific entities currently in `WireData` (e.g., `WireCellsLocalAsset`) move into feature-scoped data modules?
- Should `WireCalling` keep the meetings-focused module scope, or expand the same boundary model to additional calling capabilities?
