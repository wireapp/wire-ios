//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import AppIntents
import os
import WireDataModel
import WireSyncEngine

@available(iOS 16, *)
struct OpenWireIntent: OpenIntent {

    static let title = LocalizedStringResource(stringLiteral: "Open Wire on selected Account")

    @Parameter(title: "Account", description: "The account the app should be switched to after opening.")
    var target: AccountEntity

    @Dependency
    private var sessionManager: SessionManager

    @MainActor
    func perform() async throws -> some IntentResult {
        let account = sessionManager.accountManager.accounts.first { $0.userIdentifier == target.id }!
        //accountManager.select(account)
        sessionManager.select(account)
        return .result()
    }
}

@available(iOS 16.0, *)
struct AccountEntity: AppEntity {

    static var defaultQuery: AccountEntityQuery { .init() }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: .init(stringLiteral: "Select Account"))
    }

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(name)")
    }

    private(set) var id: UUID
    private(set) var name: String

    init(_ account: Account) {
        id = account.userIdentifier
        name = account.userName
    }
}

@available(iOS 16.0, *)
struct AccountEntityQuery: EntityQuery {

    @Dependency
    private var accountManager: AccountManager

    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        os.Logger.openWireIntent.debug("entities(for: \(identifiers)): ?")

        return identifiers.map { id in
            let account = accountManager.accounts.first { $0.userIdentifier == id }!
            return .init(account)
        }
    }

    func suggestedEntities() async throws -> [AccountEntity] {

        await MainActor.run {
            let sut = CoreCryptoKeyProvider()

            let item = CoreCryptoKeychainItem()
            let expectedKey = try! KeychainManager.generateKey(numberOfBytes: 32)
            try? KeychainManager.storeItem(item, value: expectedKey)

            let key = try! sut.coreCryptoKey(createIfNeeded: false)
            os.Logger.openWireIntent.debug("key.count: \(key.count, privacy: .public)")
        }
        UIApplication

        return accountManager.accounts.map(AccountEntity.init(_:))
    }
}

@available(iOS 16, *)
extension os.Logger {
    static let openWireIntent = Self(subsystem: Bundle.main.bundleIdentifier!, category: .init(describing: OpenWireIntent.self))
}
