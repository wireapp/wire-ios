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
import GenericMessageProtocol
import WireLogging
import WireNetwork
import CallKit

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

    private lazy var callingService: any AVSCallingEventServiceProtocol = {
        let service = AVSCallingEventService(
            userID: dependency.accountID.transportString(),
            clientID: clientID
        )

        // Track whether we reported an incoming call to CallKit,
        // so onCallClosed knows whether it needs to stop ringing.
        var didReportIncomingCall = false

        service.onIncomingCall = { [weak self] conversationId, shouldRing, isVideoCall in
            WireLogger.calling.info(
                "gagaga onIncomingCall",
                attributes: .newNSE, .safePublic
            )
            guard let self else { return }
            let callKitContent: [String: Any] = [
                "accountID": self.dependency.accountID.uuidString,
                "conversationID": conversationId,
                "shouldRing": shouldRing,
                "hasVideo": isVideoCall,
                "callerName": ""
            ]
            WireLogger.calling.info(
                "gagaga onIncomingCall, callKitContent \(callKitContent)",
                attributes: .newNSE, .safePublic
            )
            didReportIncomingCall = shouldRing

            CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
                if let error {
                    WireLogger.calling.error("gagaga reportNewIncomingVoIPPushPayload error: \(error)", attributes: .newNSE, .safePublic)
                } else {
                    WireLogger.calling.info("gagaga reportNewIncomingVoIPPushPayload done", attributes: .newNSE, .safePublic)
                }
            }
        }

        service.onMissedCall = { conversationId, messageTime, isVideoCall in
            WireLogger.calling.info(
                "gagaga onMissedCall",
                attributes: .newNSE, .safePublic
            )
            // Nothing to do here — the missed call text notification
            // is already built by ConversationCallingEventNotificationBuilder
            // from the same event in the event stream.
            WireLogger.calling.info(
                "AVS: missed call in conversation \(conversationId)",
                attributes: .newNSE, .safePublic
            )
        }

        service.onCallClosed = { [weak self] reason, conversationId in
            WireLogger.calling.info(
                "gagaga onCallClosed",
                attributes: .newNSE, .safePublic
            )
            guard let self, didReportIncomingCall else { return }
            // Stop ringing — only if we previously started it
            let callKitContent: [String: Any] = [
                "accountID": self.dependency.accountID.uuidString,
                "conversationID": conversationId,
                "shouldRing": false
            ]
            didReportIncomingCall = false
            Task {
                try? await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
            }
        }

        return service
    }()

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
        let eventStream: AsyncStream<[UpdateEvent]>
        let publicKeys = try earService.fetchPublicKeys()

        if dependency.journal[.isConsumableNotificationsEnabled] {
            let (useCase, stream) = syncEventsUseCase()
            eventStream = stream

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
            // callingService.start()
             print("🥳 start")
             WireLogger.calling.info(
                 "gagaga start",
                 attributes: .newNSE, .safePublic
             )
            eventStream = try await pullEventsUseCase.invoke(publicKeys: publicKeys)
        }
