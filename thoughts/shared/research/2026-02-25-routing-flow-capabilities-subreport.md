# Research Question
Verify whether routing in extracted feature packages (excluding legacy `AuthenticationCoordinator` internals) follows a flow-capability design:
- abstract flow capabilities (protocols + factories returning opaque coordinators/handles),
- call-sites only start flows and handle typed outcomes,
- no direct cross-feature UI imports / no requester-side branching for i.e. auth/navigation intent?

## Summary
- Within extracted feature packages, the routing boundary is still **assembly/screen-oriented**, not **flow-capability-oriented**.
- `WireAuthentication` exposes `WireAuthenticationAssembly.assemble(...) -> (view, bridge)`, not a public opaque flow starter/coordinator interface.
- `WireAuthenticationAPI` exposes many use-case protocols and typed models, but no public `AuthenticationFlow*` capability contract.
- Internal auth routing abstractions (`Router`, `RootFactory`, etc.) are `package` scoped, so they are not reusable cross-module capability APIs.
- `WireMessaging` and `WireCalling` public boundaries also expose screen factories (`UIViewController` / `some View`) rather than flow handles with typed completion/outcomes.
- Cross-feature triggering of login from other extracted packages is not supported by boundary design: `WireMessaging`/`WireCalling` have no dependency on `WireAuthentication`.
- Typed outcome signaling exists in auth (`WireAuthenticationBridge.OutboundEvent.userAuthenticated(...)`), but this is an event bridge primitive, not a generalized flow capability contract.
- For strict package-only scope, routing capability criteria are not yet met.

## Detailed Findings

### Thread 1: New package dependency graph for routing/auth intent
- `WireAuthentication` defines `WireAuthentication`, `WireAuthenticationAPI`, `WireAuthenticationLogic`, `WireAuthenticationUI` products.
- `WireMessaging` and `WireCalling` do not depend on `WireAuthentication`; they depend on shared core/UI modules.

Assessment:
- Other feature packages cannot request auth via a shared auth-flow capability because there is no dependency path or shared routing contract.

### Thread 2: Public auth boundary shape in current package boundaries
- Public entrypoint is `WireAuthenticationAssembly.assemble(...)` returning `(view, bridge)`.
- This boundary is UI assembly + event bridge, not a dedicated opaque flow capability.

Assessment:
- Callers get a rendered interface + bridge channel, not a `startLoginFlow(...)` style capability abstraction.

### Thread 3: Capability contract availability in `WireAuthenticationAPI`
- `WireAuthenticationAPI` publishes use-case protocols/factories (`LoginViaEmailUseCaseFactory`, `LoginViaSSOUseCaseFactory`, etc.) and models.
- Search over public API declarations finds no public flow/coordinator capability protocol.

Assessment:
- API is domain/use-case oriented, not flow-routing capability oriented.

### Thread 4: Internalized routing abstractions are not public boundaries
- Auth UI uses `Router`/factory abstractions internally, but these are `package` visibility.
- `DetermineAuthMethodViewModel` contains branching logic internally (good locality), but that abstraction does not become a cross-module capability.

Assessment:
- Branching is mostly localized inside auth module implementation, but the integration contract still lacks an external flow capability surface.

### Thread 5: New Messaging/Calling routing surfaces
- `WireMessagingAssembly` and `WireMessagingFactory` expose screen/use-case factories.
- `WireCallingAssembly` exposes `WireMeetingsFactory.makeMeetingsView() -> UIViewController`.

Assessment:
- Boundary pattern is “factory returns UI”, not “start flow and observe typed flow result.”

### Thread 6: Typed outcomes vs capability completeness
- `WireAuthenticationBridge` has typed outbound events (`userAuthenticated`, `exitFlowRequested`, `logoutRequested`) and limited inbound events.
- Inbound events are lifecycle/config nudges (`didRewindToThisView`, `backendSwitchRequested`, `updateAnotherAccountExistence`), not a generic external auth intent API.

Assessment:
- Typed outcomes exist, but the contract is not sufficient as a reusable flow capability for arbitrary feature callers.

### Thread 7: Cross-feature import check (extracted packages)
- `WireMessaging` / `WireCalling` / `WireUI` / `WireData` / `WireDomain` source scans show no imports of `WireAuthentication*`.
- The only non-auth-package source import of `WireAuthenticationUI` in new package roots is debug tooling (`WireDebug`).

