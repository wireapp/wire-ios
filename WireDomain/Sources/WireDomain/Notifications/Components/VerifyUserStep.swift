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
    var applicationIdentifier: String { get }
    var applicationContainer: URL { get }
}

protocol VerifyUserStepProtocol {
    func verifyUserSession() async throws
}

final class VerifyUserStep: Component<VerifyUserDependency>, VerifyUserStepProtocol {

    enum Failure: Error {
        case noAccountFound
    }

    public var selectedAccount: Account
    public var accountManager: AccountManager
    public var userID: UUID

    init(
        parent: any Scope,
        userID: UUID,
        accountManager: AccountManager
    ) throws {
        self.userID = userID
        self.accountManager = accountManager

        guard let selectedAccount = accountManager.account(
            with: userID
        ) else {
            throw Failure.noAccountFound
        }

        self.selectedAccount = selectedAccount

        super.init(parent: parent)
    }

    func verifyUserSession() async throws {
        let verifyUserSessionUseCase = VerifyUserSessionUseCase(
            cookieStorage: cookieStorage,
            coreData: coreData
        )

        try await verifyUserSessionUseCase.invoke()

        try await pullEventsStep.pullEvents()
    }

    // MARK: - Children

    var pullEventsStep: PullEventsStep {
        PullEventsStep(parent: self)
    }
}

extension VerifyUserStep {

    public var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: dependency.applicationIdentifier)!
    }

    public var cookieStorage: any CookieStorageProtocol {
        makeCookieStorage(
            userID: userID
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
