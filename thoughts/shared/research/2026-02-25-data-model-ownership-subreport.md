# Research Question
Verify whether current data-modelling boundaries align with modular architecture goals, specifically:
- model ownership by bounded feature context (vs centralized shared model modules),
- local type locality and narrow cross-module contracts (IDs/DTOs vs rich shared domain objects),
- anti-corruption layers at external/API boundaries,
- avoidance of "god" model modules and feature-entity leakage across modules?

## Summary
- Current evidence at architecture level indicates: data modelling is still anchored in broad shared model modules for major flows.
- There are **two distinct patterns** in the current package design:
  - strong bounded-context modelling in `WireMessaging` and `WireCalling`,
  - shared-model coupling in `WireAuthentication` and `WireDomain`.
- `WireMessagingData` shows a clear anti-corruption layer (`Rest*` -> DTO -> `WireMessagingDomain`), and contracts are mostly ID/value-object based.
- `WireCalling` keeps models local and contracts simple (`Meeting`, `Date`, `UUID`) with no `WireNetwork`/`WireDataModel` dependency in domain/data targets.
- `WireAuthenticationAPI/Logic/UI` imports `WireNetwork` directly and exposes `WireNetwork` models in public contracts.
- `WireDomain` heavily maps between `WireNetwork` and `WireDataModel`, indicating centralized shared model authority rather than feature-owned bounded contexts.
- `WireNetwork/Models` is effectively a large shared semantic model surface (`public` model declarations: 135), spanning many business domains (conversation, user, team, feature configs, update events).
- `WireData` currently contains a feature-specific entity (`WireCellsLocalAsset`), which is a shared-module leakage of feature data.
- A narrow shared-kernel pattern exists (`WireDomainPackage` protocol-only surface), but it is not the dominant model-sharing strategy.

## Detailed Findings

### Thread 1: Current package boundary pattern and where model ownership lives
- `WireMessaging` and `WireCalling` are split into `Domain + Data + Assembly + UI` style targets; `WireAuthentication` is split into `API + Logic + UI + facade`.
- `WireAuthenticationAPI` target depends directly on `WireNetwork`; `WireAuthenticationLogic` also depends directly on `WireNetwork`.
- `WireMessagingData` depends on `WireMessagingDomain` and `WireData`, but not on `WireNetwork`/`WireDataModel`.

Evidence:
- `WireMessaging/Package.swift:12`
- `WireMessaging/Package.swift:36`
- `WireMessaging/Package.swift:55`
- `WireCalling/Package.swift:12`
- `WireCalling/Package.swift:39`
- `WireAuthentication/Package.swift:39`
- `WireAuthentication/Package.swift:51`


### Thread 2: Bounded-context ownership vs centralized shared models

#### 2a) Positive: bounded feature ownership in Messaging/Calling
- Messaging feature models are local (`WireDriveNode`, `WireDriveConversation`, `WireDrivePreCheckResult`) and repository contracts use IDs/value types.
- Calling domain model is local (`Meeting`) and repository protocol is local.

Evidence:
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNode.swift:30`
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNodesRepositoryProtocol.swift:23`
- `WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift:28`
- `WireCalling/Sources/WireCallingDomain/WireMeetings/Protocols/MeetingsRepositoryProtocol.swift:23`

#### 2b) Observed coupling pattern: centralized shared model authority remains dominant
- `WireNetwork` exposes broad business models (`Conversation`, `FeatureConfig`, `User`, update events) as shared types.
- `WireDomain` uses `WireNetwork` and `WireDataModel` extensively for cross-cutting mappings.
- `WireDomain` import scan (selected modules): `WireNetwork=207`, `WireDataModel=264` in `WireDomain/Sources/WireDomain`.

Evidence:
- `WireNetwork/Sources/WireNetwork/Models/Conversation/Conversation.swift:23`
- `WireNetwork/Sources/WireNetwork/Models/FeatureConfig/FeatureConfig.swift:21`
- `WireDomain/Sources/WireDomain/Repositories/Conversations/ConversationModelMappings.swift:19`
- `WireDomain/Sources/WireDomain/Repositories/User/UserModelMappings.swift:20`
- `WireDomain/Sources/WireDomain/Repositories/FeatureConfig/FeatureConfigModelMappings.swift:20`


### Thread 3: Cross-module contracts (small/stable vs rich/shared)

