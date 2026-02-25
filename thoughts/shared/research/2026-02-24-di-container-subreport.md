# Research Question
Verify whether the current module architecture addresses dependency-injection pain points, with primary focus on:

- Is DI handled via a coherent container strategy, or mostly manual constructor wiring?
- Do modules self-register exposed dependencies into an app-shared container?
- Does the current boundary setup reduce cross-module boilerplate/churn, or shift it into app composition?

## Summary
- Current evidence for the app target shows manual composition (builders/factories/constructors), not a central app container.
- There is no module self-registration into an app-shared container in current app composition.
- Needle is used, but only in bounded areas: `WireAuthentication` package and `WireDomain` notification-extension flow, not as monorepo-wide DI architecture.
- New feature packages (`WireMessaging`, `WireCalling`) expose assembly/domain/ui modules but still require app-side construction/adaptation at integration seams.
- `WireMessaging` has the largest boundary and DI leakage: app imports `Domain`/`Assembly`/`UI`, implements domain repositories, and adds retroactive conformances.
- `WireMessagingUI` imports `WireMessagingData` directly in production containers, so internal layering is porous.
- `WireCallingAssembly` currently builds meetings from `MeetingsRepository.demo()`, signaling immature production composition at module boundary.
- The app target links a broad set of feature products, increasing composition complexity and non-local change risk.
- Best-fit direction for this codebase is to standardize on one composition model: either extend Needle to app root + feature registrars, or adopt a single lightweight registrar/container layer; current mixed model is the core issue.

## Detailed Findings

### Thread 1: Current module boundary shape
- `WireMessaging` and `WireCalling` use `Domain + Data + Assembly + UI` style target split (`WireMessaging/Package.swift:12`, `WireMessaging/Package.swift:36`, `WireMessaging/Package.swift:47`, `WireMessaging/Package.swift:55`, `WireCalling/Package.swift:12`, `WireCalling/Package.swift:39`, `WireCalling/Package.swift:46`, `WireCalling/Package.swift:54`).
- `WireAuthentication` uses `API + Logic + UI + facade` and is the only feature package with explicit public `*API` product (`WireAuthentication/Package.swift:12`, `WireAuthentication/Package.swift:13`, `WireAuthentication/Package.swift:50`, `WireAuthentication/Package.swift:63`).
- Shared-core fan-in is high across package manifests (path dependencies count): `WirePlugins` 10, `WireLogging` 8, `WireFoundation` 6.
- Toolchain/settings are inconsistent across packages (`swift-tools-version` spans 5.10, 6.0, 6.1, 6.2), which affects the uniformity of language-level boundary enforcement.

Assessment:
- Modularization exists structurally, but DI and boundary strategy is inconsistent across features.

