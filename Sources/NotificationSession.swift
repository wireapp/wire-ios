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
    
    public var pushNotificationStatus: PushNotificationStatus

    public init(managedObjectContext: NSManagedObjectContext,
                transportSession: ZMTransportSession,
                authenticationStatus: AuthenticationStatusProvider,
                clientRegistrationStatus: ClientRegistrationStatus,
                linkPreviewDetector: LinkPreviewDetectorType) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
        self.pushNotificationStatus = PushNotificationStatus(managedObjectContext: managedObjectContext)
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
        // we don't do slow syncing in the notification engine
    }

}

/// A syncing layer for the notification processing
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the notification extension, and hold on to that session
/// for the entire lifetime.
public class NotificationSession {

    /// Directory of all application statuses
    private let applicationStatusDirectory : ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persistet
    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence
    private var contextSaveObserverToken: NSObjectProtocol?
    private let transportSession: ZMTransportSession
    private let coreDataStack: CoreDataStack
    private let operationLoop: RequestGeneratingOperationLoop
    private let strategyFactory: StrategyFactory
        
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    
    public convenience init(applicationGroupIdentifier: String,
                            accountIdentifier: UUID,
                            environment: BackendEnvironmentProvider,
                            analytics: AnalyticsType?,
                            delegate: NotificationSessionDelegate?,
                            useLegacyPushNotifications: Bool) throws {
       
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)

        let account = Account(userName: "", userIdentifier: accountIdentifier)
        let coreDataStack = CoreDataStack(account: account,
                                          applicationContainer: sharedContainerURL)

        coreDataStack.loadStores { error in
            // TODO jacob error handling
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
            applicationGroupIdentifier: applicationGroupIdentifier,
            applicationVersion: "1.0.0"
        )
        
        try self.init(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL),
            analytics: analytics,
            delegate: delegate,
            useLegacyPushNotifications: useLegacyPushNotifications
        )
    }
    
    internal init(coreDataStack: CoreDataStack,
                  transportSession: ZMTransportSession,
                  cachesDirectory: URL,
                  saveNotificationPersistence: ContextDidSaveNotificationPersistence,
                  applicationStatusDirectory: ApplicationStatusDirectory,
                  operationLoop: RequestGeneratingOperationLoop,
                  strategyFactory: StrategyFactory) throws {
        
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory
    }
    
    public convenience init(coreDataStack: CoreDataStack,
                            transportSession: ZMTransportSession,
                            cachesDirectory: URL,
                            accountContainer: URL,
                            analytics: AnalyticsType?,
                            delegate: NotificationSessionDelegate?,
                            useLegacyPushNotifications: Bool) throws {
        
        let applicationStatusDirectory = ApplicationStatusDirectory(syncContext: coreDataStack.syncContext,
                                                                    transportSession: transportSession)
        let notificationsTracker = (analytics != nil) ? NotificationsTracker(analytics: analytics!) : nil
        let strategyFactory = StrategyFactory(contextProvider: coreDataStack,
                                              applicationStatus: applicationStatusDirectory,
                                              pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
                                              notificationsTracker: notificationsTracker,
                                              notificationSessionDelegate: delegate,
                                              useLegacyPushNotifications: useLegacyPushNotifications)
        
        let requestGeneratorStore = RequestGeneratorStore(strategies: strategyFactory.strategies)
        
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        
        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        
        try self.init(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory
        )
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
    
    public func processPushNotification(with payload: [AnyHashable: Any], completion: @escaping (Bool) -> Void) {
        Logging.network.debug("Received push notification with payload: \(payload)")

        coreDataStack.syncContext.performGroupedBlock {
            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
                Logging.push.safePublic("Not displaying notification because app is not authenticated")
                completion(false)
                return
            }
            
            ////TODO katerina: update the badge count
            // once notification processing is finished, it's safe to update the badge
            let completionHandler = {
                completion(true)
//                let unreadCount = Int(ZMConversation.unreadConversationCount(in: self.syncManagedObjectContext))
//                self.sessionManager?.updateAppIconBadge(accountID: accountID, unreadCount: unreadCount)
            }
            
            self.fetchEvents(fromPushChannelPayload: payload, completionHandler: completionHandler)
        }
    }
    
    func fetchEvents(fromPushChannelPayload payload: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard let nonce = self.messageNonce(fromPushChannelData: payload) else {
            return completionHandler()
        }
        self.applicationStatusDirectory.pushNotificationStatus.fetch(eventId: nonce, completionHandler: {
            
            ////TODO katerina: check callEventStatus
            completionHandler()
        })
    }
    
    ////TODO: need to verify with the BE response
    private func messageNonce(fromPushChannelData payload: [AnyHashable : Any]) -> UUID? {
        guard let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable : Any],
            let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable : Any],
            let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String else {
                return nil
        }
        return UUID(uuidString: rawUUID)
    }
    
    private enum PushChannelKeys: String {
        case data = "data"
        case identifier = "id"
    }
}
