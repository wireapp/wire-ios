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


class ClientRegistrationDummy : NSObject, ClientRegistrationDelegate {
    
    var clientIsReadyForRequests: Bool {
        return true
    }
    
    func didDetectCurrentClientDeletion() {
        // nop
    }
}


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

extension NSManagedObjectContext : ZMKeyValueStore {
    
    open override func setValue(_ value: Any?, forKey key: String) {
        setPersistentStoreMetadata(value, forKey: key)
    }
    
    open override func value(forKey key: String) -> Any? {
        return persistentStoreMetadata(forKey: key)
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
    
    /// The location of the database in the shared container
    let sharedDatabaseDirectory: URL
    
    /// The `NSManagedObjectContext` used to retrieve the conversations
    let userInterfaceContext: NSManagedObjectContext

    private let syncContext: NSManagedObjectContext

    /// The authentication status used to verify a user is authenticated
    private let authenticationStatus: AuthenticationStatusProvider

    let transportSession: ZMTransportSession
    
    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        return userInterfaceContext.conversationListDirectory()
    }
    
    /// Whether all prerequsisties for sharing are met
    public var canShare: Bool {
        return authenticationStatus.state == .authenticated
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
    
    public convenience init(applicationGroupIdentifier: String, hostBundleIdentifier: String) throws {
        guard let databaseDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw SharingSessionError.missingSharedContainer
        }
        
        try self.init(databaseDirectory: databaseDirectory, databaseIdentifier: hostBundleIdentifier, authenticationStatusProvider: DummyAuthenticationStatus())
    }
    
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    init(databaseDirectory: URL, databaseIdentifier: String, authenticationStatusProvider: AuthenticationStatusProvider) throws {
        sharedDatabaseDirectory = databaseDirectory
        authenticationStatus = authenticationStatusProvider

        guard !NSManagedObjectContext.needsToPrepareLocalStore(inDirectory: databaseDirectory, identifier: databaseIdentifier) else { throw InitializationError.needsMigration }
        guard authenticationStatusProvider.state == .authenticated else { throw InitializationError.loggedOut }
        userInterfaceContext = NSManagedObjectContext.createUserInterfaceContext(withStoreDirectory: databaseDirectory, storeIdentifier: databaseIdentifier)
        syncContext = NSManagedObjectContext.createSyncContext(withStoreDirectory: databaseDirectory, storeIdentifier: databaseIdentifier)

        let environment = ZMBackendEnvironment()
        
        transportSession = ZMTransportSession(
            baseURL: environment.backendURL,
            websocketURL: environment.backendWSURL,
            keyValueStore: syncContext,
            mainGroupQueue: userInterfaceContext,
            application: nil
        )

        let clientMessageTranscoder = ZMClientMessageTranscoder(
            managedObjectContext: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            clientRegistrationStatus: ClientRegistrationDummy(),
            apnsConfirmationStatus: DeliveryConfirmationDummy()
        )!

        let transcoders = [clientMessageTranscoder]
        let requestGeneratorStore = RequestGeneratorStore(strategies: transcoders)

        operationLoop = RequestGeneratingOperationLoop(
            userContext: userInterfaceContext,
            syncContext: syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
    }

    /// Cancel all pending tasks.
    /// Should be called when the extension is dismissed
    public func cancelAllPendingTasks() {
        // TODO

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