Assessment:
- Direct cross-feature auth UI coupling is mostly avoided, but the required positive capability (feature-agnostic login trigger) is also absent.

### Thread 8: Integration boundary stability signal
- `WirePreviewApps/WireAuthenticationApp` calls `assemble(...)` with parameters (`environmentType`, `accountsURL`) not present in current `WireAuthenticationAssembly` source.

Assessment:
- Even in new-module-adjacent usage, the integration surface appears churn-prone; this weakens “stable capability boundary” characteristics.

## Code References
- Package boundaries
  - `WireAuthentication/Package.swift:12`
  - `WireAuthentication/Package.swift:13`
  - `WireAuthentication/Package.swift:14`
  - `WireAuthentication/Package.swift:15`
  - `WireMessaging/Package.swift:12`
  - `WireMessaging/Package.swift:13`
  - `WireMessaging/Package.swift:14`
  - `WireMessaging/Package.swift:16`
  - `WireCalling/Package.swift:12`
  - `WireCalling/Package.swift:13`
  - `WireCalling/Package.swift:14`
  - `WireCalling/Package.swift:16`

- Auth public integration surface
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:40`
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:54`

- Auth bridge and typed events
  - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:26`
  - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:52`
  - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:54`
  - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:63`

- Auth internal (non-public) routing abstractions
  - `WireAuthentication/Sources/WireAuthenticationUI/Views/Root/Router.swift:25`
  - `WireAuthentication/Sources/WireAuthenticationUI/Views/Root/RootView.swift:24`
  - `WireAuthentication/Sources/WireAuthenticationUI/Views/DetermineAuthMethod/DetermineAuthMethodViewModel.swift:143`

- Public API surface shape (use-case contracts)
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift:23`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaSSOUseCaseProtocol.swift:22`
  - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/DetermineAuthMethodUseCaseProtocol.swift:21`

- Messaging/Calling boundary shape
  - `WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:27`
  - `WireMessaging/Sources/WireMessagingAssembly/ConversationsAssembly.swift:30`
  - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:142`
  - `WireMessaging/Sources/WireMessagingAssembly/WireMessagingFactory.swift:166`
  - `WireCalling/Sources/WireCallingAssembly/WireMeetingsFactory.swift:40`

- Cross-feature usage signal
  - `WireDebug/Sources/WireViewsDebugUI/WireAuthenticationUIDebugView.swift:22`

- Integration churn signal
  - `WirePreviewApps/WireAuthenticationApp/ContentView.swift:33`
  - `WirePreviewApps/WireAuthenticationApp/ContentView.swift:36`
  - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:40`

## Architecture / Design Insights
- Current package boundaries emphasize **feature extraction + assembly factories**, not **feature capability contracts for routing**.
- Auth has typed event outputs, but still lacks a public, intent-level “start auth flow” capability boundary that other modules can depend on without UI assembly knowledge.
- Messaging/Calling follow the same screen-factory model; this keeps host-level navigation ownership and does not solve reusable flow invocation as an architectural concept.

## Suggested Next Step (Detailed Example)
### Flow-capability pilot on `WireAuthentication` via `WireAuthenticationInterface`
- Why this pilot:
  - issue 5 is primarily an auth-routing capability gap (cross-feature "login required" trigger).
  - current auth boundary already has typed events (`WireAuthenticationBridge.OutboundEvent`), which can be adapted to a feature-agnostic capability contract.
  - this allows introducing capability-style routing without rewriting all auth internals at once.
  - Evidence:
    - `WireAuthentication/Sources/WireAuthentication/WireAuthenticationAssembly.swift:40`
    - `WireAuthentication/Sources/WireAuthenticationAPI/WireAuthenticationBridge.swift:54`
    - `WireAuthentication/Sources/WireAuthenticationUI/Views/Root/Router.swift:25`

### Routing rules for this pilot
- Feature callers depend on `WireAuthenticationInterface` only.
- Callers start a flow capability and observe typed outcomes.
- Caller code does not import auth UI/assembly modules.
- Branching for auth-method selection remains inside auth implementation.
- DI wiring is intentionally not prescribed in this routing example (tracked in DI issue).

### Proposed contract shape
- `AuthenticationFlowCapability`: starts auth flow for a typed request/context.
- `AuthenticationFlowSession`: exposes typed outcomes + optional inbound control channel.
- `AuthenticationFlowOutcome`: feature-agnostic outcomes (`authenticated`, `cancelled`, `logoutRequested`).
- `AuthenticationFlowRequest`: typed reason/context from caller (`requiresAuthenticationForFeatureX`, etc.).

### Example capability sketch
`WireAuthenticationInterface` contract:

```swift
import UIKit

