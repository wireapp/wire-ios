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

import Foundation

// MARK: - ConversationListType

public enum ConversationListType {
    case archived
    case unarchived
    case pending
    case contacts
    case groups
    case favorites
    case folder(_ folder: LabelType)
}

// MARK: - ConversationDirectoryChangeInfo

public struct ConversationDirectoryChangeInfo {
    // MARK: Lifecycle

    public init(reloaded: Bool, updatedLists: [ConversationListType], updatedFolders: Bool) {
        self.reloaded = reloaded
        self.updatedLists = updatedLists
        self.updatedFolders = updatedFolders
    }

    // MARK: Public

    public var reloaded: Bool
    public var updatedLists: [ConversationListType]
    public var updatedFolders: Bool
}

// MARK: - ConversationDirectoryObserver

public protocol ConversationDirectoryObserver: AnyObject {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo)
}

// MARK: - ConversationDirectoryType

public protocol ConversationDirectoryType {
    /// All folder created by the user
    var allFolders: [LabelType] { get }

    /// Create a new folder with a given name
    func createFolder(_ name: String) -> LabelType?

    /// Retrieve a conversation list by a given type
    func conversations(by: ConversationListType) -> [ZMConversation]

    /// Observe changes to the conversation lists & folders
    ///
    /// NOTE that returned token must be retained for as long you want the observer to be active
    func addObserver(_ observer: ConversationDirectoryObserver) -> Any
}

// MARK: - ZMConversationListDirectory + ConversationDirectoryType

extension ZMConversationListDirectory: ConversationDirectoryType {
    public func conversations(by type: ConversationListType) -> [ZMConversation] {
        switch type {
        case .archived:
            return archivedConversations.items
        case .unarchived:
            return unarchivedConversations.items
        case .pending:
            return pendingConnectionConversations.items
        case .contacts:
            return oneToOneConversations.items
        case .groups:
            return groupConversations.items
        case .favorites:
            return favoriteConversations.items
        case let .folder(label):
            guard let objectID = (label as? Label)?.objectID else {
                return []
            } // TODO: jacob make optional?
            return (listsByFolder[objectID] as? ConversationList)?.items ?? []
        }
    }

    public func addObserver(_ observer: ConversationDirectoryObserver) -> Any {
        let observerProxy = ConversationListObserverProxy(observer: observer, directory: self)
        let listToken = ConversationListChangeInfo.addListObserver(
            observerProxy,
            for: nil,
            managedObjectContext: managedObjectContext
        )
        let reloadToken = ConversationListChangeInfo.addReloadObserver(
            observerProxy,
            managedObjectContext: managedObjectContext
        )
        let folderToken = ConversationListChangeInfo.addFolderObserver(
            observerProxy,
            managedObjectContext: managedObjectContext
        )

        return [folderToken, listToken, reloadToken, observerProxy]
    }

    @objc
    public func createFolder(_ name: String) -> LabelType? {
        var created = false
        let label = Label.fetchOrCreate(
            remoteIdentifier: UUID(),
            create: true,
            in: managedObjectContext,
            created: &created
        )
        label?.name = name
        label?.kind = .folder
        return label
    }
}

// MARK: - ConversationListObserverProxy

private class ConversationListObserverProxy: NSObject, ZMConversationListObserver, ZMConversationListReloadObserver,
    ZMConversationListFolderObserver {
    // MARK: Lifecycle

    init(observer: ConversationDirectoryObserver, directory: ZMConversationListDirectory) {
        self.observer = observer
        self.directory = directory
    }

    // MARK: Internal

    weak var observer: ConversationDirectoryObserver?
    var directory: ZMConversationListDirectory

    func conversationListsDidReload() {
        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [],
            updatedFolders: false
        ))
    }

    func conversationListsDidChangeFolders() {
        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(
            reloaded: false,
            updatedLists: [],
            updatedFolders: true
        ))
    }

    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        let updatedLists: [ConversationListType] = if changeInfo.conversationList === directory.oneToOneConversations {
            [.contacts]
        } else if changeInfo.conversationList === directory.groupConversations {
            [.groups]
        } else if changeInfo.conversationList === directory.archivedConversations {
            [.archived]
        } else if changeInfo.conversationList === directory.pendingConnectionConversations {
            [.pending]
        } else if changeInfo.conversationList === directory.unarchivedConversations {
            [.unarchived]
        } else if changeInfo.conversationList === directory.favoriteConversations {
            [.favorites]
        } else if let label = changeInfo.conversationList.label, label.kind == .folder {
            [.folder(label)]
        } else {
            []
        }

        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(
            reloaded: false,
            updatedLists: updatedLists,
            updatedFolders: false
        ))
    }
}
