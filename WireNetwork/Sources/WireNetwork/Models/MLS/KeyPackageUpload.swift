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

/// Payload to upload MLS key packages.

public struct KeyPackageUpload: Equatable, Sendable {

    /// The list of base64-encoded key packages to upload.

    public let keyPackages: [KeyPackage]

    /// Create a new `KeyPackageUpload`.
    ///
    /// - Parameter keyPackages: The list of key packages to upload.

    public init(keyPackages: [KeyPackage]) {
        self.keyPackages = keyPackages
    }

}
