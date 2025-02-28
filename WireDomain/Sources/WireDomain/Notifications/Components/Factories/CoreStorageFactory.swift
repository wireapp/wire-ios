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

import Foundation
import WireDataModel
import WireAPI
import WireCrypto
import WireFoundation

struct CoreStorageFactory {
    
    private init() {}
    
    static func makeCoreData(
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
    
    static func makeCookieStorage(userID: UUID) -> any CookieStorageProtocol {
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
    
    private static func makeApplicationContainer(applicationIdentifier: String) -> URL {
        FileManager.sharedContainerDirectory(for: applicationIdentifier)
    }
    
    private static func makeKeychain() -> any KeychainProtocol {
        Keychain()
    }
}
