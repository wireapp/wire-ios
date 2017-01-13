//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import ZMCDataModel
import ZMTransport
import WireMessageStrategy


class PushMessageHandlerDummy : NSObject, ZMPushMessageHandler {
    
    func processGenericMessage(_ genericMessage: ZMGenericMessage!) {
        // nop
    }
    
    func processMessage(_ message: ZMMessage!) {
        // nop
    }
    
    func didFail(toSentMessage message: ZMMessage!) {
        // nop
    }
    
}

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
        if let clientId = context.persistentStoreMetadata(key: "PersistedClientId") as? String { // TODO move constant into shared framework
            return clientId.characters.count > 0
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

public enum SharingSessionError : Error {
    case missingSharedContainer
}

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of 
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public class SharingSession {
    
     /// The failure reason of a `SharingSession` initialization
     /// - NeedsMigration: The database needs a migration which is only done in the main app
     /// - LoggedOut:      No user is logged in
    enum InitializationError: Error {
        case needsMigration, loggedOut
    }
    
    /// The `NSManagedObjectContext` used to retrieve the conversations
    let userInterfaceContext: NSManagedObjectContext

    private let syncContext: NSManagedObjectContext

    /// The authentication status used to verify a user is authenticated
    private let authenticationStatus: AuthenticationStatusProvider
    
    /// The client registration status used to lookup if a user has registered a self client
    private let clientRegistrationStatus : ClientRegistrationDelegate

    /// The list to which touched conversations are added to in order to refresh them in the main app
    public let modifiedConversations: SharedModifiedConversationsList

    let transportSession: ZMTransportSession
    
    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        return userInterfaceContext.conversationListDirectory()
    }
    
    /// Whether all prerequsisties for sharing are met
    public var canShare: Bool {
        return authenticationStatus.state == .authenticated && clientRegistrationStatus.clientIsReadyForRequests
    }

    /// List of non-archived conversations in which the user can write
    /// The list will be sorted by relevance
    public var writeableNonArchivedConversations : [Conversation] {
        return directory.unarchivedAndNotCallingConversations.conversationArray
    }
    
    /// List of archived conversations in which the user can write
    public var writebleArchivedConversations : [Conversation] {
        return directory.archivedConversations.conversationArray
    }

    private let operationLoop: RequestGeneratingOperationLoop
        
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    
    public convenience init(applicationGroupIdentifier: String, hostBundleIdentifier: String) throws {
        
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw SharingSessionError.missingSharedContainer
        }
        
        let storeURL = sharedContainerURL.appendingPathComponent(hostBundleIdentifier, isDirectory: true).appendingPathComponent("store.wiredatabase")
        let keyStoreURL = sharedContainerURL
        
        guard !NSManagedObjectContext.needsToPrepareLocalStore(at: storeURL) else { throw InitializationError.needsMigration }
        
        ZMSLog.set(level: .debug, tag: "Network")

        let userInterfaceContext = NSManagedObjectContext.createUserInterfaceContextWithStore(at: storeURL)!
        let syncContext = NSManagedObjectContext.createSyncContextWithStore(at: storeURL, keyStore: keyStoreURL)!
        
        userInterfaceContext.zm_sync = syncContext
        syncContext.zm_userInterface = userInterfaceContext
        
        let environment = ZMBackendEnvironment(userDefaults: UserDefaults.shared())
        
        let transportSession =  ZMTransportSession(
            baseURL: environment.backendURL,
            websocketURL: environment.backendWSURL,
            mainGroupQueue: userInterfaceContext,
            initialAccessToken: ZMAccessToken(),
            application: nil,
            sharedContainerIdentifier: applicationGroupIdentifier
        )
        
        try self.init(userInterfaceContext: userInterfaceContext, syncContext: syncContext, transportSession: transportSession, sharedContainerURL: sharedContainerURL)
        
    }
    
    internal init(userInterfaceContext: NSManagedObjectContext,
                  syncContext: NSManagedObjectContext,
                  transportSession: ZMTransportSession,
                  sharedContainerURL: URL,
                  authenticationStatus: AuthenticationStatusProvider,
                  clientRegistrationStatus: ClientRegistrationStatus,
                  operationLoop: RequestGeneratingOperationLoop) throws {
        
        self.userInterfaceContext = userInterfaceContext
        self.syncContext = syncContext
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.operationLoop = operationLoop
        
        guard authenticationStatus.state == .authenticated else { throw InitializationError.loggedOut }
        
        setupCaches(atContainerURL: sharedContainerURL)
    }
    
    public convenience init(userInterfaceContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, transportSession: ZMTransportSession, sharedContainerURL: URL) throws {
        
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        
        let clientMessageTranscoder = ZMClientMessageTranscoder(
            managedObjectContext: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            clientRegistrationStatus: clientRegistrationStatus,
            apnsConfirmationStatus: DeliveryConfirmationDummy()
        )!
        
        let missingClientStrategy = MissingClientsRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, apnsConfirmationStatus: DeliveryConfirmationDummy(), managedObjectContext: syncContext)
        let imageUploadStrategy = ImageUploadRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, managedObjectContext: syncContext, maxConcurrentImageOperation: 1)
        let fileUploadStrategy = FileUploadRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, managedObjectContext: syncContext, taskCancellationProvider: transportSession)

        let requestGeneratorStore = RequestGeneratorStore(strategies: [missingClientStrategy, clientMessageTranscoder, imageUploadStrategy, fileUploadStrategy])

        let operationLoop = RequestGeneratingOperationLoop(
            userContext: userInterfaceContext,
            syncContext: syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        modifiedConversations = SharedModifiedConversationsList()
        
        try self.init(
            userInterfaceContext: userInterfaceContext,
            syncContext: syncContext,
            transportSession: transportSession,
            sharedContainerURL: sharedContainerURL,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: clientRegistrationStatus,
            operationLoop: operationLoop
        )
    }
    
    private func setupCaches(atContainerURL containerURL: URL) {
        let cachesURL = containerURL.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Caches", isDirectory: true)
        
        let userImageCache = UserImageLocalCache(location: cachesURL)
        userInterfaceContext.zm_userImageCache = userImageCache
        syncContext.zm_userImageCache = userImageCache
        
        let imageAssetCache = ImageAssetCache(MBLimit: 50, location: cachesURL)
        userInterfaceContext.zm_imageAssetCache = imageAssetCache
        syncContext.zm_imageAssetCache = imageAssetCache
        
        let fileAssetcache = FileAssetCache(location: cachesURL)
        userInterfaceContext.zm_fileAssetCache = fileAssetcache
        syncContext.zm_fileAssetCache = fileAssetcache
    }

    public func enqueue(changes: @escaping () -> Void) {
        enqueue(changes: changes, completionHandler: nil)
    }
    
    public func enqueue(changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        userInterfaceContext.performGroupedBlock { [weak self] in
            changes()
            
            self?.userInterfaceContext.saveOrRollback()
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }

}

// MARK: - Helper

extension ZMConversationList {

    var conversationArray: [Conversation] {
        return self.flatMap { $0 as? Conversation }
    }

}
