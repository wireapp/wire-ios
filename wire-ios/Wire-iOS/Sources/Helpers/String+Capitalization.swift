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

extension String {
    /// The first character in each sentence changed to its corresponding uppercase value.
    /// All remaining characters set to their corresponding lowercase values.
    ///
    /// Caveat:

    ///  1. The implementation only works with a string that contains one sentence.
    ///  The second sentence won't get capitalized.
    ///
    ///  2. It doesn't work if the first string is a whitespace character and delimiter.
    var capitalizedCharacter: String {
        let firstLetter = self.prefix(1).capitalized

        let remainingLetters = self.dropFirst().lowercased()

        return firstLetter + remainingLetters
    }
}
