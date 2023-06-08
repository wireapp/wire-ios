//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel

extension ZMConversation {

    private var hasIncompleteMetadataForGroup: Bool {
        guard let name = userDefinedName else {
            return true
        }
        return name.isEmpty
    }

    private var hasIncompleteMetadataForOneToOne: Bool {
        if let _ = participants.first(where: { $0.hasEmptyName }) {
            return true
        } else {
            return false
        }
    }

    var hasIncompleteMetadata: Bool {
        guard !estimatedHasMessages else {
            return false
        }
        switch conversationType {
        case .group:
            return hasIncompleteMetadataForGroup
        case .oneOnOne:
            return hasIncompleteMetadataForOneToOne
        default:
            return false
        }
    }

}

extension UserType {

    public var hasEmptyName: Bool {
        guard let name = name else {
            return true
        }
        return name.isEmpty
    }

}
