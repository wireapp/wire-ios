//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireTransport
import WireRequestStrategy
import WireLinkPreview


let PushChannelUserIDKey = "user"
let PushChannelDataKey = "data"

////TODO katerina: move to the request strategy
extension Dictionary {
    
    internal func accountId() -> UUID? {
        guard let userInfoData = self[PushChannelDataKey as! Key] as? [String: Any] else {
            Logging.push.safePublic("No data dictionary in notification userInfo payload");
            return nil
        }
    
        guard let userIdString = userInfoData[PushChannelUserIDKey] as? String else {
            return nil
        }
    
        return UUID(uuidString: userIdString)
    }
}

class ClientRegistrationStatus : NSObject, ClientRegistrationDelegate {
    
    let context : NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    var clientIsReadyForRequests: Bool {
        if let clientId = context.persistentStoreMetadata(forKey: "PersistedClientId") as? String { // TODO move constant into shared framework
            return !clientId.isEmpty
        }
        
        return false
    }
    
    func didDetectCurrentClientDeletion() {
        // nop
    }
}

class AuthenticationStatus : AuthenticationStatusProvider {
    
    let transportSession : ZMTransportSession
    
    init(transportSession: ZMTransportSession) {
        self.transportSession = transportSession
    }
    
    var state: AuthenticationState {
        return isLoggedIn ? .authenticated : .unauthenticated
    }
    
    private var isLoggedIn : Bool {
        return transportSession.cookieStorage.authenticationCookieData != nil
    }
    
}

extension BackendEnvironmentProvider {
    func cookieStorage(for account: Account) -> ZMPersistentCookieStorage {
        let backendURL = self.backendURL.host!
        return ZMPersistentCookieStorage(forServerName: backendURL, userIdentifier: account.userIdentifier)
    }
    
    public func isAuthenticated(_ account: Account) -> Bool {
        return cookieStorage(for: account).authenticationCookieData != nil
    }
}

class ApplicationStatusDirectory : ApplicationStatus {

    let transportSession : ZMTransportSession

    /// The authentication status used to verify a user is authenticated
    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client
    public let clientRegistrationStatus : ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public init(managedObjectContext: NSManagedObjectContext, transportSession: ZMTransportSession, authenticationStatus: AuthenticationStatusProvider, clientRegistrationStatus: ClientRegistrationStatus, linkPreviewDetector: LinkPreviewDetectorType/*, syncStateDelegate: ZMSyncStateDelegate*/) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
    }

    public convenience init(syncContext: NSManagedObjectContext, transportSession: ZMTransportSession) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()
        self.init(managedObjectContext: syncContext,transportSession: transportSession, authenticationStatus: authenticationStatus, clientRegistrationStatus: clientRegistrationStatus, linkPreviewDetector: linkPreviewDetector)
    }

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            return .online
        } else {
            return .unauthenticated
        }
    }

    public var operationState: OperationState {
        return .background
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return self.clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        return transportSession
    }

    func requestSlowSync() {
        // we don't do slow syncing in the share engine
    }

}

/// A syncing layer for the notification processing
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the notification extension, and hold on to that session
/// for the entire lifetime.
public class NotificationSession {
    
    fileprivate enum PushChannelKeys: String {
        case data = "data"
        case identifier = "id"
        case notificationType = "type"
    }

    fileprivate enum PushNotificationType: String {
        case plain = "plain"
        case cipher = "cipher"
        case notice = "notice"
    }

    /// The `NSManagedObjectContext` used to retrieve the conversations
    var userInterfaceContext: NSManagedObjectContext {
        return contextDirectory.uiContext
    }

    private var syncContext: NSManagedObjectContext {
        return contextDirectory.syncContext
    }

    /// Directory of all application statuses
    private let applicationStatusDirectory : ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persistet
    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    private var contextSaveObserverToken: NSObjectProtocol?

    let transportSession: ZMTransportSession
    
