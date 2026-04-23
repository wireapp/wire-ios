// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

/// An error that wraps another error, allowing recursive inspection of the error chain.
public protocol WrappingError: Error {
    var underlyingError: any Error { get }
}

public extension Error {
    /// The deepest non-wrapping error in the chain.
    var rootCause: any Error {
        (self as? WrappingError)?.underlyingError.rootCause ?? self
    }

    var isCancelledError: Bool {
        rootCause is CancellationError || (rootCause as? URLError)?.code == .cancelled
    }
}
