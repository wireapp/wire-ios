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

extension String {
    /// Creates a new string by applying the given transform.
    ///
    /// - Parameter transform: TextTransform to apply
    /// - Returns: the transformed string
    func applying(transform: TextTransform) -> String {
        switch transform {
        case .none: self
        case .capitalize: localizedCapitalized
        case .lower: localizedLowercase
        case .upper: localizedUppercase
        }
    }
}

extension NSAttributedString {
    /// Creates a new string by applying the given transform.

    func applying(transform: TextTransform) -> NSAttributedString {
        let newString = string.applying(transform: transform)

        let mutableCopy = mutableCopy() as! NSMutableAttributedString
        mutableCopy.replaceCharacters(in: NSRange(location: 0, length: length), with: newString)
        return mutableCopy
    }
}

extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespaces)
    }
}
