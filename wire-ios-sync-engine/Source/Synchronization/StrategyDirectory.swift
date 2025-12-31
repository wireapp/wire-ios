//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireDataModel
import WireDomain
import WireNetwork
import WireRequestStrategy

@objc
public protocol StrategyDirectoryProtocol {

    var eventConsumers: [ZMEventConsumer] { get }
    var eventAsyncConsumers: [ZMEventAsyncConsumer] { get }
    var requestStrategies: [RequestStrategy] { get }
    var contextChangeTrackers: [ZMContextChangeTracker] { get }
    var clientContextChangeTrackers: [ZMContextChangeTracker] { get }

}

@objcMembers
public class StrategyDirectory: NSObject, StrategyDirectoryProtocol {

    public private(set) var strategies: [Any]
    public private(set) var requestStrategies: [RequestStrategy]
    public private(set) var eventConsumers: [ZMEventConsumer]
    public private(set) var eventAsyncConsumers: [ZMEventAsyncConsumer]
    public private(set) var contextChangeTrackers: [ZMContextChangeTracker]
    public private(set) var clientContextChangeTrackers: [ZMContextChangeTracker] = []
    public private(set) var initiateResetMLSConversationUseCaseFactory: (NSManagedObjectContext) -> WireRequestStrategy
        .InitiateResetMLSConversationUseCaseProtocol

    init(
        contextProvider: ContextProvider,
        applicationStatusDirectory: ApplicationStatusDirectory,
        cookieStorage: ZMPersistentCookieStorage,
        pushMessageHandler: PushMessageHandler,
        flowManager: FlowManagerType,
        updateEventProcessor: UpdateEventProcessor,
        localNotificationDispatcher: LocalNotificationDispatcher,
        lastEventIDRepository: LastEventIDRepositoryInterface,
        transportSession: TransportSessionType,
        proteusService: ProteusServiceInterface,
        mlsService: MLSServiceInterface,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        pullSelfUserClientsFactory: @escaping PullSelfUserClientsFactory,
        searchUsersCache: SearchUsersCache?,
        initiateResetMLSConversationUseCaseFactory: @escaping (NSManagedObjectContext) -> WireRequestStrategy
            .InitiateResetMLSConversationUseCaseProtocol,
        metadata: BackendMetadataProvider
    ) {
        self.strategies = Self.buildStrategies(
            contextProvider: contextProvider,
            applicationStatusDirectory: applicationStatusDirectory,
            cookieStorage: cookieStorage,
            pushMessageHandler: pushMessageHandler,
            flowManager: flowManager,
            updateEventProcessor: updateEventProcessor,
            localNotificationDispatcher: localNotificationDispatcher,
            lastEventIDRepository: lastEventIDRepository,
            transportSession: transportSession,
            proteusService: proteusService,
            mlsService: mlsService,
            coreCryptoProvider: coreCryptoProvider,
            pullSelfUserClientsFactory: pullSelfUserClientsFactory,
            searchUsersCache: searchUsersCache,
            metadata: metadata
        )
        self.initiateResetMLSConversationUseCaseFactory = initiateResetMLSConversationUseCaseFactory

        self.requestStrategies = strategies.compactMap { $0 as? RequestStrategy }
        self.eventConsumers = strategies.compactMap { $0 as? ZMEventConsumer }
        self.eventAsyncConsumers = strategies.compactMap { $0 as? ZMEventAsyncConsumer }
        self.contextChangeTrackers = strategies.flatMap { (object: Any) -> [ZMContextChangeTracker] in
            if let source = object as? ZMContextChangeTrackerSource {
                return source.contextChangeTrackers
            } else if let tracker = object as? ZMContextChangeTracker {
                return [tracker]
            } else {
                return []
            }
        }
    }

    deinit {
        strategies.forEach { strategy in
            if let strategy = strategy as? TearDownCapable {
                strategy.tearDown()
            }
        }
    }