//        for await events in eventStream {
//            for event in events {
//                WireLogger.calling.info(
//                    "gagaga event \(event)",
//                    attributes: .newNSE, .safePublic
//                )
//                if let param = await avsParameters(from: event)  {
//                    print("🥳 process")
//                    WireLogger.calling.info(
//                        "gagaga process",
//                        attributes: .newNSE, .safePublic
//                    )
//                    callingService.process(
//                        data: param.data,
//                        currentTime: param.currentTime,
//                        serverTime: param.serverTime,
//                        conversationId: param.conversationId,
//                        userId: param.userId,
//                        clientId: clientID,
//                        conversationType: param.conversationType
//                    )
//                }
//            }
//        }
//        callingService.end()
        WireLogger.calling.info(
            "gagaga end",
            attributes: .newNSE, .safePublic
        )
        print("🥳 end")

        // Generate notifications from events.
        let notifications = try await generateNotificationsUseCase(
            eventID: eventID
        ).invoke(
            updateEvents: eventStream
        )

        // Show notifications.
        try await showNotificationsUseCase(
            contentHandler: contentHandler
        ).invoke(
            userNotifications: notifications
        )
    }

    private func avsParameters(from event: UpdateEvent) async -> AVSCallParams? {
        switch event {
        case .conversation(.proteusMessageAdd(let e)):
            WireLogger.calling.info(
                "gagaga proteus",
                attributes: .newNSE, .safePublic
            )
            return await avsParametersForProteus(e).first
        case .conversation(.mlsMessageAdd(let e)):
            WireLogger.calling.info(
                "gagaga MLS",
                attributes: .newNSE, .safePublic
            )
            return await avsParametersForMLS(e).first
        default:
            return nil
        }
    }

    private func avsParametersForProteus(
         _ event: ConversationProteusMessageAddEvent
     ) async -> [AVSCallParams] {
         guard
             let decryptedBase64 = event.message.decryptedMessage,
             let payload = Data(base64Encoded: decryptedBase64),
             let genericMessage = GenericMessage(from: payload, validate: false),
             genericMessage.hasCalling,
             let callingData = genericMessage.calling.content.data(using: .utf8)
         else { return [] }

         let params = await buildParams(
             callingData: callingData,
             callingProto: genericMessage.calling,
             fallbackConversationID: event.conversationID,
             senderID: event.senderID,
             senderClientID: event.messageSenderClientID,
             timestamp: event.timestamp,
             isMLS: false
         )
         return params.map { [$0] } ?? []
     }

    private func avsParametersForMLS(
          _ event: ConversationMLSMessageAddEvent
      ) async -> [AVSCallParams] {
          var result: [AVSCallParams] = []

          for decryptedMessage in event.decryptedMessages {
              guard
                  let payload = Data(base64Encoded: decryptedMessage.message),
                  let genericMessage = GenericMessage(from: payload, validate: false),
                  genericMessage.hasCalling,
                  let callingData = genericMessage.calling.content.data(using: .utf8),
                  let clientID = decryptedMessage.senderClientID,  // optional in MLS
                  let timestamp = event.timestamp                   // optional in MLS
              else { continue }
              WireLogger.calling.info(
                  "gagaga hasCalling is true",
                  attributes: .newNSE, .safePublic
              )
              if let params = await buildParams(
                  callingData: callingData,
                  callingProto: genericMessage.calling,
                  fallbackConversationID: event.conversationID,
                  senderID: event.senderID,
                  senderClientID: clientID,
                  timestamp: timestamp,
                  isMLS: true
              ) {
                  result.append(params)
              }
          }

          return result
      }

    private func buildParams(
          callingData: Data,
          callingProto: Calling,
          fallbackConversationID: ConversationID,
          senderID: UserID,
          senderClientID: String,
          timestamp: Date,
          isMLS: Bool
      ) async -> AVSCallParams? {
          // Prefer conversation ID embedded in the calling proto (mirrors WireCallCenterV3)
          let callingConvID = callingProto.qualifiedConversationID
          let conversationUUID: UUID
          let conversationDomain: String?
          if !callingConvID.id.isEmpty, let uuid = UUID(uuidString: callingConvID.id) {
              conversationUUID = uuid
              conversationDomain = callingConvID.domain.isEmpty ? nil : callingConvID.domain
          } else {
              conversationUUID = fallbackConversationID.id
              conversationDomain = fallbackConversationID.domain
          }

          func serialize(id: UUID, domain: String?) -> String {
              if isFederationEnabled, let domain { return "\(id.transportString())@\(domain)" }
              return id.transportString()
          }

          let conversation = await conversationLocalStore.fetchOrCreateConversation(
              id: conversationUUID,
              domain: conversationDomain
          )
          let isGroup = await conversationLocalStore.isGroupConversation(conversation)

          // WCALL_CONV_TYPE: 0 = oneToOne, 1 = group (Proteus), 3 = conference_mls
          let conversationType: Int32 = if !isGroup {
              0  // WCALL_CONV_TYPE_ONEONONE
          } else if isMLS {
              3  // WCALL_CONV_TYPE_CONFERENCE_MLS
          } else {
              1  // WCALL_CONV_TYPE_GROUP
          }

          return AVSCallParams(
              data: callingData,
              currentTime: UInt32(Date.now.timeIntervalSince1970),
              serverTime: UInt32(timestamp.timeIntervalSince1970),
              conversationId: serialize(id: conversationUUID, domain: conversationDomain),
              userId: serialize(id: senderID.id, domain: senderID.domain),
              clientId: senderClientID,
              conversationType: conversationType
          )
      }



    private func avsParameters1(
        from event: UpdateEvent
    ) async -> (data: Data, currentTime: UInt32, serverTime: UInt32,
                conversationId: String, userId: String,
                clientId: String, conversationType: Int32)? {

        // Only proteusMessageAdd events carry calling payloads
        guard
            case .conversation(.proteusMessageAdd(let proteusEvent)) = event,
            let decryptedBase64 = proteusEvent.message.decryptedMessage,
            let payload = Data(base64Encoded: decryptedBase64),
            let genericMessage = GenericMessage(from: payload, validate: false),
            genericMessage.hasCalling,
            // The calling content is a JSON string — AVS needs it as raw bytes
            let callingData = genericMessage.calling.content.data(using: .utf8)
        else { return nil }
        WireLogger.calling.info(
            "gagaga hasCalling is true",
            attributes: .newNSE, .safePublic
        )
        // Prefer the conversation ID embedded in the calling message (mirrors WireCallCenterV3)
        let callingConvID = genericMessage.calling.qualifiedConversationID
        let conversationUUID: UUID
        let conversationDomain: String?
        if !callingConvID.id.isEmpty, let uuid = UUID(uuidString: callingConvID.id) {
            conversationUUID = uuid
            conversationDomain = callingConvID.domain.isEmpty ? nil : callingConvID.domain
        } else {
            conversationUUID = proteusEvent.conversationID.id
            conversationDomain = proteusEvent.conversationID.domain
        }

        // Serialize UUID as "uuid@domain" when federation is enabled (mirrors AVSIdentifier.serialized)
        func serialize(id: UUID, domain: String?) -> String {
            if isFederationEnabled, let domain { return "\(id.transportString())@\(domain)" }
            return id.transportString()
        }

        // Look up conversation type from CoreData
        // WCALL_CONV_TYPE_ONEONONE = 0, WCALL_CONV_TYPE_GROUP = 1
        let conversation = await conversationLocalStore.fetchOrCreateConversation(
            id: conversationUUID,
            domain: conversationDomain
        )
        WireLogger.calling.info(
            "gagaga conversation \(conversation)",
            attributes: .newNSE, .safePublic
        )
        let isGroup = await conversationLocalStore.isGroupConversation(conversation)
        WireLogger.calling.info(
            "gagaga isGroup \(isGroup)",
            attributes: .newNSE, .safePublic
        )

        return (
            data: callingData,
            currentTime: UInt32(Date.now.timeIntervalSince1970),   // mirrors CallEvent.currentTimestamp
            serverTime: UInt32(proteusEvent.timestamp.timeIntervalSince1970), // mirrors CallEvent.serverTimestamp
            conversationId: serialize(id: conversationUUID, domain: conversationDomain),
            userId: serialize(id: proteusEvent.senderID.id, domain: proteusEvent.senderID.domain),
            clientId: proteusEvent.messageSenderClientID,
            conversationType: isGroup ? 1 : 0
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
