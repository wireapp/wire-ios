//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import NeedleFoundation
import WireDataModel
//import GenericMessageProtocol
import WireLogging
import WireNetwork
//import CallKit

protocol NSEClientScopeDependency: Dependency {

    var account: Account { get }
    var accountID: UUID { get }
    var appContainerURL: URL { get }
    var userAccountDataURL: URL { get }
    var accountManager: AccountManager { get }
    var journal: Journal { get }
    var sharedUserDefaults: UserDefaults { get }
    var cookieStorage: CookieStorage { get }

}

/// The scope of a user client within the NSE flow.
///
/// Within this scope the necessary use cases to process
/// the notification request are builds and invoked.

final class NSEClientScope: Component<NSEClientScopeDependency> {

    enum Failure: Error {

        case pushChannelAlreadyOpened

    }

    private let clientID: String
    private let restNetworkService: NetworkService
    private let webSocketNetworkService: NetworkService
    private let apiVersion: WireNetwork.APIVersion
    private let localDomain: String
    private let isFederationEnabled: Bool
    private let coreDataStack: CoreDataStack
    private let earService: EARServiceInterface

    private let pushChannelCoordinator: AppExtensionPushChannelCoordinator
    private var currentTask: Task<Void, any Error>?
    private var monitoringTask: Task<Void, any Error>?
    //private var callKitReportTask: Task<Void, Never>?

//    private lazy var callingService: any AVSCallingEventServiceProtocol = {
//        let service = AVSCallingEventService(
//            userID: dependency.accountID.transportString(),
//            clientID: clientID
//        )
//
//        // Track whether we reported an incoming call to CallKit,
//        // so onCallClosed knows whether it needs to stop ringing.
//        var didReportIncomingCall = false
//
//        service.onIncomingCall = { [weak self] conversationId, shouldRing, isVideoCall in
//            WireLogger.calling.info(
//                "gagaga onIncomingCall, conversationId: \(conversationId)",
//                attributes: .newNSE, .safePublic
//            )
//
//            guard let self,
//                  let qualifiedID = QualifiedID(rawValue: conversationId) else {
//                return
//            }
//            let callKitContent: [String: Any] = [
//                "accountID": self.dependency.accountID.uuidString,
//                "conversationID": qualifiedID.uuid.uuidString,
//                "shouldRing": shouldRing,
//                "hasVideo": isVideoCall,
//                "callerName": ""
//            ]
//            WireLogger.calling.info(
//                "gagaga onIncomingCall, callKitContent \(callKitContent)",
//                attributes: .newNSE, .safePublic
//            )
//            didReportIncomingCall = shouldRing
//
//            self.callKitReportTask = Task {
//                await withCheckedContinuation { continuation in
//                    CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
//                        if let error {
//                            WireLogger.calling.error("gagaga reportNewIncomingVoIPPushPayload error: \(error)", attributes: .newNSE, .safePublic)
//                        } else {
//                            WireLogger.calling.info("gagaga reportNewIncomingVoIPPushPayload done", attributes: .newNSE, .safePublic)
//                        }
//                    }
//                }
//            }
//        }
//
//        service.onMissedCall = { conversationId, messageTime, isVideoCall in
//            WireLogger.calling.info(
//                "gagaga onMissedCall",
//                attributes: .newNSE, .safePublic
//            )
//            // Nothing to do here — the missed call text notification
//            // is already built by ConversationCallingEventNotificationBuilder
//            // from the same event in the event stream.
//            WireLogger.calling.info(
//                "AVS: missed call in conversation \(conversationId)",
//                attributes: .newNSE, .safePublic
//            )
//        }
//
//        service.onCallClosed = { [weak self] reason, conversationId in
//            WireLogger.calling.info(
//                "gagaga onCallClosed",
//                attributes: .newNSE, .safePublic
//            )
//            guard let self, didReportIncomingCall else { return }
//            // Stop ringing — only if we previously started it
//            let callKitContent: [String: Any] = [
//                "accountID": self.dependency.accountID.uuidString,
//                "conversationID": conversationId,
//                "shouldRing": false
//            ]
//            didReportIncomingCall = false
//            Task {
//                try? await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
//            }
//        }
//
//        return service
//    }()

