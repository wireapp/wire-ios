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

import Foundation
import NeedleFoundation
import UserNotifications
import WireDataModel
import WireFoundation
import WireNetwork

/// The flow for processing notification requests received
/// in the notification service extension.

final class NSEFlow: BootstrapComponent {

    enum Failure: Error {

        case accountNotFound(UUID)
    }

    public let currentBuildNumber: String
    public let appContainerURL: URL
    public let accountDataURL: URL
    public let accountManager: AccountManager
    public let backendStore: BackendEnvironmentStore
    public let sharedUserDefaults: UserDefaults
    public let cookieEncryptionKey: Data
    public let minTLSVersion: WireNetwork.TLSVersion
    public let preferredAPIVersion: WireNetwork.APIVersion?

    // TODO: [WPB-19778] use to check app version migration
    private let currentAppVersion: String
    private var scopesByAccount = [Account: NSEUserScope]()

    init(
        currentAppVersion: String,
        currentBuildNumber: String,
        appContainerURL: URL,
        sharedUserDefaults: UserDefaults,
        cookieEncryptionKey: Data,
        minTLSVersion: String?,
        preferredAPIVersion: UInt?
    ) throws {
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.appContainerURL = appContainerURL
        self.sharedUserDefaults = sharedUserDefaults
        self.cookieEncryptionKey = cookieEncryptionKey
        self.minTLSVersion = WireNetwork.TLSVersion.minVersionFrom(minTLSVersion)
        self.preferredAPIVersion = preferredAPIVersion.flatMap {
            WireNetwork.APIVersion(rawValue: $0)
        }

        let accountURLs = AccountURLs(root: appContainerURL)
        self.accountDataURL = accountURLs.accountData
        self.accountManager = try AccountManager(
            currentAppVersion: currentAppVersion,
            directory: accountURLs.accounts
        )
        self.backendStore = try BackendEnvironmentStore(directory: accountDataURL)
    }

    func start(
        request: UNNotificationRequest,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) async throws {
        // Get account.
        let payload = try ProcessNotificationRequestUseCase().invoke(request: request)

        guard let account = accountManager.account(with: payload.userID) else {
            throw Failure.accountNotFound(payload.userID)
        }

        // Continue with user.
        let userScope = userScope(for: account)
        try await userScope.processPayload(
            eventID: payload.eventID,
            contentHandler: contentHandler
        )
    }

    // MARK: - Children

    private func userScope(for account: Account) -> NSEUserScope {
        shared {
            NSEUserScope(
                parent: self,
                account: account
            )
        }
    }

}
