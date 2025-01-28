//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import NeedleFoundation
import WireDataModel

protocol LocalStoreDependency: Dependency {
    var userIdentifier: UUID { get }
}

protocol UserClientsLocalStoreProvider {
    var userClientsLocalStore: any UserClientsLocalStoreProtocol { get }
}

protocol UpdateEventsLocalStoreProvider {
    var updateEventsLocalStore: any UpdateEventsLocalStoreProtocol { get }
}

/// Provides local stores.
final class LocalStoreComponent: Component<LocalStoreDependency>, UserClientsLocalStoreProvider,
    UpdateEventsLocalStoreProvider {
    private let context: NSManagedObjectContext

    init(parent: any Scope, context: NSManagedObjectContext) {
        self.context = context
        super.init(parent: parent)
    }

    var updateEventsLocalStore: UpdateEventsLocalStoreProtocol {
        UpdateEventsLocalStore(
            context: context,
            userID: dependency.userIdentifier,
            sharedUserDefaults: .standard
        )
    }

    var userLocalStore: UserLocalStoreProtocol {
        UserLocalStore(
            context: context,
            conversationLocalStore: conversationLocalStore
        )
    }

    var conversationLocalStore: ConversationLocalStoreProtocol {
        ConversationLocalStore(
            context: context,
            mlsService: context.mlsService!,
            messageLocalStore: messageLocalStore
        )
    }

    var userClientsLocalStore: any UserClientsLocalStoreProtocol {
        UserClientsLocalStore(context: context)
    }

    var messageLocalStore: any MessageLocalStoreProtocol {
        MessageLocalStore(context: context)
    }

}
