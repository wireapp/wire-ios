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
import WireFoundation

public struct ProxyCredentialStore {

    let keychain = Keychain()

    public init() {}

    public func fetchCredentials(
        host: String,
        port: Int
    ) async throws -> (username: String, password: String)? {
        let usernameData: Data? = try await keychain.fetchItem(query: [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-username"),
            .returningData(true)
        ])

        let passwordData: Data? = try await keychain.fetchItem(query: [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-password"),
            .returningData(true)
        ])

        guard
            let usernameData,
            let passwordData
        else {
            return nil
        }

        return (
            username: String(decoding: usernameData, as: UTF8.self),
            password: String(decoding: passwordData, as: UTF8.self)
        )
    }

    public func storeCredentials(
        host: String,
        port: Int,
        username: String,
        password: String
    ) async throws {
        try? await keychain.deleteItem(
            query: getUsernameQuery(
                host: host,
                port: port
            )
        )
        try? await keychain.deleteItem(
            query: getPasswordQuery(
                host: host,
                port: port
            )
        )
        try await keychain.addItem(
            query: setUsernameQuery(
                host: host,
                port: port,
                username: username
            )
        )
        try await keychain.addItem(
            query: setPasswordQuery(
                host: host,
                port: port,
                password: password
            )
        )
    }

    private func getUsernameQuery(
        host: String,
        port: Int
    ) -> Set<KeychainQueryItem> {
        var query = usernameQuery(
            host: host,
            port: port
        )
        query.insert(.returningData(true))
        return query
    }

    private func setUsernameQuery(
        host: String,
        port: Int,
        username: String
    ) -> Set<KeychainQueryItem> {
        var query = usernameQuery(
            host: host,
            port: port
        )
        query.insert(.data(Data(username.utf8)))
        return query
    }

    private func usernameQuery(
        host: String,
        port: Int
    ) -> Set<KeychainQueryItem> {
        [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-username")
        ]
    }

    private func getPasswordQuery(
        host: String,
        port: Int
    ) -> Set<KeychainQueryItem> {
        var query = passwordQuery(
            host: host,
            port: port
        )
        query.insert(.returningData(true))
        return query
    }

    private func setPasswordQuery(
        host: String,
        port: Int,
        password: String
    ) -> Set<KeychainQueryItem> {
        var query = passwordQuery(
            host: host,
            port: port
        )
        query.insert(.data(Data(password.utf8)))
        return query
    }

    private func passwordQuery(
        host: String,
        port: Int
    ) -> Set<KeychainQueryItem> {
        [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-password")
        ]
    }

}
