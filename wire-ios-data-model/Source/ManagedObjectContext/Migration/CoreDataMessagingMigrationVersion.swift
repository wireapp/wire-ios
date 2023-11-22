////
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

enum CoreDataMessagingMigrationVersion: String, CaseIterable {

    // TODO: add more old versions!
    
    case version2_108 = "zmessaging2.108.0"
    case version2_109 = "zmessaging2.109.0"

    var nextVersion: Self? {
        switch self {
        case .version2_108:
            return .version2_109
        case .version2_109:
            return nil
        }
    }

    // MARK: - Current

    static let current: Self = {
        guard let current = allCases.last else {
            fatalError("no model versions found")
        }

        return current
    }()
}
