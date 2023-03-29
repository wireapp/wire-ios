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
    var capitalizedSentence: String {
        // First, we use the prefix(1) method to get the first letter of the string.
        // Then, we capitalized it
        let firstLetter = self.prefix(1).capitalized
        // We remove the first letter using dropFirst() to get the remaining letters.
        // Then, we lowercase them
        let remainingLetters = self.dropFirst().lowercased()
        // Then, we combine the capitalized letter and the remaining lettters back together.
        return firstLetter + remainingLetters
    }
}
