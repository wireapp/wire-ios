//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Combine
import Foundation
import WireDataModel
import WireRequestStrategy

@objcMembers
public final class CallingRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder, ZMContextChangeTracker, ZMContextChangeTrackerSource, ZMEventConsumer {

    // MARK: - Private Properties

    private static let logger = Logger(subsystem: "VoIP Push", category: "CallingRequestStrategy")

    private let zmLog = ZMSLog(tag: "calling")

    private let messageSender: MessageSenderInterface
    private let flowManager: FlowManagerType
    private let decoder = JSONDecoder()

    private let callEventStatus: CallEventStatus

    private var callConfigRequestSync: ZMSingleRequestSync! = nil
    private var callConfigCompletion: CallConfigRequestCompletion?

    private var clientDiscoverySync: ZMSingleRequestSync! = nil
    private var clientDiscoveryRequest: ClientDiscoveryRequest?

    private let ephemeralURLSession = URLSession(configuration: .ephemeral)
    private let fetchUserClientsUseCase: FetchUserClientsUseCaseProtocol

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Properties

    var callCenter: WireCallCenterV3?

    // MARK: - Init

    public init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        clientRegistrationDelegate: ClientRegistrationDelegate,
        flowManager: FlowManagerType,
        callEventStatus: CallEventStatus,
        fetchUserClientsUseCase: FetchUserClientsUseCaseProtocol = FetchUserClientsUseCase(),
        messageSender: MessageSenderInterface
    ) {
        self.messageSender = messageSender
        self.flowManager = flowManager
        self.callEventStatus = callEventStatus
        self.fetchUserClientsUseCase = fetchUserClientsUseCase

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        configuration = [.allowsRequestsWhileInBackground,
                         .allowsRequestsWhileOnline,
                         .allowsRequestsWhileWaitingForWebsocket]

        callConfigRequestSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        clientDiscoverySync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)

        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        if let clientId = selfUser.selfClient()?.remoteIdentifier {
            zmLog.debug("Creating callCenter from init")
            callCenter = WireCallCenterV3Factory.callCenter(withUserId: selfUser.avsIdentifier,
                                                            clientId: clientId,
                                                            uiMOC: managedObjectContext.zm_userInterface,
                                                            flowManager: flowManager,
                                                            analytics: managedObjectContext.analytics,
                                                            transport: self)
        }

        setupEventProcessingNotifications()
    }

    private func setupEventProcessingNotifications() {

        NotificationCenter.default
            .publisher(for: .eventProcessorDidStartProcessingEventsNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.callCenter?.avsWrapper.notify(isProcessingNotifications: true) }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .eventProcessorDidFinishProcessingEventsNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.callCenter?.avsWrapper.notify(isProcessingNotifications: false) }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        let request = callConfigRequestSync.nextRequest(for: apiVersion) ??
        clientDiscoverySync.nextRequest(for: apiVersion)

        return request
    }

    // MARK: - Single Request Transcoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch sync {
        case callConfigRequestSync:
            zmLog.debug("Scheduling request to '/calls/config/v2'")

            return ZMTransportRequest(path: "/calls/config/v2",
                                      method: .get,
                                      binaryData: nil,
                                      type: "application/json",
                                      contentDisposition: nil,
                                      shouldCompress: true,
                                      apiVersion: apiVersion.rawValue)

        case clientDiscoverySync:
            guard
                let request = clientDiscoveryRequest,
                let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else {
                return nil
            }

            zmLog.debug("Scheduling request to discover clients")

            let factory = ClientMessageRequestFactory()

            return factory.upstreamRequestForFetchingClients(
                conversationId: request.conversationId,
                domain: request.domain,
                selfClient: selfClient,
                apiVersion: apiVersion
            )

        default:
            return nil
        }

    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        switch sync {
        case callConfigRequestSync:
            zmLog.debug("Received call config response for \(self): \(response)")
            if response.httpStatus == 200 {
                var payloadAsString: String?
                if let payload = response.payload, let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                    payloadAsString = String(decoding: data, as: UTF8.self)
                }
                zmLog.debug("Callback: \(String(describing: self.callConfigCompletion))")
                self.callConfigCompletion?(payloadAsString, response.httpStatus)
                self.callConfigCompletion = nil
            }

        case clientDiscoverySync:
            zmLog.debug("Received client discovery response for \(self): \(response)")

            defer {
                clientDiscoveryRequest = nil
            }

            guard response.httpStatus == 412 else {
                zmLog.warn("Expected 412 response: missing clients")
                return
            }

            guard let jsonData = response.rawData else { return }

            let apiVersion = APIVersion(rawValue: response.apiVersion)!
            decoder.userInfo = [ClientDiscoveryResponsePayload.apiVersionKey: apiVersion]

            do {
                let payload = try decoder.decode(ClientDiscoveryResponsePayload.self, from: jsonData)
                clientDiscoveryRequest?.completion(payload.clients)
            } catch {
                zmLog.error("Could not parse client discovery response: \(error.localizedDescription)")
            }

        default:
            break
        }
    }

    // MARK: - Context Change Tracker

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self]
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return nil
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // nop
    }

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        guard callCenter == nil else { return }

        for object in objects {
            if let userClient = object as? UserClient, userClient.isSelfClient(), let clientId = userClient.remoteIdentifier, let userId = userClient.user?.avsIdentifier {
                zmLog.debug("Creating callCenter")
                let uiContext = managedObjectContext.zm_userInterface!
                let analytics = managedObjectContext.analytics
                uiContext.performGroupedBlock {
                    self.callCenter = WireCallCenterV3Factory.callCenter(withUserId: userId,
                                                                         clientId: clientId,
                                                                         uiMOC: uiContext.zm_userInterface,
                                                                         flowManager: self.flowManager,
                                                                         analytics: analytics,
                                                                         transport: self)
                }
                break
            }
        }
    }

    // MARK: - Event Consumer

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        Self.logger.trace("process events: \(events)")
        events.forEach(processEvent)
    }

    private func processEvent(_ event: ZMUpdateEvent) {
        let serverTimeDelta = managedObjectContext.serverTimeDelta
        guard event.type.isOne(of: [.conversationOtrMessageAdd, .conversationMLSMessageAdd]) else { return }

        if let genericMessage = GenericMessage(from: event), genericMessage.hasCalling {

            guard
                let payload = genericMessage.calling.content.data(using: .utf8, allowLossyConversion: false),

                    let callEventContent = CallEventContent(from: payload, with: decoder),
                let senderUUID = event.senderUUID,
                let conversationUUID = event.conversationUUID,
                let eventTimestamp = event.timestamp
            else {
                zmLog.error("ignoring calling message: \(genericMessage)")
                return
            }

            self.zmLog.debug("received calling message, timestamp \(eventTimestamp), serverTimeDelta \(serverTimeDelta)")

            guard !callEventContent.isRemoteMute else {
                callCenter?.isMuted = true
                zmLog.debug("muted remotely from calling message")
                return
            }

            processCallEvent(
                callingConversationId: genericMessage.calling.qualifiedConversationID,
                conversationUUID: conversationUUID,
                senderUUID: senderUUID,
                clientId: event.senderClientID ?? callEventContent.callerClientID,
                conversationDomain: event.conversationDomain,
                senderDomain: event.senderDomain,
                payload: payload,
                currentTimestamp: serverTimeDelta,
                eventTimestamp: eventTimestamp
            )
        }
    }

    func processCallEvent(
        callingConversationId: QualifiedConversationId,
        conversationUUID: UUID,
        senderUUID: UUID,
        clientId: String,
        conversationDomain: String?,
        senderDomain: String?,
        payload: Data,
        currentTimestamp: TimeInterval,
        eventTimestamp: Date) {

            let identifier = !callingConversationId.id.isEmpty ? UUID(uuidString: callingConversationId.id)! : conversationUUID
            let domain = !callingConversationId.domain.isEmpty ? callingConversationId.domain : conversationDomain

            let conversationId = AVSIdentifier(
                identifier: identifier,
                domain: domain
            )

            let userId = AVSIdentifier(
                identifier: senderUUID,
                domain: senderDomain
            )

            let callEvent = CallEvent(
                data: payload,
                currentTimestamp: Date().addingTimeInterval(currentTimestamp),
                serverTimestamp: eventTimestamp,
                conversationId: conversationId,
                userId: userId,
                clientId: clientId
            )

            callEventStatus.scheduledCallEventForProcessing()
            callCenter?.processCallEvent(callEvent, completionHandler: { [weak self] in
                self?.zmLog.debug("processed calling message")
                self?.callEventStatus.finishedProcessingCallEvent()
            })
        }

}