    init(
        parent: any Scope,
        clientID: String,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        apiVersion: WireNetwork.APIVersion,
        localDomain: String,
        isFederationEnabled: Bool,
        coreDataStack: CoreDataStack,
        earService: EARServiceInterface
    ) {
        self.clientID = clientID
        self.restNetworkService = restNetworkService
        self.webSocketNetworkService = webSocketNetworkService
        self.apiVersion = apiVersion
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.coreDataStack = coreDataStack
        self.pushChannelCoordinator = AppExtensionPushChannelCoordinator(clientID: clientID)
        self.earService = earService

        super.init(parent: parent)
    }
    
    func processPayload(
        eventID: UUID,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) async throws {
        // Pull pending update events.
//        let eventStream: AsyncStream<[UpdateEvent]>
        let publicKeys = try earService.fetchPublicKeys()

        // 1. Pull pending update events.
        let upstream: AsyncStream<[UpdateEvent]>
        if dependency.journal[.isConsumableNotificationsEnabled] {
            let (useCase, stream) = syncEventsUseCase()
            upstream = stream

            // because we might be interrupted when in background, we wrap the sync in an expiringActivity that will
            // cancel the task (not keeping any file lock in suspend mode)
            try await withExpiringActivity(reason: "processPayload in NSE") { [weak self] in
                guard let self else { return }
                // make sure no pushChannel is open
                let pushChannelState = PushChannelState(
                    sharedContainerURL: dependency.appContainerURL,
                    clientID: clientID
                )
                do {
                    try await pushChannelState.markAsOpen()
                } catch {
                    throw Failure.pushChannelAlreadyOpened
                }

                monitoringTask = Task { [weak self] in
                    var request = await self?.pushChannelCoordinator.listenForYieldRequests()
                    if Task.isCancelled {
                        return
                    }
                    WireLogger.sync.debug("requested to cancel sync", attributes: .incrementalSync, .newNSE)
                    self?.currentTask?.cancel()
                    request?.acknowledge()
                    WireLogger.sync.debug("notified main App to resume sync", attributes: .incrementalSync, .newNSE)
                }

                currentTask = Task {
                    do {
                        try Task.checkCancellation()
                        try await useCase.invoke()
                    } catch {
                        // either we timeout during decrypting/storing events OR an issue
                        // with the sync. In both cases, we end up with a stream of
                        // notifications that has not been shown, so we need to continue
                        // to show them.
                        WireLogger.sync.warn(
                            "syncing events via websocket: \(String(describing: error))",
                            attributes: .incrementalSyncV3, .newNSE
                        )
                        await pushChannelState.markAsClosed()
                    }
                }
                try await currentTask?.value
                WireLogger.sync.debug("closing push channel")
                await pushChannelState.markAsClosed()

                // no need to monitor anymore let's cancel
                monitoringTask?.cancel()
            }

        } else {
            upstream = try await pullEventsUseCase.invoke(publicKeys: publicKeys)
        }
        // 2. Buffer all events (stream is finite in NSE).
        var eventBatches: [[UpdateEvent]] = []
        for await batch in upstream {
            eventBatches.append(batch)
        }
        WireLogger.calling.info(
            "WOW NSE: buffered \(eventBatches.count) batches, total events: \(eventBatches.flatMap { $0 }.count)",
            attributes: .newNSE, .safePublic
        )
        let isAvsReady = dependency.sharedUserDefaults.bool(forKey: "isAVSReady")
        let isCallKitAvailable = dependency.sharedUserDefaults.bool(forKey: "isCallKitAvailable")
        WireLogger.calling.info("WOW NSE state: isAvsReady=\(isAvsReady), isCallKitAvailable=\(isCallKitAvailable)", attributes: .newNSE, .safePublic)

        // 3. Process calling events via AVS — CallKit is reported internally via callingService callbacks.
        await processCallingEventsUseCase().invoke(eventBatches: eventBatches)

        // 4. Generate notifications from events.
        let eventStream = AsyncStream<[UpdateEvent]> { continuation in
            for batch in eventBatches { continuation.yield(batch) }
            continuation.finish()
        }
        let notifications = try await generateNotificationsUseCase(
            eventID: eventID
        ).invoke(
            updateEvents: eventStream
        )

        // 5. Show notifications.
        try await showNotificationsUseCase(
            contentHandler: contentHandler
        ).invoke(
            userNotifications: notifications
        )
//        _ = await callKitReportTask?.value
    }

//    private func teeCallingEvents(
//        from upstream: AsyncStream<[UpdateEvent]>
//    ) -> AsyncStream<[UpdateEvent]> {
//        AsyncStream<[UpdateEvent]> { continuation in
//            // Ensure end() even if downstream cancels early
//            continuation.onTermination = { _ in
//                self.callingService.end()
//            }
//
//            // Start once, right before consumption begins
//            callingService.start()
//
//            Task { [weak self] in
//                guard let self else {
//                    continuation.finish()
//                    return
//                }
//
//                for await batch in upstream {
//                    if Task.isCancelled { break }
//
//                    // Only process calling events
//                    for event in batch {
//                        if let param = await self.avsParameters(from: event) {
//                            callingService.process(
//                                data: param.data,
//                                currentTime: param.currentTime,
//                                serverTime: param.serverTime,
//                                conversationId: param.conversationId,
//                                userId: param.userId,
//                                clientId: clientID,
//                                conversationType: param.conversationType
//                            )
//                        }
//                    }
//
//                    // Forward batch to downstream consumer (normal notifications)
//                    continuation.yield(batch)
//                }
//
//                continuation.finish()
//                callingService.end()
//            }
//        }
//    }
//