#### 3a) Messaging/Calling contracts are mostly narrow
- Messaging repository/use-case contracts rely on `UUID`, feature-local structs, and package-scoped DTOs.
- Calling contracts are minimal and context-local (`Meeting`, `Date`, pagination primitives).

Evidence:
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNodesRepositoryProtocol.swift:29`
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNodesRepositoryProtocol.swift:105`
- `WireCalling/Sources/WireCallingDomain/WireMeetings/Protocols/MeetingsRepositoryProtocol.swift:25`

#### 3b) Authentication contracts leak rich shared models
- Public authentication API contracts return/accept `WireNetwork` models directly.
- UI view models hold `BackendEnvironment2`, catch `NetworkStackError`, and branch on transport/network concerns.

Evidence:
- `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:20`
- `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:44`
- `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift:20`
- `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift:29`
- `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/FetchBackendConfigUseCaseProtocol.swift:24`
- `WireAuthentication/Sources/WireAuthenticationUI/Views/DetermineAuthMethod/DetermineAuthMethodViewModel.swift:24`
- `WireAuthentication/Sources/WireAuthenticationUI/Views/DetermineAuthMethod/DetermineAuthMethodViewModel.swift:57`
- `WireAuthentication/Sources/WireAuthenticationUI/Utilities/Alert.swift:126`

Import scan (selected modules):
- `WireAuthenticationAPI | WireNetwork=7`
- `WireAuthenticationLogic | WireNetwork=9`
- `WireAuthenticationUI | WireNetwork=34`
- `WireMessagingDomain/Data | WireNetwork=0`
- `WireCallingDomain/Data | WireNetwork=0`


### Thread 4: Anti-corruption layers at module boundaries

#### 4a) Strong anti-corruption in MessagingData
- External `CellsSDK` schemas are translated via feature DTOs and mapped into feature domain models.
- Bidirectional mapping exists at module boundary (`toDTO`, `toDomainModel`) before domain consumption.

Evidence:
- `WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift:25`
- `WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift:90`
- `WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift:152`
- `WireMessaging/Sources/WireMessagingData/WireDrive/NodesAPI/NodesAPI.swift:116`
- `WireMessaging/Sources/WireMessagingData/WireDrive/NodesAPI/NodesAPI.swift:163`

#### 4b) Network package has internal decoding boundary
- Versioned API responses decode into internal response structs then convert to stable API models via `ToAPIModelConvertible`.

Evidence:
- `WireNetwork/Sources/WireNetwork/APIs/Rest/UsersAPI/UsersAPIV12.swift:66`
- `WireNetwork/Sources/WireNetwork/APIs/Rest/UsersAPI/UsersAPIV12.swift:84`
- `WireNetwork/Sources/WireNetwork/APIs/Rest/UsersAPI/UsersAPIV12.swift:118`
- `WireNetwork/Sources/WireNetwork/Components/ToAPIModelConvertible.swift:21`

#### 4c) Authentication has limited anti-corruption
- It maps some error semantics and wraps some call outputs, but still carries `WireNetwork` model types across module boundaries rather than defining local auth contracts.

Evidence:
- `WireAuthentication/Sources/WireAuthenticationLogic/LoginViaEmailUseCase.swift:35`
- `WireAuthentication/Sources/WireAuthenticationLogic/LoginViaEmailUseCase.swift:45`
- `WireAuthentication/Sources/WireAuthenticationLogic/CreateAuthenticationResultUseCase.swift:25`
- `WireAuthentication/Sources/WireAuthenticationLogic/CreateAuthenticationResultUseCase.swift:42`


### Thread 5: God modules and feature-entity leakage
- `WireNetwork/Models` is a broad shared semantic hub (type scan: `public` declarations = 135) and is imported across multiple feature stacks.
- `WireData` currently includes a feature-specific Cells entity (`WireCellsLocalAsset`), then `WireMessagingData` aliases and persists against it.
- This is direct feature-entity sharing through a shared module, not a narrowly scoped shared kernel.

Evidence:
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:22`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:22`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:25`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:61`


### Thread 6: Shared kernel usage (good pattern, limited scope)
- `WireDomainPackage` exposes a small protocol-focused contract surface (`IndividualToTeamMigrationUseCaseProtocol`, backup errors) and is used by UI-facing modules.
- This pattern matches explicit shared-kernel intent, but coverage is narrow compared to widespread `WireNetwork`/`WireDataModel` sharing.

