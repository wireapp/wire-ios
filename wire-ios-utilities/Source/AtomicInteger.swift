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

@objc
public class AtomicInteger: NSObject {

    private var value: Int

    @objc
    public init(value: Int) {
        self.value = value
    }

    @objc
    public func rawValue() -> Int {
        return value
    }

    @objc
    @discardableResult
    public func increment() -> Int {
        value += 1
        return value
    }

    @objc
    @discardableResult
    public func decrement() -> Int {
        value -= 1
        return value
    }

    /// Checks if the current value is equal to the expected value. If the expected value is equal
    /// to the current value, set the current value to the new value.
    /// - Parameters:
    ///   - condition: The condition to evaluate before updating the value.
    ///   - newValue: The value to set to the integer if the condition evaluated to `true`.
    /// - Returns: Whether the condition evaluated to `true`.
    @objc
    public func setValue(
        withEqualityCondition condition: Int,
        newValue: Int
    ) -> Bool {
        if value == condition {
            value = newValue
            return true
        } else {
            return false
        }
    }
}