    // MARK: - Calling

    private var callingService: any AVSCallingEventServiceProtocol {
        shared {
            AVSCallingEventService(
                userID: dependency.accountID.transportString(),
                clientID: clientID
            )
        }
    }

    private func processCallingEventsUseCase() -> ProcessCallingEventsUseCase {
        ProcessCallingEventsUseCase(
            callingService: callingService,
            clientID: clientID,
            conversationLocalStore: conversationLocalStore,
            isFederationEnabled: isFederationEnabled,
            accountID: dependency.accountID
        )
    }

    // MARK: - Pull events consumable notifications

    private func syncEventsUseCase() -> (SyncEventsUseCase, AsyncStream<[UpdateEvent]>) {
        let sync = pullPendingUpdateEventsSyncV2
        return (SyncEventsUseCase(pendingEventsSync: sync), sync.stream)
    }

    private var pullPendingUpdateEventsSyncV2: PullPendingUpdateEventsSyncV2 {
        PullPendingUpdateEventsSyncV2(
            selfClientID: clientID,
            pushChannelAPI: pushChannelV2API,
            updateEventsStore: updateEventsLocalStore,
            journal: dependency.journal,
            decryptor: updateEventDecryptor,
            coreCryptoProvider: coreCryptoProvider
        )
    }

    private var pushChannelV2API: PushChannelV2API {
        shared {
            PushChannelV2APIBuilder(pushChannelService: pushChannelService).makeAPI(for: apiVersion)
        }
    }

    private var pushChannelService: PushChannelService {
        shared {
            PushChannelService(
                networkService: webSocketNetworkService,
                authenticationManager: authenticationManager
            )
        }
    }

    // MARK: - Pull events

    private var pullEventsUseCase: PullEventsUseCase {
        PullEventsUseCase(pendingEventsSync: pullPendingUpdateEventsSync)
    }

    private var authenticationManager: AuthenticationManager {
        shared {
            AuthenticationManager(
                clientID: clientID,
                cookieStorage: dependency.cookieStorage,
                networkService: restNetworkService,
                onAuthenticationFailure: {}
            )
        }
    }

    private var apiService: APIService {
        shared {
            APIService(
                networkService: restNetworkService,
                authenticationManager: authenticationManager
            )
        }
    }

