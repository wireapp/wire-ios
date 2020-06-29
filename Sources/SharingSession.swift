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

//class PushMessageHandlerDummy : NSObject, PushMessageHandler {
//
//    func process(_ message: ZMMessage) {
//        // nop
//    }
//
//    public func process(_ event: ZMUpdateEvent) {
//        // nop
//    }
//
//    func didFailToSend(_ message: ZMMessage) {
//        // nop
//    }
//
//}

class DeliveryConfirmationDummy : NSObject, DeliveryConfirmationDelegate {

    static var sendDeliveryReceipts: Bool {
        return false
    }

    var needsToSyncMessages: Bool {
        return false
    }

    func needsToConfirmMessage(_ messageNonce: UUID) {
        // nop
    }

    func didConfirmMessage(_ messageNonce: UUID) {
        // nop
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
    let deliveryConfirmationDummy : DeliveryConfirmationDummy

    /// The authentication status used to verify a user is authenticated
    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client
    public let clientRegistrationStatus : ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public init(transportSession: ZMTransportSession, authenticationStatus: AuthenticationStatusProvider, clientRegistrationStatus: ClientRegistrationStatus, linkPreviewDetector: LinkPreviewDetectorType) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.deliveryConfirmationDummy = DeliveryConfirmationDummy()
        self.linkPreviewDetector = linkPreviewDetector
    }

    public convenience init(syncContext: NSManagedObjectContext, transportSession: ZMTransportSession) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()
        self.init(transportSession: transportSession, authenticationStatus: authenticationStatus, clientRegistrationStatus: clientRegistrationStatus, linkPreviewDetector: linkPreviewDetector)
    }

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            return .eventProcessing
        } else {
            return .unauthenticated
        }
    }

    public var operationState: OperationState {
        return .background
    }

    public let notificationFetchStatus: BackgroundNotificationFetchStatus = .done

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return self.clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        return transportSession
    }

    public var deliveryConfirmation: DeliveryConfirmationDelegate {
        return deliveryConfirmationDummy
    }

    func requestSlowSync() {
        // we don't do slow syncing in the share engine
    }

}

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public class SharingSession {
    
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
        
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    
    public convenience init(applicationGroupIdentifier: String,
                            accountIdentifier: UUID,
//                            hostBundleIdentifier: String,
                            environment: BackendEnvironmentProvider,
                            analytics: AnalyticsType?,
                            eventProcessor: UpdateEventProcessor
    ) throws {
        
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        
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
            eventProcessor: eventProcessor
        )
    }
    
    internal init(contextDirectory: ManagedObjectContextDirectory,
                  transportSession: ZMTransportSession,
                  cachesDirectory: URL,
                  saveNotificationPersistence: ContextDidSaveNotificationPersistence,
                  applicationStatusDirectory: ApplicationStatusDirectory,
                  operationLoop: RequestGeneratingOperationLoop,
                  strategyFactory: StrategyFactory
        ) throws {
        
        self.contextDirectory = contextDirectory
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory
        
//        setupObservers()
    }
    
    public convenience init(contextDirectory: ManagedObjectContextDirectory,
                            transportSession: ZMTransportSession,
                            cachesDirectory: URL,
                            accountContainer: URL,
                            analytics: AnalyticsType?,
                            eventProcessor: UpdateEventProcessor) throws {
        
        let applicationStatusDirectory = ApplicationStatusDirectory(syncContext: contextDirectory.syncContext, transportSession: transportSession)
        let pushNotificationStatus = PushNotificationStatus(managedObjectContext: contextDirectory.syncContext)

        let notificationsTracker = (analytics != nil) ? NotificationsTracker(analytics: analytics!) : nil
        let strategyFactory = StrategyFactory(syncContext: contextDirectory.uiContext,
                                              applicationStatus: applicationStatusDirectory,
                                              pushNotificationStatus: pushNotificationStatus,
                                              eventProcessor: eventProcessor,
                                              notificationsTracker: notificationsTracker)
        
        let requestGeneratorStore = RequestGeneratorStore(strategies: strategyFactory.strategies)
        
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: contextDirectory.uiContext,
            syncContext: contextDirectory.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        print("<<< OperationLoop was created \(operationLoop)")
//        let test = strategyFactory.strategies[0] as! PushNotificationStrategy).sync.listPaginator!
//        (strategyFactory.strategies[0] as! PushNotificationStrategy).sync.listPaginator!.didReceive(<#T##response: ZMTransportResponse!##ZMTransportResponse!#>, forSingleRequest: test.)
        
        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        
        try self.init(
            contextDirectory: contextDirectory,
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

//    private func setupObservers() {
//        contextSaveObserverToken = NotificationCenter.default.addObserver(
//            forName: contextWasMergedNotification,
//            object: nil,
//            queue: .main,
//            using: { [weak self] note in
//                self?.saveNotificationPersistence.add(note)
//                DarwinNotification.shareExtDidSaveNote.post()
//            }
//        )
//    }
}
