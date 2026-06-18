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
import WireShareEngine
import WireShareExtensionCore

struct FetchConversationsUseCaseImpl: FetchConversationsUseCase {

    let sessionProvider: (Account) async throws -> SharingSession

    func callAsFunction(
        for account: Account
    ) async throws -> [WireShareExtensionCore.Conversation] {
        let session = try await sessionProvider(account)
        return session.writeableNonArchivedConversations.compactMap { conversation in
            guard let name = conversation.name, let id = conversation.remoteIdentifier else { return nil }
            return WireShareExtensionCore.Conversation(
                id: id,
                name: name
            )
        }
    }

}