    private var updateEventsAPI: some UpdateEventsAPI {
        shared {
            UpdateEventsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        }
    }

    private var updateEventsLocalStore: UpdateEventsLocalStore {
        shared {
            UpdateEventsLocalStore(
                eventContext: coreDataStack.eventContext,
                syncContext: coreDataStack.syncContext,
                userID: dependency.accountID,
                sharedUserDefaults: dependency.sharedUserDefaults
            )
        }
    }

    private var coreCryptoMigrationManager: CoreCryptoKeyMigrationManager {
        shared {
            CoreCryptoKeyMigrationManager(journal: dependency.journal)
        }
    }

    private var coreCryptoProvider: CoreCryptoProvider {
        shared {
            CoreCryptoProvider(
                selfUserID: dependency.accountID,
                sharedContainerURL: dependency.appContainerURL,
                accountDirectory: dependency.userAccountDataURL,
                sharedUserDefaults: dependency.sharedUserDefaults,
                syncContext: coreDataStack.syncContext,
                coreCryptoKeyMigrationManager: coreCryptoMigrationManager,
                allowCreation: false,
                localDomain: localDomain
            )
        }
    }

    private var proteusService: ProteusService {
        shared {
            ProteusService(coreCryptoProvider: coreCryptoProvider)
        }
    }

    private var userClientsLocalStore: UserClientsLocalStore {
        shared {
            UserClientsLocalStore(context: coreDataStack.syncContext)
        }
    }

    private var messageLocalStore: MessageLocalStore {
        shared {
            MessageLocalStore(context: coreDataStack.syncContext)
        }
    }

    private var userLocalStore: UserLocalStore {
        shared {
            UserLocalStore(
                context: coreDataStack.syncContext,
                messageLocalStore: messageLocalStore
            )
        }
    }

    private var proteusMessageDecryptor: ProteusMessageDecryptor {
        shared {
            ProteusMessageDecryptor(
                proteusService: proteusService,
                userClientsLocalStore: userClientsLocalStore,
                userLocalStore: userLocalStore
            )
        }
    }

    private var featureRepository: LegacyFeatureRepository {
        shared {
            LegacyFeatureRepository(context: coreDataStack.syncContext)
        }
    }

    private var mlsActionExecutor: MLSActionExecutor {
        shared {
            MLSActionExecutor(
                coreCryptoProvider: coreCryptoProvider,
                featureRepository: featureRepository
            )
        }
    }

    private var mlsDecryptionService: MLSDecryptionService {
        shared {
            MLSDecryptionService(
                context: coreDataStack.syncContext,
                mlsActionExecutor: mlsActionExecutor
            )
        }
    }

    private var conversationLocalStore: ConversationLocalStore {
        shared {
            ConversationLocalStore(
                context: coreDataStack.syncContext,
                mlsService: nil,
                messageLocalStore: messageLocalStore,
                localDomain: localDomain,
                isFederationEnabled: isFederationEnabled
            )
        }
    }

    private var mlsMessageDecryptor: MLSMessageDecryptor {
        shared {
            MLSMessageDecryptor(
                mlsDecryptionService: mlsDecryptionService,
                conversationLocalStore: conversationLocalStore
            )
        }
    }

    private var updateEventDecryptor: UpdateEventDecryptor {
        shared {
            UpdateEventDecryptor(
                proteusMessageDecryptor: proteusMessageDecryptor,
                mlsMessageDecryptor: mlsMessageDecryptor,
                mlsService: nil,
                messageLocalStore: messageLocalStore
            )
        }
    }

    private var pullPendingUpdateEventsSync: PullPendingUpdateEventsSync {
        shared {
            PullPendingUpdateEventsSync(
                selfClientID: clientID,
                api: updateEventsAPI,
                store: updateEventsLocalStore,
                journal: dependency.journal,
                decryptor: updateEventDecryptor,
                coreCryptoProvider: coreCryptoProvider
            )
        }
    }

    // MARK: - Generate notifications

