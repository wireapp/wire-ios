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

import Foundation

extension Sequence where Iterator.Element == NSAttributedString {

    public func joined(separator: NSAttributedString? = .none) -> NSAttributedString {
        let result = Array(self)
        guard result.count > 1 else { return result.first ?? .init() }

        let string = NSMutableAttributedString(attributedString: result[0])
        for i in result.indices[1...] {
            separator.map { string.append($0) }
            string.append(result[i])
        }
        return string
    }
}
