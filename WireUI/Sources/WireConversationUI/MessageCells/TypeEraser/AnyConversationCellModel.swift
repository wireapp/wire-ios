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

import SwiftUI

struct AnyConversationCellModel<Model: ConversationCellModelProtocol>: ConversationCellModelProtocol {
    typealias ContentView = AnyConversationCellContentView<AnyConversationCellModel<Model>>

    var id: AnyHashable { _id() }

    private let _id: @Sendable () -> AnyHashable
    private let _hash: @Sendable (inout Hasher) -> Void
    private let _isEqual: @Sendable (Any) -> Bool

    init(_ base: Model) {
        _id = {
            AnyHashable(base.id)
        }
        _hash = { hasher in
            base.hash(into: &hasher)
        }
        _isEqual = { other in
            guard let otherBase = other as? Model else { return false }
            return base == otherBase
        }
    }

    init() {
        self.init(Model())
    }

    func hash(into hasher: inout Hasher) {
        _hash(&hasher)
    }

    static func == (lhs: AnyConversationCellModel, rhs: AnyConversationCellModel) -> Bool {
        lhs._isEqual(rhs)
    }

}