    private var contextDirectory: ManagedObjectContextDirectory!
        
    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        return userInterfaceContext.conversationListDirectory()
    }
    
    private let operationLoop: RequestGeneratingOperationLoop

    private let strategyFactory: StrategyFactory
    
    private var pushNotificationStatus: PushNotificationStatus
        
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    
    public convenience init?(payload: UNMutableNotificationContent,
                             applicationGroupIdentifier: String,
                             environment: BackendEnvironmentProvider,
                             analytics: AnalyticsType?, //TODO: it's always nil now
                             delegate: NotificationSessionDelegate?
    ) throws {
       
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        
        guard let accountIdentifier = payload.userInfo.accountId() else {
            return nil
        }
        
        let group = DispatchGroup()
        
        var directory: ManagedObjectContextDirectory!
        group.enter()
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountIdentifier,
            applicationContainer: sharedContainerURL,
            startedMigrationCallback: {  },
            completionHandler: { contextDirectory in
                directory = contextDirectory
                group.leave()
            }
        )
        
        var didCreateStorageStack = false
        group.notify(queue: .global()) {
            didCreateStorageStack = true
        }
        
        while !didCreateStorageStack {
            if !RunLoop.current.run(mode: RunLoop.Mode.default, before: Date(timeIntervalSinceNow: 0.002)) {
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
        
        let cookieStorage = ZMPersistentCookieStorage(forServerName: environment.backendURL.host!, userIdentifier: accountIdentifier)
        let reachabilityGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Sharing session reachability")!
        let serverNames = [environment.backendURL, environment.backendWSURL].compactMap { $0.host }
        let reachability = ZMReachability(serverNames: serverNames, group: reachabilityGroup)
        
        let transportSession =  ZMTransportSession(
            environment: environment,
            cookieStorage: cookieStorage,
            reachability: reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: applicationGroupIdentifier
        )
        
        try self.init(
            contextDirectory: directory,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL),
            analytics: analytics,
            delegate: delegate,
            sharedContainerURL: sharedContainerURL,
            accountIdentifier: accountIdentifier,
            payload: payload
        )
    }
    
    internal init(contextDirectory: ManagedObjectContextDirectory,
                  transportSession: ZMTransportSession,
                  cachesDirectory: URL,
                  saveNotificationPersistence: ContextDidSaveNotificationPersistence,
                  applicationStatusDirectory: ApplicationStatusDirectory,
                  operationLoop: RequestGeneratingOperationLoop,
                  strategyFactory: StrategyFactory,
                  pushNotificationStatus: PushNotificationStatus
        ) throws {
        
        self.contextDirectory = contextDirectory
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory
        self.pushNotificationStatus = pushNotificationStatus
        
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }
    
    public convenience init(contextDirectory: ManagedObjectContextDirectory,
                            transportSession: ZMTransportSession,
                            cachesDirectory: URL,
                            accountContainer: URL,
                            analytics: AnalyticsType?,
                            delegate: NotificationSessionDelegate?,
                            sharedContainerURL: URL,
                            accountIdentifier: UUID,
                            payload: UNMutableNotificationContent) throws {
        
        let applicationStatusDirectory = ApplicationStatusDirectory(syncContext: contextDirectory.syncContext, transportSession: transportSession)
        let pushNotificationStatus = PushNotificationStatus(managedObjectContext: contextDirectory.syncContext)
        
        let notificationsTracker = (analytics != nil) ? NotificationsTracker(analytics: analytics!) : nil
        let strategyFactory = StrategyFactory(syncContext: contextDirectory.syncContext,
                                              applicationStatus: applicationStatusDirectory,
                                              pushNotificationStatus: pushNotificationStatus,
                                              notificationsTracker: notificationsTracker,
                                              notificationSessionDelegate: delegate,
                                              sharedContainerURL: sharedContainerURL,
                                              accountIdentifier: accountIdentifier)
        
        let requestGeneratorStore = RequestGeneratorStore(strategies: strategyFactory.strategies)
        
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: contextDirectory.uiContext,
            syncContext: contextDirectory.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        
        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        
        try self.init(
            contextDirectory: contextDirectory,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            pushNotificationStatus: pushNotificationStatus
        )
        
        self.receivedPushNotification(with: payload.userInfo) {
            Logging.push.safePublic("Processing push payload completed")
            //self?.notificationsTracker?.registerNotificationProcessingCompleted()
        }
    }

    deinit {
        if let token = contextSaveObserverToken {
            NotificationCenter.default.removeObserver(token)
            contextSaveObserverToken = nil
        }
        transportSession.reachability.tearDown()
        transportSession.tearDown()
        strategyFactory.tearDown()
    }
    
    private func receivedPushNotification(with payload: [AnyHashable: Any], completion: @escaping () -> Void) {
        Logging.network.debug("Received push notification with payload: \(payload)")
                
        syncContext.performGroupedBlock {
            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
                Logging.push.safePublic("Not displaying notification because app is not authenticated")
                completion()
                return
            }
            
            ////TODO katerina: update the badge count
            // once notification processing is finished, it's safe to update the badge
            let completionHandler = {
                completion()
//                let unreadCount = Int(ZMConversation.unreadConversationCount(in: self.syncManagedObjectContext))
//                self.sessionManager?.updateAppIconBadge(accountID: accountID, unreadCount: unreadCount)
            }
            
            self.fetchEvents(fromPushChannelPayload: payload, completionHandler: completionHandler)
        }
    }
    
    func fetchEvents(fromPushChannelPayload payload: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        syncContext.performGroupedBlock {
            guard let nonce = self.messageNonce(fromPushChannelData: payload) else {
                return completionHandler()
            }
            self.pushNotificationStatus.fetch(eventId: nonce, completionHandler: {
                
                 ////TODO katerina: ?
//                 self.callEventStatus.waitForCallEventProcessingToComplete { [weak self] in
//                    guard let strongSelf = self else { return }
//                    strongSelf.syncMOC.performGroupedBlock {
                        completionHandler()
//                    }
//                }
            })
        }
    }
    
    private func messageNonce(fromPushChannelData payload: [AnyHashable : Any]) -> UUID? {
        guard let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable : Any],
              let rawNotificationType = notificationData[PushChannelKeys.notificationType.rawValue] as? String,
              let notificationType = PushNotificationType(rawValue: rawNotificationType) else {
            return nil
        }
        
        switch notificationType {
        case .plain, .notice:
            if let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable : Any], let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String {
                return UUID(uuidString: rawUUID)
            }
        case .cipher:
            return messageNonce(fromEncryptedPushChannelData: notificationData)
        }
        
        return nil
    }
    
    private var apsSignalKeyStore: APSSignalingKeysStore? {
        let selfUser = ZMUser.selfUser(in: syncContext)
        guard let selfClient = selfUser.selfClient() else {
            return nil
        }
        return APSSignalingKeysStore.init(userClient: selfClient)
    }
    
    private func messageNonce(fromEncryptedPushChannelData encryptedPayload: [AnyHashable : Any]) -> UUID? {
        //    @"aps" : @{ @"alert": @{@"loc-args": @[],
        //                          @"loc-key"   : @"push.notification.new_message"}
        //              },
        //    @"data": @{ @"data" : @"SomeEncryptedBase64EncodedString",
        //                @"mac"  : @"someMacHashToVerifyTheIntegrityOfTheEncodedPayload",
        //                @"type" : @"cipher"
        //
        
        guard let apsSignalKeyStore = apsSignalKeyStore else {
            Logging.network.debug("Could not initiate APSSignalingKeystore")
            return nil
        }
        
        guard let decryptedPayload = apsSignalKeyStore.decryptDataDictionary(encryptedPayload) else {
            Logging.network.debug("Failed to decrypt data dictionary from push payload: \(encryptedPayload)")
            return nil
        }
        
        if let data = decryptedPayload[PushChannelKeys.data.rawValue] as? [AnyHashable : Any], let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String {
            return UUID(uuidString: rawUUID)
        }
        
        return nil
    }
}


