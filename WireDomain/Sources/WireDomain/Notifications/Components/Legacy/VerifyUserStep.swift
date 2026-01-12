//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

// TODO: [WPB-19818] delete when multibackend is released

import NeedleFoundation
import UserNotifications
import WireCrypto
import WireDataModel
import WireFoundation
import WireNetwork

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
        case missingSelfClientID
        case mainAppPushChannelOpened
    }

    public var selectedAccount: Account
    public var accountManager: AccountManager
    public var userID: UUID
    public var eventID: UUID

    init(
        parent: any Scope,
        userID: UUID,
        eventID: UUID,
        accountManager: AccountManager
    ) throws {
        self.userID = userID
        self.accountManager = accountManager
        self.eventID = eventID

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
            journal: journal,
            cookieStorage: cookieStorage,
            coreData: coreData
        )

        try await verifyUserSessionUseCase.invoke()

        let selfUser = await userLocalStore.selfUserInfo()

        guard let selfClientID = selfUser.clientId else {
            throw Failure.missingSelfClientID
        }

        if journal[.isConsumableNotificationsEnabled] {

            try await syncEventsStep(
                selfClientID: selfClientID
            ).pullEvents()

        } else {
            try await pullEventsStep(
                selfClientID: selfClientID
            ).pullEvents()
        }
    }

    // MARK: - Children

    func pullEventsStep(
        selfClientID: String
    ) -> PullEventsStep {
        PullEventsStep(
            parent: self,
            selfClientID: selfClientID
        )
    }

    func syncEventsStep(
        selfClientID: String
    ) -> SyncEventsStep {
        SyncEventsStep(
            parent: self,
            selfClientID: selfClientID
        )
    }
}

extension VerifyUserStep {

    public var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: dependency.applicationIdentifier)!
    }

    private var journal: Journal {
        Journal(
            userID: userID,
            storage: sharedUserDefaults
        )
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

    func makeCoreData(
        account: Account,
        applicationIdentifier: String
    ) -> CoreDataStack {
        let applicationContainer = makeApplicationContainer(
            applicationIdentifier: applicationIdentifier
        )

        return CoreDataStack(
            account: account,
            applicationContainer: applicationContainer,
            localDomain: BackendInfo.domain,
            isFederationEnabled: BackendInfo.isFederationEnabled
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
