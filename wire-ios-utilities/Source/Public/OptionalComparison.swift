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

public enum OptionalComparison {
    /// Compares two optional values in ascending order.
    ///
    /// - Parameters:
    ///   - lhs: An optional comparable value on the left hand side.
    ///   - rhs: An optional comparable value on the right hand side.
    ///
    /// - Returns:
    ///  `true` if left hand side is smaller than right hand side.
    /// `nil` is  considered as smaller than any value.
    /// If both parameters are `nil`, the method returns `false`.
    public static func prependingNilAscending<T: Comparable>(lhs: T?, rhs: T?) -> Bool {
        if lhs == nil, rhs == nil {
            return false
        }

        guard let lhs else {
            return true
        }

        guard let rhs else {
            return false
        }

        return lhs < rhs
    }
}

extension Collection {
    /// Returns the elements of the sequence, sorted ascending using the given keyPath as the comparison between
    /// elements.
    /// - Parameter keyPath: The keypath to compare, the value can be optional.
    /// - Returns: An ascending sorted array of the sequence’s elements with prepending `nil` values.
    public func sortedAscendingPrependingNil(
        by keyPath: KeyPath<Element, (some Comparable)?>
    ) -> [Element] {
        sorted { lhsRoot, rhsRoot in
            OptionalComparison.prependingNilAscending(
                lhs: lhsRoot[keyPath: keyPath],
                rhs: rhsRoot[keyPath: keyPath]
            )
        }
    }

    /// Returns the elements of the sequence, sorted ascending using the given closure as the comparison between
    /// elements.
    /// - Parameter keyPath: The keypath to compare, the value can be optional.
    /// - Returns: An ascending sorted array of the sequence’s elements with prepending `nil` values.
    public func sortedAscendingPrependingNil(
        by value: (Element) -> (some Comparable)?
    ) -> [Element] {
        sorted { lhsRoot, rhsRoot in
            OptionalComparison.prependingNilAscending(
                lhs: value(lhsRoot),
                rhs: value(rhsRoot)
            )
        }
    }
}
