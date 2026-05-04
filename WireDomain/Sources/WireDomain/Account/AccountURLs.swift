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

/// An object representing the high level folder structure
/// in the app container on the file system.
///
/// An example of the app container looks like:
/// ```
/// - Root
///     - Accounts
///         - 47B3C313-E3FA-4DE4-8DBE-5BBDB6A0A14B.json
///         - 0F5771BB-2103-4E45-9ED2-E7E6B9D46C0F.json
///     - AccountData
///         - 47B3C313-E3FA-4DE4-8DBE-5BBDB6A0A14B
///             - ...
///         - 0F5771BB-2103-4E45-9ED2-E7E6B9D46C0F
///             - ...
/// ```

public struct AccountURLs {

    /// Root of the account container.

    private let root: URL

    /// Directory containing information about store accounts.

    public let accounts: URL

    /// Directory containing data for each stored account.

    public let accountData: URL

    /// Create the account data URLs.
    ///
    /// - Parameter root: The url to the application container.

    public init(root: URL) {
        self.root = root
        self.accounts = root.appending(
            path: "Accounts",
            directoryHint: .isDirectory
        )
        self.accountData = root.appending(
            path: "AccountData",
            directoryHint: .isDirectory
        )
    }

    /// The data directory url for a given account.

    public func dataDirectory(forAccountID id: UUID) -> URL {
        accountData.appending(
            path: id.uuidString,
            directoryHint: .isDirectory
        )
    }

}
