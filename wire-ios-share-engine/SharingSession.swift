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
    
    /// The `NSManagedObjectContext` used to retrieve the conversations,
    /// we only use a single context in the sharing session for now
    let managedObjectContext: NSManagedObjectContext

    /// The authentication status used to verify a user is authenticated
    private let authenticationStatus: AuthenticationStatusProvider
    
    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        return managedObjectContext.conversationListDirectory()
    }
    
    /// Whether all prerequsisties for sharing are met
    var canShare: Bool {
        return authenticationStatus.state == .authenticated
    }

    /// List of non-archived conversations in which the user can write
    /// The list will be sorted by relevance
    var writeableNonArchivedConversations : [Conversation] {
        return directory.unarchivedAndNotCallingConversations.conversationArray
    }
    
    /// List of archived conversations in which the user can write
    var writebleArchivedConversations : [Conversation] {
        return directory.archivedConversations.conversationArray
    }
    
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    init(databaseDirectory: URL, authenticationStatusProvider: AuthenticationStatusProvider) throws {
        sharedDatabaseDirectory = databaseDirectory
        authenticationStatus = authenticationStatusProvider
        
        guard !NSManagedObjectContext.needsToPrepareLocalStore(inDirectory: databaseDirectory) else { throw InitializationError.needsMigration }
        guard authenticationStatusProvider.state == .authenticated else { throw InitializationError.loggedOut }
        managedObjectContext = NSManagedObjectContext.createUserInterfaceContext(withStoreDirectory: databaseDirectory)
    }

    /// Cancel all pending tasks.
    /// Should be called when the extension is dismissed
    func cancelAllPendingTasks() {
        // TODO
    }

}

// MARK: - Helper

extension ZMConversationList {

    var conversationArray: [Conversation] {
        return self.flatMap { $0 as? Conversation }
    }

}
