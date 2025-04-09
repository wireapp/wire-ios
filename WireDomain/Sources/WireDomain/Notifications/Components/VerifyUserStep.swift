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
    var userID: UUID! { get }
    var applicationIdentifier: String { get }
    var applicationContainer: URL { get }
}

protocol VerifyUserStepFactory {
    func verifyUserSession(
        userID: UUID
    ) async throws
}

final class VerifyUserStep: Component<VerifyUserDependency>, VerifyUserStepFactory {
    
    enum Failure: Error {
        case noAccountFound
    }

    func verifyUserSession(
        userID: UUID
    ) async throws {
        let verifyUserSessionUseCase = VerifyUserSessionUseCase(
            userID: userID,
            cookieStorage: cookieStorage,
            coreData: coreData
        )
        
        try await verifyUserSessionUseCase.invoke()
        
        try await pullEventsStep.pullEvents()
    }

    // MARK: - Children

    var pullEventsStep: any PullEventsStepFactory {
        PullEventsStep(parent: self)
    }
}

extension VerifyUserStep {
    
    public var accountManager: AccountManager {
        AccountManager(
            sharedDirectory: dependency.applicationContainer
        )
    }
    
    public var selectedAccount: Account {
        accountManager.account(
            with: dependency.userID
        )!
    }

    public var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: dependency.applicationIdentifier)!
    }

    public var cookieStorage: any CookieStorageProtocol {
        makeCookieStorage(
            userID: dependency.userID
        )
    }

    public var coreData: CoreDataStack {
        shared {
            makeCoreData(
                account: selectedAccount,
                applicationIdentifier: dependency.applicationIdentifier
            )
        }
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
            if let key = sharedUserDefaults.data(forKey: cookieKey) {
                return key
            }

            // Creates a new key
            do {
                let newKey = try AES256Crypto.generateRandomEncryptionKey()
                sharedUserDefaults.set(newKey, forKey: cookieKey)
                return newKey
            } catch {
                fatal("Could not generate random encryption key: \(error.localizedDescription)")
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