public struct AuthenticationFlowRequest: Sendable {
    public enum Reason: Sendable {
        case featureAccess(String)
        case appLaunch
    }

    public let reason: Reason

    public init(reason: Reason) {
        self.reason = reason
    }
}

public enum AuthenticationFlowOutcome: Sendable {
    case authenticated(userID: UUID)
    case cancelled
    case logoutRequested
}

public enum AuthenticationFlowInput: Sendable {
    case backendSwitchRequested
    case accountExistenceChanged(Bool)
}

public protocol AuthenticationFlowSession: Sendable {
    var outcomes: AsyncStream<AuthenticationFlowOutcome> { get }
    func send(_ input: AuthenticationFlowInput)
}

public protocol AuthenticationFlowCapability {
    @MainActor
    func start(
        request: AuthenticationFlowRequest,
        presenter: UIViewController
    ) -> any AuthenticationFlowSession
}
```

`WireAuthenticationAssembly` adapter (implementation detail):

```swift
import WireAuthenticationInterface
import WireAuthentication

public final class WireAuthenticationFlowCapability: AuthenticationFlowCapability {
    @MainActor
    public func start(
        request: AuthenticationFlowRequest,
        presenter: UIViewController
    ) -> any AuthenticationFlowSession {
        // Internally use existing assembly + bridge and map bridge events
        // to AuthenticationFlowOutcome stream.
        let assembly = WireAuthenticationAssembly(...)
        let (view, bridge) = assembly.assemble()

        presenter.present(view, animated: true)

        return AuthenticationFlowSessionAdapter(bridge: bridge)
    }
}
```

Feature caller usage (no auth assembly/UI import):

```swift
import WireAuthenticationInterface

final class MessagingAuthGate {
    private let authFlow: AuthenticationFlowCapability

    init(authFlow: AuthenticationFlowCapability) {
        self.authFlow = authFlow
    }

    @MainActor
    func ensureLoggedIn(presenter: UIViewController) {
        let session = authFlow.start(
            request: .init(reason: .featureAccess("WireMessaging")),
            presenter: presenter
        )

        Task {
            for await outcome in session.outcomes {
                switch outcome {
                case .authenticated:
                    // continue feature flow
                    return
                case .cancelled, .logoutRequested:
                    // abort feature flow
                    return
                }
            }
        }
    }
}
```

### Incremental migration plan
1. Add `WireAuthenticationInterface` product/target with routing capability contracts.
2. Implement adapter in auth implementation module that maps current bridge events into new typed outcomes.
3. Expose `AuthenticationFlowCapability` from the existing app composition path (without prescribing DI style in this track).
4. Migrate one caller path (for example a messaging gate) to new capability API.
5. Add guardrail checks to block direct `WireAuthenticationAssembly` imports in feature caller modules.
6. Gradually migrate remaining callers; keep legacy assembly seam only during transition.

### Scope note (important)
- This pilot addresses routing capability boundary quality.
- DI container standardization is intentionally out of scope here (tracked in DI issue).
- It does **not** require immediate rewrite of internal auth router/view flow; adapter layer can be incremental.

### Validation criteria for this pilot
- At least one non-auth feature triggers login through `AuthenticationFlowCapability` without importing auth assembly/UI.
- Caller handles typed `AuthenticationFlowOutcome` only (no auth-internal event enums in caller code).
- Auth internal routing changes do not require caller signature changes.
- Existing auth behavior remains unchanged for migrated flow.

## Related Notes
- `thoughts/shared/research/2026-02-24-authentication-api-boundary-subreport.md`
- `thoughts/shared/research/2026-02-24-di-container-subreport.md`
- `thoughts/shared/research/2026-02-24-public-interface-subreport.md`
- `thoughts/shared/research/2026-02-25-tooling-dx-subreport.md`

## Open Questions / Follow-ups
- Should `WireAuthenticationInterface` define a public `AuthenticationFlowCapability` with one start method and typed completion/result channel?
- Should `WireAuthenticationAssembly` be reduced to an implementation detail behind `WireAuthenticationInterface` capability contracts?
- Should routing-critical entrypoints in `WireMessagingAssembly` / `WireCallingAssembly` evolve from raw screen builders into capability starters with typed outcomes?