    private func generateNotificationsUseCase(eventID: UUID) -> GenerateNotificationUseCase {
        GenerateNotificationUseCase(
            conversationEventBuilder: conversationEventBuilder,
            userEventBuilder: userEventNotificationBuilder,
            eventID: eventID
        )
    }

    private var conversationEventBuilder: ConversationEventNotificationBuilder {
        shared {
            let validator = ConversationEventNotificationBuilder.Validator(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore,
                messageLocalStore: messageLocalStore
            )

            return ConversationEventNotificationBuilder(
                validator: validator,
                conversationMessageAddEventNotificationBuilder: conversationMessageAddEventNotificationBuilder,
                conversationMemberLeaveEventNotificationBuilder: conversationMemberLeaveEventNotificationBuilder,
                conversationMemberJoinEventNotificationBuilder: conversationMemberJoinEventNotificationBuilder,
                conversationCreateEventNotificationBuilder: conversationCreateEventNotificationBuilder,
                conversationDeleteEventNotificationBuilder: conversationDeleteEventNotificationBuilder,
                conversationMessageTimerUpdateEventNotificationBuilder: conversationMessageTimerUpdateEventNotificationBuilder
            )
        }
    }

    private var conversationMessageAddEventNotificationBuilder: ConversationMessageAddEventNotificationBuilder {
        let context = ConversationMessageAddEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore
        )

        let validator = ConversationMessageAddEventNotificationBuilder.Validator(
            conversationLocalStore: conversationLocalStore
        )

