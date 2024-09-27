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

// MARK: - UnownedObject

public final class UnownedObject<T: AnyObject> {
    // MARK: Lifecycle

    public init(_ o: T) {
        self.unbox = o
    }

    // MARK: Public

    public weak var unbox: T?

    public var isValid: Bool { unbox != nil }
}

// MARK: - UnownedNSObject

@objcMembers
public final class UnownedNSObject: NSObject {
    // MARK: Lifecycle

    public init(_ unbox: NSObject) {
        self.unbox = unbox
    }

    // MARK: Public

    public weak var unbox: NSObject?

    public var isValid: Bool { unbox != nil }
}