Evidence:
- `WireDomain/Sources/WireDomainPackage/UseCases/Protocols/IndividualToTeamMigrationUseCaseProtocol.swift:34`
- `WireDomain/Sources/WireDomainPackage/UseCases/Protocols/ImportLegacyBackupError.swift:19`
- `WireUI/Sources/WireSettingsUI/Account/BackupImportExport/BackupImportExportBuilder.swift:21`


### Thread 7: Known vs unknown
Known:
- Messaging/Calling modules demonstrate bounded-context data modelling and DTO boundary translation.
- Authentication and Domain modules still expose and consume centralized shared model types directly.
- Shared modules currently contain feature-specific entities (`WireData` -> `WireCellsLocalAsset`).

Unknown:
- Whether `BackendEnvironment2`/`AccessToken` are intentionally defined as organization-wide shared kernel concepts (design intent not documented in code comments/docs here).
- Whether `WireData` is intended to remain a feature-agnostic persistence kernel or act as a host for selected feature persistence entities.
- Whether import-count hot spots in `WireDomain` are accepted architecture or target for reduction.

## Code References
- `WireMessaging/Package.swift:12`
- `WireMessaging/Package.swift:36`
- `WireMessaging/Package.swift:67`
- `WireCalling/Package.swift:12`
- `WireAuthentication/Package.swift:39`
- `WireAuthentication/Package.swift:51`
- `WireData/Sources/WireData/Models/WireCellsLocalAsset.swift:22`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:25`
- `WireMessaging/Sources/WireMessagingData/WireDrive/WireDriveLocalAssetStore.swift:61`
- `WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift:90`
- `WireMessaging/Sources/WireMessagingData/WireDrive/Model/WireDriveNodeNetworkModel.swift:152`
- `WireMessaging/Sources/WireMessagingData/WireDrive/NodesAPI/NodesAPI.swift:116`
- `WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveNodesRepositoryProtocol.swift:29`
- `WireMessaging/Sources/WireMessagingDomain/Conversation/UserModel.swift:24`
- `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:44`
- `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift:29`
- `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/FetchBackendConfigUseCaseProtocol.swift:24`
- `WireAuthentication/Sources/WireAuthenticationUI/Views/DetermineAuthMethod/DetermineAuthMethodViewModel.swift:57`
- `WireAuthentication/Sources/WireAuthenticationUI/Utilities/Alert.swift:126`
- `WireAuthentication/Sources/WireAuthenticationLogic/CreateAuthenticationResultUseCase.swift:42`
- `WireNetwork/Sources/WireNetwork/Models/Conversation/Conversation.swift:23`
- `WireNetwork/Sources/WireNetwork/Models/FeatureConfig/FeatureConfig.swift:21`
- `WireNetwork/Sources/WireNetwork/APIs/Rest/UsersAPI/UsersAPIV12.swift:66`
- `WireDomain/Sources/WireDomain/Repositories/Conversations/ConversationModelMappings.swift:19`
- `WireDomain/Sources/WireDomain/Repositories/User/UserModelMappings.swift:20`
- `WireDomain/Sources/WireDomain/Repositories/FeatureConfig/FeatureConfigModelMappings.swift:20`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:20`
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/LoadConversationMessagesRepository.swift:173`

## Architecture / Design Insights
- The current module architecture contains a **good feature-local data pattern** (Messaging/Calling) and a **shared-model coupling pattern** (Authentication/Domain). These two patterns are currently co-existing at package boundary level.
- The key issue for your pain point is not package count, but **where semantic ownership lives**. Right now, semantic ownership for many core entities still lives in broad shared modules (`WireNetwork`, `WireDataModel`) rather than bounded feature contexts.
- Anti-corruption discipline is strong where feature data layers own external translation (`WireMessagingData`), and weak where module APIs expose external/shared model types directly (`WireAuthenticationAPI`).
- A narrow shared kernel exists (`WireDomainPackage`) and is a positive precedent; however, it is not yet the dominant shape of cross-module model sharing.

## Suggested Next Step (Detailed Example - Full AccessToken Separation)
### Fully separate auth token model from network token model
- Why this pilot:
  - `AccessToken` currently leaks from `WireNetwork` into `WireAuthenticationAPI`, logic, and UI-level auth flows.
  - This couples auth boundary evolution to shared network-model changes.
  - Evidence:
    - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/LoginViaEmailUseCaseProtocol.swift:29`
    - `WireAuthentication/Sources/WireAuthenticationAPI/Use cases/CreateAuthenticationResultUseCaseProtocol.swift:28`
    - `WireAuthentication/Sources/WireAuthenticationAPI/Models/AuthenticationResult.swift:36`
    - `WireAuthentication/Sources/WireAuthenticationLogic/LoginViaEmailUseCase.swift:35`

