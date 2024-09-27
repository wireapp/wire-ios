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

enum NetworkQualityType: Int, Comparable {
    case unknown = 0
    case type2G
    case type3G
    case type4G
    case typeWifi

    // MARK: Internal

    static func < (lhs: NetworkQualityType, rhs: NetworkQualityType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
