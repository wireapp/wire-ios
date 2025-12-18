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
package import WireFoundation
import WireLogging

package struct WireCellsStorePublicLinkPasswordUseCase {

    private let keychain: any KeychainProtocol

    package init(keychain: any KeychainProtocol) {
        self.keychain = keychain
    }

    package func invoke(
        linkID: String,
        password: String
    ) async throws {
        guard let data = password.data(using: .utf8) else {
            return
        }

        let query: Set<KeychainQueryItem> = [
            .service("Wire: file shared link for wire.com"),
            .account(linkID),
            .itemClass(.genericPassword),
            .accessible(.afterFirstUnlock),
            .data(data)
        ]

        do {
            try await keychain.addItem(query: query)
        } catch let error as KeychainError {
            switch error {
            case let .errorStatus(oSstatus) where oSstatus == errSecDuplicateItem:
                let updateQuery: Set<KeychainQueryItem> = [.data(data)]
                try await keychain.updateItem(query: query, attributesToUpdate: updateQuery)
            default:
                return WireLogger.wireCells.error("Failed to store password in keychain: \(error)")
            }
        }
    }

}
