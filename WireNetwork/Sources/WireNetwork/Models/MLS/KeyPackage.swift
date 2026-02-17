//
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

/// A base64-encoded MLS key package.

public struct KeyPackage: Equatable, Sendable {

    /// The base64-encoded key package data.

    public let base64EncodedData: String

    /// Create a new `KeyPackage`.
    ///
    /// - Parameter base64EncodedData: The base64-encoded key package data.

    public init(base64EncodedData: String) {
        self.base64EncodedData = base64EncodedData
    }

}
