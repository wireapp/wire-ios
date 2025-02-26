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
import WireAPI
import WireCrypto
import WireDataModel
import WireFoundation
import WireLogging

protocol CoreStorageDependency: Dependency {
    var selectedAccount: Account { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
    var userIdentifier: UUID { get }
}

protocol CookieStorageProvider {
    var cookieStorage: any CookieStorageProtocol { get }
}

protocol CoreDataProvider {
    var coreData: CoreDataStack { get }
}

/// Provides core storage objects.
final class CoreStorageComponent: Component<CoreStorageDependency>, CookieStorageProvider, CoreDataProvider {

    var coreData: CoreDataStack {
        CoreDataStack(
            account: dependency.selectedAccount,
            applicationContainer: dependency.applicationContainer
        )
    }

    var cookieStorage: any CookieStorageProtocol {
        CookieStorage(
            userID: dependency.userIdentifier,
            cookieEncryptionKey: cookiesEncryptionKey,
            keychain: keychain
        )
    }

    var userDefaults: UserDefaults {
        let userDefaults = UserDefaults.standard
        userDefaults.addSuite(named: dependency.applicationIdentifier)
        return userDefaults
    }

    // MARK: - Private

    private var keychain: any KeychainProtocol {
        Keychain()
    }

    private var cookiesEncryptionKey: Data {
        let cookieKey = "ZMCookieKey"
        let sharedDefaults = UserDefaults.standard
        if let key = sharedDefaults.data(forKey: "cookieKeyKey") {
            return key
        }

        // Create a new key
        do {
            let newKey = try AES256Crypto.generateRandomEncryptionKey()
            sharedDefaults.set(newKey, forKey: cookieKey)
            return newKey
        } catch {
            fatalError()
        }
    }

}