    static func buildStrategies(
        contextProvider: ContextProvider,
        applicationStatusDirectory: ApplicationStatusDirectory,
        cookieStorage: ZMPersistentCookieStorage,
        pushMessageHandler: PushMessageHandler,
        flowManager: FlowManagerType,
        updateEventProcessor: UpdateEventProcessor,
        localNotificationDispatcher: LocalNotificationDispatcher,
        lastEventIDRepository: LastEventIDRepositoryInterface,
        transportSession: TransportSessionType,
        proteusService: ProteusServiceInterface,
        mlsService: MLSServiceInterface,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        pullSelfUserClientsFactory: @escaping PullSelfUserClientsFactory,
        searchUsersCache: SearchUsersCache?,
        metadata: BackendMetadataProvider
    ) -> [Any] {
        let syncMOC = contextProvider.syncContext
        let featureRepository = LegacyFeatureRepository(context: syncMOC)

        let mlsFeature = featureRepository.fetchMLS()
        let oneOnOneResolver = LegacyOneOnOneResolver(
            migrator: OneOnOneMigrator(mlsService: mlsService),
            isMLSEnabled: mlsFeature.isEnabled
        )
        let mlsClientManager = MLSClientManager(
            coreCryptoProvider: coreCryptoProvider,
            mlsService: mlsService
        )

        var isCloudDomain = false
        if let localDomain = metadata.domain, BackendEnvironment2.isCloudDomain(localDomain) {
            isCloudDomain = true
        }

        return [
            UserClientRequestStrategy(
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                clientUpdateStatus: applicationStatusDirectory.clientUpdateStatus,
                context: syncMOC,
                proteusService: proteusService
            ),
            ZMMissingUpdateEventsTranscoder(
                managedObjectContext: syncMOC,
                eventProcessor: updateEventProcessor,
                applicationStatus: applicationStatusDirectory,
                pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
                syncStatus: applicationStatusDirectory.syncStatus,
                operationStatus: applicationStatusDirectory.operationStatus,
                lastEventIDRepository: lastEventIDRepository
            ),
            FetchingClientRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                apiVersion: metadata.apiVersion,
                localDomain: metadata.domain
            ),
            VerifyLegalHoldRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            ProxiedRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                requestsStatus: applicationStatusDirectory.proxiedRequestStatus
            ),
            DeleteAccountRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                cookieStorage: cookieStorage
            ),
            AssetV3UploadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain,
                isCloudDomain: isCloudDomain
            ),
            AssetV2DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            AssetV3DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            AssetV3PreviewDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            UserPropertyRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            UserProfileUpdateRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                userProfileUpdateStatus: applicationStatusDirectory.userProfileUpdateStatus
            ),
            LinkPreviewAssetUploadRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                linkPreviewPreprocessor: nil,
                previewImagePreprocessor: nil,
                localDomain: metadata.domain,
                isCloudDomain: isCloudDomain
            ),
            LinkPreviewAssetDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            ImageV2DownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            PushTokenStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            TypingStrategy(
                applicationStatus: applicationStatusDirectory,
                managedObjectContext: syncMOC,
                localDomain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            ),
            SearchUserImageStrategy(
                applicationStatus: applicationStatusDirectory,
                managedObjectContext: syncMOC,
                searchUsersCache: searchUsersCache
            ),
            ConnectionRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus,
                oneOneOneResolver: oneOnOneResolver,
                apiVersion: metadata.apiVersion,
                localDomain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            ),
            ConversationRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus,
                mlsService: mlsService,
                removeLocalConversation: RemoveLocalConversationUseCase(),
                apiVersion: metadata.apiVersion,
                localDomain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            ),
            UserProfileRequestStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus,
                oneOnOneResolver: oneOnOneResolver,
                apiVersion: metadata.apiVersion,
                localDomain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            ),
            ZMLastUpdateEventIDTranscoder(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus,
                lastEventIDRepository: lastEventIDRepository
            ),
            ZMSelfStrategy(
                managedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                syncStatus: applicationStatusDirectory.syncStatus
            ) as Any,
            SelfUserRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            LegalHoldRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus
            ),
            TeamDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus
            ),
            TeamRolesDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus
            ),
            TeamMembersDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus
            ),
            PermissionsDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            TeamInvitationRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                teamInvitationStatus: applicationStatusDirectory.teamInvitationStatus
            ),
            AssetDeletionRequestStrategy(
                context: syncMOC,
                applicationStatus: applicationStatusDirectory,
                identifierProvider: applicationStatusDirectory.assetDeletionStatus,
                localDomain: metadata.domain
            ),
            UserRichProfileRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            TeamImageAssetUpdateStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain
            ),
            LabelDownstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncStatus: applicationStatusDirectory.syncStatus
            ),
            LabelUpstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            ConversationRoleDownstreamRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            SignatureRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            FeatureConfigRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus,
                mlsClientManager: mlsClientManager,
                apiVersion: metadata.apiVersion
            ),
            FetchBackendMLSPublicKeysRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus
            ),
            TerminateFederationRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory
            ),
            ConversationStatusStrategy(
                managedObjectContext: syncMOC
            ),
            UserClientEventConsumer(
                managedObjectContext: syncMOC,
                clientRegistrationStatus: applicationStatusDirectory.clientRegistrationStatus,
                clientUpdateStatus: applicationStatusDirectory.clientUpdateStatus,
                resolveOneOnOneConversations: makeResolveOneOnOneConversationsUseCase(
                    context: syncMOC,
                    resolver: oneOnOneResolver,
                    pullSelfUserClientsFactory: pullSelfUserClientsFactory
                )
            ),
            UserImageAssetUpdateStrategy(
                managedObjectContext: syncMOC,
                applicationStatusDirectory: applicationStatusDirectory,
                userProfileImageUpdateStatus: applicationStatusDirectory.userProfileImageUpdateStatus,
                localDomain: metadata.domain,
                isCloudDomain: isCloudDomain
            ),
            localNotificationDispatcher,
            MLSRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                localDomain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            ),
            SelfSupportedProtocolsRequestStrategy(
                context: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus,
                selfUserProvider: WireDomain.SelfUserProvider(context: syncMOC)
            ),
            EvaluateOneOnOneConversationsStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: applicationStatusDirectory,
                syncProgress: applicationStatusDirectory.syncStatus
            )
        ]
    }

    func makeClientRelatedStategies(
        applicationStatusDirectory: ApplicationStatusDirectory,
        syncContext: NSManagedObjectContext,
        transportSession: TransportSessionType,
        pushMessageHandler: PushMessageHandler,
        flowManager: FlowManagerType,
        incrementalSyncObserver: IncrementalSyncObserverProtocol,
        metadata: BackendMetadataProvider
    ) {
        syncContext.performAndWait {
            let httpClient = HttpClientImpl(
                transportSession: transportSession,
                queue: syncContext
            )
            let apiProvider = APIProvider(httpClient: httpClient)
            let messageDependencyResolver = MessageDependencyResolver(context: syncContext)
            let sessionEstablisher = SessionEstablisher(
                context: syncContext,
                apiProvider: apiProvider
            )

            let messageSender = MessageSender(
                apiProvider: apiProvider,
                sessionEstablisher: sessionEstablisher,
                messageDependencyResolver: messageDependencyResolver,
                context: syncContext,
                incrementalSyncObserver: incrementalSyncObserver,
                initiateResetMLSConversationUseCase: initiateResetMLSConversationUseCaseFactory(syncContext),
                featureRepository: LegacyFeatureRepository(context: syncContext),
                apiVersion: metadata.apiVersion
            )

            let strategies: [Any] = [
                AssetClientMessageRequestStrategy(
                    managedObjectContext: syncContext,
                    messageSender: messageSender
                ),
                ClientMessageRequestStrategy(
                    context: syncContext,
                    localNotificationDispatcher: pushMessageHandler,
                    messageSender: messageSender
                ),
                DeliveryReceiptRequestStrategy(
                    managedObjectContext: syncContext,
                    messageSender: messageSender
                ),
                AvailabilityRequestStrategy(
                    context: syncContext,
                    messageSender: messageSender
                ),
                LinkPreviewUpdateRequestStrategy(
                    managedObjectContext: syncContext,
                    messageSender: messageSender
                ),
                CallingRequestStrategy(
                    managedObjectContext: syncContext,
                    applicationStatus: applicationStatusDirectory,
                    flowManager: flowManager,
                    messageSender: messageSender,
                    localDomain: metadata.domain,
                    isFederationEnabled: metadata.isFederationEnabled
                ),
                ResetSessionRequestStrategy(
                    managedObjectContext: syncContext,
                    messageSender: messageSender
                )
            ]

            self.strategies.append(contentsOf: strategies)
            self.requestStrategies.append(contentsOf: strategies.compactMap { $0 as? RequestStrategy })
            self.eventConsumers.append(contentsOf: strategies.compactMap { $0 as? ZMEventConsumer })
            self.eventAsyncConsumers.append(contentsOf: strategies.compactMap { $0 as? ZMEventAsyncConsumer })
            self.clientContextChangeTrackers = strategies.flatMap { (object: Any) -> [ZMContextChangeTracker] in
                if let source = object as? ZMContextChangeTrackerSource {
                    return source.contextChangeTrackers
                } else if let tracker = object as? ZMContextChangeTracker {
                    return [tracker]
                } else {
                    return []
                }
            }
            self.contextChangeTrackers.append(contentsOf: clientContextChangeTrackers)
        }
    }

    // MARK: Use Cases

    private static func makeResolveOneOnOneConversationsUseCase(
        context: NSManagedObjectContext,
        resolver: any OneOnOneResolverInterface,
        pullSelfUserClientsFactory: @escaping PullSelfUserClientsFactory
    ) -> any LegacyResolveOneOnOneConversationsUseCaseProtocol {

        LegacyResolveOneOnOneConversationsUseCase(
            context: context,
            supportedProtocolService: LegacySupportedProtocolsService(context: context),
            resolver: resolver,
            pullSelfUserClientsFactory: pullSelfUserClientsFactory
        )
    }
}
