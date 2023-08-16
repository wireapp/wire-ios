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

extension [String] {

    typealias Strings = L10n.Localizable.General.NounSeparator

    func localizedString() -> String {
        guard
            let first = first,
            let last = last
        else {
            return ""
        }

        switch count {
        case 1:
            return first

        case 2:
            // "A and B"
            return Strings.and(first, last)

        default:
            // "A, B, C, ..."
            var commaSeparatedValues = dropLast().reduce(first, Strings.comma)

            // "A, B, C, ..., and Z"
            return Strings.commaAnd(commaSeparatedValues, last)
        }
    }

}
