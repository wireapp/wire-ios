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
import WireAPI
import WireCrypto
import WireDataModel
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
        makeCookieStorage(
            userID: dependency.userID
        )
    }

    public var userLocalStore: any UserLocalStoreProtocol {
        UserLocalStore(
            context: coreData.syncContext,
            messageLocalStore: messageLocalStore
        )
    }

    public var messageLocalStore: any MessageLocalStoreProtocol {
        MessageLocalStore(
            context: coreData.syncContext
        )
    }

    public var coreData: CoreDataStack {
        makeCoreData(
            account: dependency.selectedAccount,
            applicationIdentifier: dependency.applicationIdentifier
        )
    }

    func makeCoreData(
        account: Account,
        applicationIdentifier: String
    ) -> CoreDataStack {
        let applicationContainer = makeApplicationContainer(
            applicationIdentifier: applicationIdentifier
        )

        return CoreDataStack(
            account: account,
            applicationContainer: applicationContainer
        )
    }

    func makeCookieStorage(userID: UUID) -> any CookieStorageProtocol {
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
            userID: userID,
            cookieEncryptionKey: cookiesEncryptionKey,
            keychain: makeKeychain()
        )
    }

    func makeApplicationContainer(applicationIdentifier: String) -> URL {
        FileManager.sharedContainerDirectory(for: applicationIdentifier)
    }

    func makeKeychain() -> any KeychainProtocol {
        Keychain()
    }
}
