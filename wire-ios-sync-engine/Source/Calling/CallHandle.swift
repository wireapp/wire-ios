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

import CallKit
import Foundation

struct CallHandle: Hashable {
    // MARK: Lifecycle

    init(
        accountID: UUID,
        conversationID: UUID
    ) {
        self.accountID = accountID
        self.conversationID = conversationID
    }

    init?(encodedString: String) {
        let identifiers = encodedString
            .split(separator: Self.separator)
            .map(String.init)
            .compactMap(UUID.init(uuidString:))

        guard identifiers.count == 2 else {
            return nil
        }

        self.accountID = identifiers[0]
        self.conversationID = identifiers[1]
    }

    // MARK: Internal

    // MARK: - Properties

    let accountID: UUID
    let conversationID: UUID

    // MARK: - Methods

    var cxHandle: CXHandle {
        CXHandle(type: .generic, value: encodedString)
    }

    var encodedString: String {
        "\(accountID.transportString())\(Self.separator)\(conversationID.transportString())"
    }

    // MARK: Private

    private static let separator: Character = "+"
}
