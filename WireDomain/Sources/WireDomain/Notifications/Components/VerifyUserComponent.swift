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
    var userLocalStore: any UserLocalStoreProtocol {
        UserLocalStore(
            context: coreData.syncContext,
            conversationLocalStore: <#T##any ConversationLocalStoreProtocol#>
        )
    }
    
    public var cookieStorage: any CookieStorageProtocol {
        let cookiesEncryptionKey: Data = {
            let cookieKey = "ZMCookieKey"
            let sharedDefaults = UserDefaults.standard
            if let key = sharedDefaults.data(forKey: "cookieKeyKey") {
                return key
            }

            // Creates a new key
            do {
                let newKey = try AES256Crypto.generateRandomEncryptionKey()
                sharedDefaults.set(newKey, forKey: cookieKey)
                return newKey
            } catch {
                fatalError()
            }
        }()
        
        return CookieStorage(
            userID: dependency.userID,
            cookieEncryptionKey: cookiesEncryptionKey,
            keychain: keychain
        )
    }
    
    var keychain: any KeychainProtocol {
        Keychain()
    }
    
    public var applicationIdentifier: String {
        let infoDictionary = Bundle.main.infoDictionary
        guard let appGroupID = infoDictionary?["WireGroupId"] as? String else {
            fatalError() // TODO: Jullian
        }
        
        return "group.\(appGroupID)"
    }
    
    public var applicationContainer: URL {
        FileManager.sharedContainerDirectory(for: applicationIdentifier)
    }
    
    public var selectedAccount: Account {
        let accountManager = AccountManager(sharedDirectory: applicationContainer)
        
        guard let selectedAccount = accountManager.account(
            with: dependency.userID
        ) else {
            fatalError() // TODO: Jullian
        }
        
        return selectedAccount
    }
    
    var coreData: CoreDataStack {
        CoreDataStack(
            account: selectedAccount,
            applicationContainer: applicationContainer
        )
    }
}