### Thread 2: App-level DI reality (composition root in `Wire-iOS`)
- App bootstrap is manual chain:
  - `AppDelegate.createAppRootRouter()` builds `AppRootRouter` with concrete dependencies (`wire-ios/Wire-iOS/Sources/AppDelegate.swift:397`, `wire-ios/Wire-iOS/Sources/AppDelegate.swift:411`).
  - `AppRootRouter` builds `AuthenticatedRouter` with concrete feature wiring (`wire-ios/Wire-iOS/Sources/AppRootRouter.swift:464`, `wire-ios/Wire-iOS/Sources/AppRootRouter.swift:474`).
  - `AuthenticatedRouter` constructs `ZClientControllerBuilder` directly (`wire-ios/Wire-iOS/Sources/AuthenticatedRouter.swift:83`).
  - `ZClientControllerBuilder` constructs feature factories and passes them into `ZClientViewController` (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:63`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:83`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:115`).
- `ZClientViewController` then owns many lazy builders/factories and passes dependencies further (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:107`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:119`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:147`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:217`).
- Quantitative signal of wiring spread in app sources:
  - `wireMessagingFactory:` appears 30 times.
  - `mainCoordinator:` appears 166 times in `UserInterface/*`.
- Global access patterns are still present (`SessionManager.shared`, `UIApplication.shared.delegate as? AppDelegate`), reducing DI purity (`wire-ios/Wire-iOS/Sources/Helpers/syncengine/SessionManager+Convenience.swift:26`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:520`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:306`).

Assessment:
- There is a composition root, but it is a manual object graph, not container-managed DI.

### Thread 3: Feature-level DI patterns (where containers do and do not exist)
- `WireAuthentication` uses Needle internally:
  - assembly bootstrap calls `registerProviderFactories()` (`WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:35`, `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:36`);
  - root component is `BootstrapComponent` (`WireAuthentication/Sources/WireAuthentication/Components/RootComponent.swift:30`);
  - generated provider registry exists (`WireAuthentication/Sources/WireAuthentication/Needle.generated.swift:451`, `WireAuthentication/Sources/WireAuthentication/Needle.generated.swift:477`).
- `WireDomain` also uses Needle, but for notification service extension flow (NSE), not app-wide feature DI:
  - extension bootstrap (`WireDomain/Sources/WireDomain/Notifications/NotificationServiceExtension.swift:64`);
  - flow component (`WireDomain/Sources/WireDomain/Notifications/Components/NSEFlow.swift:29`);
  - generated registration (`WireDomain/Sources/WireDomain/Needle.generated.swift:166`).
- `WireMessaging` / `WireCalling` do not use a DI container:
  - `WireMessagingFactory` directly constructs internal collaborators and use cases (`WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:53`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:59`, `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:170`);
  - `WireMeetingsFactory` builds view model directly and currently uses `MeetingsRepository.demo()` (`WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:40`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`, `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:45`).

Assessment:
- DI architecture is fragmented: container-based in selected modules, manual composition elsewhere.

### Thread 4: Module self-registration into shared container
- No evidence of app-shared DI container or module registrar pattern was found in app or feature packages (no `Swinject`/`Resolver`/`Factory`/custom app container registration usage in source scans).
- The only registration pattern found is Needle generated provider registration within specific Needle scopes (`WireAuthentication/.../Needle.generated.swift:451`, `WireDomain/.../Needle.generated.swift:153`).
- Integration remains app-owned and explicit:
  - auth assembly call site passes many concrete values (`wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:300`, `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:316`);
  - messaging/calling factories are built in app builder (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:83`, `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:115`).

Assessment:
- The requested pattern ("module self-registers exposed deps in shared container") is not implemented.

### Thread 5: Boundary quality and DI boilerplate propagation
- App target links many package products simultaneously (`wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1383`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1392`, `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1393`).
- Messaging boundary is broad in app:
  - import counts in app sources: `WireMessagingDomain` 43, `WireMessagingAssembly` 12, `WireMessagingUI` 13.
  - app consumes all three products in key screens (`wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController.swift:27`).
- App implements messaging-domain contracts directly (`wire-ios/Wire-iOS/Sources/ChannelRepository.swift:25`, `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/ConversationCreationRepository.swift:22`, `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:23`).
- App adds retroactive conformances for messaging interfaces in composition layer (`wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`).
- `WireMessagingUI` imports `WireMessagingData` directly in production containers and composes use cases there (`WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`, `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:73`).

Assessment:
- DI boilerplate is not just constructor verbosity; it is a boundary ownership issue where app and feature layers both own composition seams.

### Thread 6: DI best-practice check for large modular iOS apps
- Criteria: single composition root + module registrars + clear feature facades + no global singleton access + environment/test overrides.
- Current state:
  - `single composition root`: partial (exists, but manual and leaky).
  - `module self-registration`: not yet met.
  - `feature facade-only app imports`: not yet met for messaging.
  - `consistent DI model across features`: not yet met (Needle in some modules only).
  - `global singleton avoidance`: partially met.
  - `test-friendly dependency override path`: partial (many protocols/mocks exist, but high integration churn).

Assessment:
- Current evidence indicates the current DI pattern does not yet solve critical DI pain points in a scalable way.

## Container Options (Fit For This Repo)
The repository already contains Needle and generated component graphs in production modules, so the lowest-risk path is:

1. **Primary recommendation: standardize on Needle for app root + feature registrars**
- Why this fits this monorepo:
  - already in use (`WireAuthentication` and NSE flow),
  - compile-time safety and hierarchical components align with existing feature/component style,
- avoids introducing a second DI paradigm into an already broad feature graph.
- Concrete target state:
  - `AppComponent` (root) owns app-lifetime services;
  - each feature package exposes `FeatureComponent` + minimal facade protocol;
  - app integrates features by requesting facades from components, not constructing feature internals.

2. **Alternative: Factory (FactoryKit) for incremental container registration**
- Good when you want faster adoption with minimal codegen and explicit scoped containers.
- Tradeoff in this repo: introducing a new DI system while Needle is already present may increase short-term architecture drift unless Needle is intentionally retired.

3. **Alternative: Swinject**
- Most flexible runtime container, but runtime resolution and registration-heavy style are generally less attractive for this codebase than compile-time approaches already present.

4. **Complementary (not replacement): swift-dependencies**
- Strong for controllable dependency values in feature logic/tests/SwiftUI previews.
- Best used as a feature-level override mechanism, not as sole object-graph container for this app architecture.

## Code References
- `WireMessaging/Package.swift:12`
- `WireMessaging/Package.swift:36`
- `WireMessaging/Package.swift:47`
- `WireMessaging/Package.swift:55`
- `WireCalling/Package.swift:12`
- `WireCalling/Package.swift:39`
- `WireCalling/Package.swift:46`
- `WireCalling/Package.swift:54`
- `WireAuthentication/Package.swift:13`
- `wire-ios/Wire-iOS/Sources/AppDelegate.swift:397`
- `wire-ios/Wire-iOS/Sources/AppDelegate.swift:411`
- `wire-ios/Wire-iOS/Sources/AppRootRouter.swift:464`
- `wire-ios/Wire-iOS/Sources/AppRootRouter.swift:474`
- `wire-ios/Wire-iOS/Sources/AuthenticatedRouter.swift:83`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:63`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:83`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:105`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:115`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:146`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:107`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:147`
- `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:217`
- `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:300`
- `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift:316`
- `wire-ios/Wire-iOS/Sources/Helpers/syncengine/SessionManager+Convenience.swift:26`
- `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:36`
- `WireAuthentication/Sources/WireAuthentication/Components/RootComponent.swift:30`
- `WireAuthentication/Sources/WireAuthentication/Needle.generated.swift:451`
- `WireAuthentication/Sources/WireAuthentication/Needle.generated.swift:477`
- `WireDomain/Sources/WireDomain/Notifications/NotificationServiceExtension.swift:64`
- `WireDomain/Sources/WireDomain/Needle.generated.swift:153`
- `WireDomain/Sources/WireDomain/Needle.generated.swift:166`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:53`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:142`
- `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:170`
- `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:40`
- `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:42`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:23`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/FilesViewContainer.swift:113`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:22`
- `WireMessaging/Sources/WireMessagingUI/WireDrive/Components/Files/RecycleBinContainer.swift:73`
- `wire-ios/Wire-iOS/Sources/ChannelRepository.swift:25`
- `wire-ios/Wire-iOS/Sources/UserInterface/StartUI/StartUI/ConversationCreationRepository.swift:22`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:23`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1383`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1390`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1391`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1392`
- `wire-ios/Wire-iOS.xcodeproj/project.pbxproj:1393`

## Architecture / Design Insights
- The core problem is not "no DI at all"; it is "multiple DI styles with different boundary ownership models." This multiplies boilerplate and integration churn.
- Manual constructor injection in app code is acceptable in small scope, but current breadth of feature boundaries makes it the scaling bottleneck.
- Messaging and calling packages expose useful feature boundaries, but those boundaries still expose too much internal composition, forcing app-level adaptation.
- A single DI strategy must be chosen for app integration surfaces. Given current code, extending Needle is lower-risk than introducing another container paradigm now.

## Suggested Next Step (Detailed Example)
### Global DI composition pilot on `WireCalling` + `WireCallingInterface`
- Why this pilot:
  - `WireCalling` is the smallest extracted feature package among messaging/calling/authentication.
  - Host integration is already relatively narrow and can be migrated with lower risk than messaging.
  - Existing app call sites are centralized enough for an incremental DI migration.
  - Evidence:
    - `WireCalling/Package.swift:12`
    - `WireCalling/Package.swift:13`
    - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientControllerBuilder.swift:115`
    - `wire-ios/Wire-iOS/Sources/UserInterface/MainController/ZClientViewController.swift:205`

### DI rules for this pilot
- App consumers depend on `WireCallingInterface` only.
- `WireCallingAssembly` import is allowed only in global app composition root.
- Implementation modules self-register feature services into shared container.
- Feature dependencies are resolved in shared DI, not exposed through interface contracts and not rebuilt in per-screen builders.
- Composition should happen at feature-level scope (not per-use-case wiring in app files).

### Proposed DI shape (incremental target)
- `AppDependencyContainer` (shared container with app/session/transient scopes).
- `FeatureModuleRegistrar` protocol implemented by feature implementation modules.
- `WireCallingRegistrar` in `WireCallingAssembly` registers `WireCallingFeatureInterface`.
- App composition root only wires registrars once; feature consumers resolve typed interfaces from container.

### Incremental migration plan
1. Introduce shared app container abstraction with typed `register`/`resolve`.
2. Add `FeatureModuleRegistrar` protocol and implement `WireCallingRegistrar` in `WireCallingAssembly`.
3. Move `WireMeetingsFactory(...)` construction into `WireCallingRegistrar.register(in:)`.
4. In app bootstrap, invoke all registrars once and create session scope.
5. Migrate app call sites to resolve/inject `WireCallingFeatureInterface` (`resolve` or `@Dependency`).
6. Add guardrail checks to block new direct feature-factory construction in app UI builder files.

### Example composition sketch
Container contract + module self-registration:

```swift
import WireCallingInterface
import WireReusableUIComponents

public enum DependencyScope {
    case app
    case session
    case transient
}

public protocol AppDependencyContainer: AnyObject {
    func register<Service>(
        _ type: Service.Type,
        scope: DependencyScope,
        factory: @escaping (AppDependencyContainer) -> Service
    )
    func resolve<Service>(_ type: Service.Type) -> Service
}

public protocol FeatureModuleRegistrar {
    static func register(in container: AppDependencyContainer)
}

public enum WireCallingRegistrar: FeatureModuleRegistrar {
    public static func register(in container: AppDependencyContainer) {
        container.register(
            WireCallingFeatureInterface.self,
            scope: .session
        ) { resolver in
            WireMeetingsFactory(
                passwordValidator: resolver.resolve((any PasswordValidator).self)
            )
        }
    }
}
```

```swift
// Global app bootstrap (single registration place)
import WireCallingInterface
import WireCallingAssembly

@MainActor
func makeContainer() -> AppDependencyContainer {
    let container = SharedDependencyContainer()

    CoreRegistrar.register(in: container)
    AuthenticationRegistrar.register(in: container)
    WireCallingRegistrar.register(in: container)
    WireMessagingRegistrar.register(in: container)

    return container
}
```

```swift
// Resolve side
let callingFeature = container.resolve(WireCallingFeatureInterface.self)
```

```swift
// Property-wrapper side
import WireCallingInterface

@propertyWrapper
struct Dependency<Service> {
    var wrappedValue: Service { AppDI.shared.resolve(Service.self) }
}

final class ZClientViewController {
    @Dependency var wireCallingFeature: WireCallingFeatureInterface

    @MainActor
    func showMeetings() {
        let meetingsUI = wireCallingFeature.makeMeetingsView(
            options: .init(isContextMenuAllowed: SecurityFlags.clipboard.isEnabled)
        )
        present(meetingsUI, animated: true)
    }
}
```

```swift
// Runtime option remains consumer-controlled through interface
let meetingsUI = wireCallingFeature.makeMeetingsView(
    options: .init(isContextMenuAllowed: SecurityFlags.clipboard.isEnabled)
)
```

### Scope note (important)
- This pilot primarily reduces app-boundary DI boilerplate and ownership spread.
- It does **not** by itself solve routing capability design (`start flow + typed result`).
- It does **not** fully solve internal feature layering leaks (for example UI/data coupling inside feature internals).

### Validation criteria for this pilot
- `WireCallingAssembly` provides a registrar (`WireCallingRegistrar`) that self-registers `WireCallingFeatureInterface`.
- App bootstrap registers feature modules once; app consumers do not construct feature factories directly.
- App consumer files import `WireCallingInterface` without `WireCallingAssembly`.
- App call sites can use `container.resolve(WireCallingFeatureInterface.self)` or `@Dependency var wireCallingFeature: WireCallingFeatureInterface`.
- Calling feature wiring changes are contained to composition root files more often than app UI builder files.
- Integration remains behaviorally equivalent for meetings entrypoint.

## Related Notes
- `thoughts/shared/research/2026-02-25-tooling-dx-subreport.md`
- `thoughts/shared/research/2026-02-24-public-interface-subreport.md`
- `thoughts/shared/research/2026-02-24-messaging-calling-locality-subreport.md`
- `thoughts/shared/research/2026-02-24-authentication-api-boundary-subreport.md`
- `thoughts/shared/research/2026-02-25-shared-modules-subreport.md`

## Open Questions / Follow-ups
- Do you want to standardize on Needle monorepo-wide (recommended), or intentionally replace Needle with another container strategy?
- For messaging/calling, should app integration be restricted to one facade product per feature (instead of importing `Domain`/`Assembly`/`UI`)?
- Should feature packages expose explicit module registrars (for a root app container) and stop app-side manual construction of feature internals?
- Should app-level policy explicitly enforce: feature implementation modules can be imported only in global composition root files?
- Should feature providers be session-scoped by default (rather than rebuilt in UI builders) for app-boundary DI consistency?
- Can `WireMessagingUI` stop importing `WireMessagingData` directly and move composition into assembly/component layer?
- Is `WireMeetingsFactory` intentionally demo-wired right now, or should it be converted to production repository wiring as part of DI unification?