// MARK: - Wire Call Center Transport

extension CallingRequestStrategy: WireCallCenterTransport {

    public func send(
        data: Data,
        conversationId: AVSIdentifier,
        targets: [AVSClient]?,
        overMLSSelfConversation: Bool,
        completionHandler: @escaping ((Int) -> Void)
    ) {
        let dataString = String(decoding: data, as: UTF8.self)
        let callingContent = Calling(content: dataString, conversationId: conversationId.toQualifiedId())

        managedObjectContext.performGroupedBlock {
            guard let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: self.managedObjectContext
            ) else {
                self.zmLog.error("Not sending calling messsage since conversation doesn't exist")
                completionHandler(500)
                return
            }

            let genericMessage = GenericMessage(content: callingContent)

            self.zmLog.debug("schedule calling message")

            let recipients = targets.map { self.recipients(for: $0, in: self.managedObjectContext) } ?? .conversationParticipants

            let message: GenericMessageEntity

            if overMLSSelfConversation, conversation.messageProtocol == .mls {
                guard let selfConversation = ZMConversation.fetchSelfMLSConversation(in: self.managedObjectContext) else {
                    WireLogger.mls.error("missing self conversation for sending message to own clients")
                    completionHandler(500)
                    return
                }

                message = GenericMessageEntity(
                    message: genericMessage,
                    context: self.managedObjectContext,
                    conversation: selfConversation,
                    targetRecipients: recipients,
                    completionHandler: nil
                )
            } else {
                message = GenericMessageEntity(
                    message: genericMessage,
                    context: self.managedObjectContext,
                    conversation: conversation,
                    targetRecipients: recipients,
                    completionHandler: nil
                )
            }

            WaitingGroupTask(context: self.managedObjectContext) {
                do {
                    try await self.messageSender.sendMessage(message: message)
                    completionHandler(200)
                } catch {
                    completionHandler(400)
                }
            }
        }
    }

    public func sendSFT(data: Data, url: URL, completionHandler: @escaping ((Result<Data, Error>) -> Void)) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = data

        ephemeralURLSession.task(with: request) { data, response, error in
            if let error {
                completionHandler(.failure(SFTResponseError.transport(error: error)))
                return
            }

            guard
                let response = response as? HTTPURLResponse,
                let data
            else {
                completionHandler(.failure(SFTResponseError.missingData))
                return
            }

            guard (200...299).contains(response.statusCode) else {
                completionHandler(.failure(SFTResponseError.server(status: response.statusCode)))
                return
            }

            completionHandler(.success(data))
        }.resume()
    }

    public func requestCallConfig(completionHandler: @escaping CallConfigRequestCompletion) {
        self.zmLog.debug("requestCallConfig() called, moc = \(managedObjectContext)")
        managedObjectContext.performGroupedBlock { [unowned self] in
            self.zmLog.debug("requestCallConfig() on the moc queue")
            self.callConfigCompletion = completionHandler

            self.callConfigRequestSync.readyForNextRequestIfNotBusy()
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    public func requestClientsList(conversationId: AVSIdentifier, completionHandler: @escaping ([AVSClient]) -> Void) {
        self.zmLog.debug("requestClientList() called, moc = \(managedObjectContext)")

        managedObjectContext.performGroupedBlock { [unowned self] in
            guard let conversation = ZMConversation.fetch(
                with: conversationId.identifier,
                domain: conversationId.domain,
                in: self.managedObjectContext
            ) else {
                self.zmLog.error("Can't request client list since conversation doesn't exist")
                completionHandler([])
                return
            }

            switch conversation.messageProtocol {
            case .proteus, .mixed:
                // With proteus, we discover clients by posting an otr message to no-one,
                // then parse the error response that contains the list of all clients.
                self.clientDiscoveryRequest = ClientDiscoveryRequest(
                    conversationId: conversationId.identifier,
                    domain: conversationId.domain,
                    completion: completionHandler
                )
                self.clientDiscoverySync.readyForNextRequestIfNotBusy()
                RequestAvailableNotification.notifyNewRequestsAvailable(nil)

            case .mls:
                // With MLS we will fetch all clients for each group participant at once
                // directly from the backend.
                let userIDs = conversation.localParticipants.map { user in
                    QualifiedID(uuid: user.remoteIdentifier, domain: user.domain ?? BackendInfo.domain!)
                }

                Task {
                    do {
                        let qualifiedClientIDs = try await self.fetchUserClientsUseCase.fetchUserClients(
                            userIDs: Set(userIDs),
                            in: self.managedObjectContext
                        )

                        let avsClients = qualifiedClientIDs.map {
                            AVSClient(
                                userId: AVSIdentifier(identifier: $0.userID, domain: $0.domain),
                                clientId: $0.clientID
                            )
                        }

                        completionHandler(avsClients)

                    } catch {
                        WireLogger.mls.error("Failed to fetch client list for MLS conference: \(String(describing: error))")
                    }
                }
            }
        }
    }

    enum SFTResponseError: LocalizedError {

        case server(status: Int)
        case transport(error: Error)
        case missingData

        var errorDescription: String? {
            switch self {
            case let .server(status: status):
                return "Server http status code: \(status)"
            case let .transport(error: error):
                return "Transport error: \(error.localizedDescription)"
            case .missingData:
                return "Response body missing data"
            }
        }

    }

    private func recipients(for targets: [AVSClient], in managedObjectContext: NSManagedObjectContext) -> Recipients {
        let clientsByUser = targets
            .compactMap { UserClient.fetchExistingUserClient(with: $0.clientId, in: managedObjectContext) }
            .partition(by: \.user)
            .mapValues { Set($0) }

        return .clients(clientsByUser)
    }

}

// MARK: - Client Discovery Request

extension CallingRequestStrategy {

    struct ClientDiscoveryRequest {

        let conversationId: UUID
        let domain: String?
        let completion: ([AVSClient]) -> Void

    }

    struct ClientDiscoveryResponsePayload: Decodable {
        static let apiVersionKey = CodingUserInfoKey(rawValue: "clientDiscoveryDecodingOptions")!

        let clients: [AVSClient]

        /// This can decode the two types of responses listed below given that v0 uses legacy endpoints and v1 uses federation endpoints
        ///
        /// When querying the legacy endpoint, this will be the response
        /// {
        ///    "missing": {
        ///       "000600d0-000b-9c1a-000d-a4130002c221": [
        ///          "60f85e4b15ad3786",
        ///          "6e323ab31554353b"
        ///       ]
        ///    }
        ///    ...
        /// }
        ///
        /// When querying the federation enabled endpoint, this will be the response
        /// {
        ///    "missing": {
        ///       "domain1.example.com": {
        ///           "000600d0-000b-9c1a-000d-a4130002c221": [
        ///               "60f85e4b15ad3786",
        ///               "6e323ab31554353b"
        ///           ]
        ///       }
        ///    }
        ///    ...
        /// }
        init(from decoder: Decoder) throws {
            guard let apiVersion = decoder.userInfo[Self.apiVersionKey] as? APIVersion else {
                fatalError("missing api version")
            }

            // get the main container from the decoder
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // get the nested container keyed by "missing"
            // it will contain a list of users and their client ids, but depending on the response, it may be segmented by domains
            let nestedContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .missing)

            // define the block used below to extract the clients from a container
            let extractClientsFromContainer = { (container: KeyedDecodingContainer<DynamicKey>, domain: String?) -> [AVSClient] in
                var clients = [AVSClient]()

                try container.allKeys.forEach { userIdKey in
                    let clientIds = try container.decode([String].self, forKey: userIdKey)

                    let identifier = AVSIdentifier(
                        identifier: UUID(uuidString: userIdKey.stringValue)!,
                        domain: domain
                    )

                    clients += clientIds.compactMap {
                        AVSClient(userId: identifier, clientId: $0)
                    }
                }

                return clients
            }

            var allClients = [AVSClient]()

            switch apiVersion {
            case .v0:
                // `nestedContainer` contains all the user ids with no notion of domain, we can extract clients directly
               allClients = try extractClientsFromContainer(nestedContainer, nil)
            case .v1, .v2, .v3, .v4, .v5, .v6:
                // `nestedContainer` has further nested containers each dynamically keyed by a domain name.
                // we need to loop over each container to extract the clients.
                try nestedContainer.allKeys.forEach { domainKey in
                    let usersContainer = try nestedContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: domainKey)
                    allClients += try extractClientsFromContainer(usersContainer, domainKey.stringValue)
                }
            }

            clients = allClients
        }

        enum CodingKeys: String, CodingKey {
            case missing
        }
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            return nil
        }
    }
}

// MARK: - Message sending

private extension GenericMessageEntity {

    var isRejected: Bool {
        guard
            message.hasCalling else {
            return false
        }

        return message.calling.isRejected
    }
}

private extension Calling {

    var isRejected: Bool {
        guard
            let payload = content.data(using: .utf8, allowLossyConversion: false),
            let callContent = CallEventContent(from: payload)
        else {
            return false
        }

        return callContent.isRejected
    }
}

private extension AVSIdentifier {
    func toQualifiedId() -> QualifiedID {
        QualifiedID(uuid: identifier, domain: domain ?? BackendInfo.domain ?? "")
    }
}