        return ConversationMessageAddEventNotificationBuilder(
            context: context,
            validator: validator,
            conversationCallingEventNotificationBuilder: conversationCallingEventNotificationBuilder,
            conversationAudioMessageNotificationBuilder: conversationAudioMessageNotificationBuilder,
            conversationEphemeralMessageNotificationBuilder: conversationEphemeralMessageNotificationBuilder,
            conversationFileUploadMessageNotificationBuilder: conversationFileUploadMessageNotificationBuilder,
            conversationHiddenMessageNotificationBuilder: conversationHiddenMessageNotificationBuilder,
            conversationImageMessageNotificationBuilder: conversationImageMessageNotificationBuilder,
            conversationLocationMessageNotificationBuilder: conversationLocationMessageNotificationBuilder,
            conversationPingMessageNotificationBuilder: conversationPingMessageNotificationBuilder,
            conversationVideoMessageNotificationBuilder: conversationVideoMessageNotificationBuilder,
            conversationTextMessageNotificationBuilder: conversationTextMessageNotificationBuilder
        )
    }

    private var conversationCallingEventNotificationBuilder: ConversationCallingEventNotificationBuilder {
        let validator = ConversationCallingEventNotificationBuilder.Validator(
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore,
            userDefaults: dependency.sharedUserDefaults
        )

        let context = ConversationCallingEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationCallingEventNotificationBuilder(
            context: context,
            validator: validator,
            accountID: dependency.accountID
        )
    }

    private var conversationAudioMessageNotificationBuilder: ConversationAudioMessageNotificationBuilder {
        let context = ConversationAudioMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationAudioMessageNotificationBuilder(context: context)
    }

    private var conversationVideoMessageNotificationBuilder: ConversationVideoMessageNotificationBuilder {
        let context = ConversationVideoMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationVideoMessageNotificationBuilder(context: context)
    }

    private var conversationPingMessageNotificationBuilder: ConversationPingMessageNotificationBuilder {
        let context = ConversationPingMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationPingMessageNotificationBuilder(context: context)
    }

    private var conversationLocationMessageNotificationBuilder: ConversationLocationMessageNotificationBuilder {
        let context = ConversationLocationMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationLocationMessageNotificationBuilder(context: context)
    }

    private var conversationHiddenMessageNotificationBuilder: ConversationHiddenMessageNotificationBuilder {
        let context = ConversationHiddenMessageNotificationBuilder.Context(
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore
        )

        return ConversationHiddenMessageNotificationBuilder(context: context)
    }

    private var conversationFileUploadMessageNotificationBuilder: ConversationFileUploadMessageNotificationBuilder {
        let context = ConversationFileUploadMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationFileUploadMessageNotificationBuilder(context: context)
    }

    private var conversationImageMessageNotificationBuilder: ConversationImageMessageNotificationBuilder {
        let context = ConversationImageMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        return ConversationImageMessageNotificationBuilder(context: context)
    }

    private var conversationEphemeralMessageNotificationBuilder: ConversationEphemeralMessageNotificationBuilder {
        let context = ConversationEphemeralMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore,
            messageLocalStore: messageLocalStore
        )

        return ConversationEphemeralMessageNotificationBuilder(context: context)
    }

    private var conversationTextMessageNotificationBuilder: ConversationTextMessageNotificationBuilder {
        let context = ConversationTextMessageNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore,
            messageLocalStore: messageLocalStore
        )

        return ConversationTextMessageNotificationBuilder(context: context)
    }

    private var conversationMemberLeaveEventNotificationBuilder: ConversationMemberLeaveEventNotificationBuilder {
        let context = ConversationMemberLeaveEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = ConversationMemberLeaveEventNotificationBuilder.Validator(
            userLocalStore: userLocalStore
        )

        return ConversationMemberLeaveEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var conversationMemberJoinEventNotificationBuilder: ConversationMemberJoinEventNotificationBuilder {
        let context = ConversationMemberJoinEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = ConversationMemberJoinEventNotificationBuilder.Validator(
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore
        )

        return ConversationMemberJoinEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var conversationCreateEventNotificationBuilder: ConversationCreateEventNotificationBuilder {
        let context = ConversationCreateEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = ConversationCreateEventNotificationBuilder.Validator(
            userLocalStore: userLocalStore
        )

        return ConversationCreateEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var conversationDeleteEventNotificationBuilder: ConversationDeleteEventNotificationBuilder {
        let context = ConversationDeleteEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = ConversationDeleteEventNotificationBuilder.Validator(
            conversationLocalStore: conversationLocalStore
        )

        return ConversationDeleteEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var conversationMessageTimerUpdateEventNotificationBuilder: ConversationMessageTimerUpdateEventNotificationBuilder {
        let context = ConversationMessageTimerUpdateEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = ConversationMessageTimerUpdateEventNotificationBuilder.Validator()

        return ConversationMessageTimerUpdateEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var userEventNotificationBuilder: UserEventNotificationBuilder {
        shared {
            let validator = UserEventNotificationBuilder.Validator()

            return UserEventNotificationBuilder(
                validator: validator,
                userConnectionEventNotificationBuilder: userConnectionEventNotificationBuilder,
                userContactJoinEventNotificationBuilder: userContactJoinEventNotificationBuilder
            )
        }
    }

    private var userContactJoinEventNotificationBuilder: UserContactJoinEventNotificationBuilder {
        let context = UserContactJoinEventNotificationBuilder.Context()
        let validator = UserContactJoinEventNotificationBuilder.Validator()

        return UserContactJoinEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var userConnectionEventNotificationBuilder: UserConnectionEventNotificationBuilder {
        let context = UserConnectionEventNotificationBuilder.Context(
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let validator = UserConnectionEventNotificationBuilder.Validator()

        return UserConnectionEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    // MARK: - Show notifications

    private func showNotificationsUseCase(contentHandler: @escaping (UNNotificationContent) -> Void)
        -> ShowNotificationUseCase {
        ShowNotificationUseCase(
            contentHandler: contentHandler,
            conversationLocalStore: conversationLocalStore,
            selectedAccount: dependency.account,
            accountManager: dependency.accountManager,
            databaseSaver: databaseSaver
        )
    }

    private var databaseSaver: DatabaseSaver {
        shared {
            DatabaseSaver(context: coreDataStack.syncContext)
        }
    }

}

private struct AVSCallParams {
     let data: Data
     let currentTime: UInt32
     let serverTime: UInt32
     let conversationId: String
     let userId: String
     let clientId: String
     let conversationType: Int32
 }
