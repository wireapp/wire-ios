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
import UserNotifications
import WireDataModel
import WireAPI
import WireCrypto
import WireFoundation

protocol VerifyUserDependency: Dependency {
    var userID: UUID { get }
    var selectedAccount: Account { get }
    var applicationIdentifier: String { get }
}

final class VerifyUserComponent: Component<VerifyUserDependency> {
    
    var verifyUserSession: VerifyUserSession {
        VerifyUserSession(
            pullEventsServiceProvider: pullEventsComponent,
            userLocalStore: userLocalStore,
            cookieStorage: cookieStorage
        )
    }
    
    // MARK: - Children
    
    var pullEventsComponent: PullEventsComponent {
        PullEventsComponent(parent: self)
    }
}

extension VerifyUserComponent {
    
    public var cookieStorage: any CookieStorageProtocol {
        CoreStorageFactory.makeCookieStorage(
            userID: dependency.userID
        )
    }
    
    public var userLocalStore: any UserLocalStoreProtocol {
        UserLocalStore(
            context: coreData.syncContext,
            conversationLocalStore: conversationLocalStore
        )
    }
    
    public var conversationLocalStore: any ConversationLocalStoreProtocol {
        ConversationLocalStore(
            context: coreData.syncContext,
            mlsService: nil,
            messageLocalStore: messageLocalStore
        )
    }
    
    public var messageLocalStore: any MessageLocalStoreProtocol {
        MessageLocalStore(
            context: coreData.syncContext
        )
    }
    
    public var coreData: CoreDataStack {
        CoreStorageFactory.makeCoreData(
            account: dependency.selectedAccount,
            applicationIdentifier: dependency.applicationIdentifier
        )
    }
}
