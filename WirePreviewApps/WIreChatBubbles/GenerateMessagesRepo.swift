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
import WireMessagingDomain

struct GenerateMessagesRepo: LoadConversationMessagesRepositoryProtocol {

    func loadMessages(offset: Int, limit: Int) async -> [MessageModel] {
        let base = "This is a line. "
        return (0 ..< 7).map { _ in
            let repeatCount = Int.random(in: 1 ... 5)
            return MessageModel(
                sender: .init(
                    remoteIdentifier: .init(),
                    name: "Sender",
                    handle: nil
                ),
                kind: .text(.init(text: String(repeating: base, count: repeatCount)))
            )
        }
    }
}