### Target separation rule
- `WireAuthenticationAPI` exposes only auth-owned token model.
- Network/transport token model is separate and remains in network/adaptation layer.
- Final state: `WireNetwork.AccessToken` is not referenced in auth API contracts, auth UI, or auth feature logic contracts.

### Proposed model split
- `WireAuthenticationAPI.AuthenticationAccessToken` (public boundary model).
- `WireAuthenticationLogic` (or auth network adapter) owns a separate transport token model, for example `NetworkAuthenticationAccessToken`.
- Explicit mapper at the network->auth boundary converts transport model to auth boundary model.

### Example refactor sketch
Auth boundary model:

```swift
// WireAuthenticationAPI
public struct AuthenticationAccessToken: Equatable, Hashable, Sendable {
    public let userID: UUID
    public let token: String
    public let type: String
    public let expirationDate: Date
}
```

Network-side token model (separate type):

```swift
// WireAuthenticationLogic (or auth network adapter target)
struct NetworkAuthenticationAccessToken: Sendable {
    let userID: UUID
    let token: String
    let type: String
    let expirationDate: Date
}
```

Boundary mapping:

```swift
// WireAuthenticationLogic
import WireAuthenticationAPI

extension AuthenticationAccessToken {
    init(networkToken: NetworkAuthenticationAccessToken) {
        self.init(
            userID: networkToken.userID,
            token: networkToken.token,
            type: networkToken.type,
            expirationDate: networkToken.expirationDate
        )
    }
}
```

### Incremental migration plan
1. Introduce `AuthenticationAccessToken` (API) and `NetworkAuthenticationAccessToken` (network/adaptation side).
2. Migrate all auth API signatures to `AuthenticationAccessToken`:
   - `LoginViaEmailUseCaseProtocol`
   - `CreateAuthenticationResultUseCaseProtocol`
   - `AuthenticationResult.accessToken`
3. Update auth UI/logic/mocks to consume `AuthenticationAccessToken` only.
4. Refactor login/network adapters so `WireNetwork.AccessToken` is converted immediately at network boundary.
5. Remove residual `WireNetwork.AccessToken` usage from `WireAuthentication` module and keep separate network token model as the only transport type in adapters.

### Scope note (important)
- This pilot enforces full token-model separation (auth boundary model + separate network model).
- It does **not** redesign auth routing contracts (issue 5).
- It does **not** prescribe DI/container changes (issue 2).
- It does **not** perform full decomposition of all `WireNetwork` models in one step.

### Validation criteria for this pilot
- `WireAuthenticationAPI` contains no `WireNetwork.AccessToken` references.
- `WireAuthenticationUI` and auth feature logic contracts use `AuthenticationAccessToken`, not `WireNetwork.AccessToken`.
- Network adapters keep a separate transport token model and explicit mapping.
- Email login/relogin/verification-code flows remain behaviorally unchanged.

## Related Notes
- `thoughts/shared/research/2026-02-24-messaging-calling-locality-subreport.md`
- `thoughts/shared/research/2026-02-24-public-interface-subreport.md`
- `thoughts/shared/research/2026-02-24-authentication-api-boundary-subreport.md`
- `thoughts/shared/research/2026-02-24-di-container-subreport.md`
- `thoughts/shared/research/2026-02-25-routing-flow-capabilities-subreport.md`

## Open Questions / Follow-ups
- Should `WireAuthenticationAPI` define auth-owned boundary models (e.g., `AuthSession`, `BackendDescriptor`) and confine `WireNetwork` types to logic/data internals?
- Should `WireData` stop carrying feature-specific entities like `WireCellsLocalAsset`, moving those to feature data modules or explicit feature persistence kernels?
- Should `WireNetwork` public model exposure be split into narrower context packages to prevent cross-feature semantic coupling?
- Which concepts are explicitly intended as shared kernel (for example `QualifiedID`, `BackendEnvironment2`), and which should be feature-local?
- Should `WireMessagingDomain.UserModel.objectID: any Sendable` be replaced with a stable, persistence-agnostic identifier contract?
