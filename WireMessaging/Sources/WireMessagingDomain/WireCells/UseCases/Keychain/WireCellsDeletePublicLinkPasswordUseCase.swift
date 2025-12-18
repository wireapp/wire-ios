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

package import WireFoundation
import WireLogging
import Foundation

package struct WireCellsDeletePublicLinkPasswordUseCase {
    
    enum Failure: Error {
        case itemNotFound
    }

    private let keychain: any KeychainProtocol

    package init(keychain: any KeychainProtocol) {
        self.keychain = keychain
    }

    package func invoke(
        linkID: String
    ) async {
        let query: Set<KeychainQueryItem> = [
            .service("Wire: file shared link for wire.com"),
            .account(linkID),
            .itemClass(.genericPassword),
        ]
        
        do {
            try await keychain.deleteItem(query: query)
        } catch let error as KeychainError {
            switch error {
            case .errorStatus(let oSstatus) where oSstatus == errSecItemNotFound:
                return
            default:
                return WireLogger.wireCells.error("Failed to delete password from keychain: \(error)")
            }
        } catch {
            return WireLogger.wireCells.error("Failed to delete password from keychain: \(error)")
        }
    
    }

}
