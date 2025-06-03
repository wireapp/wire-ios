//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireFoundation

/// A key that pairs a raw string with a specific value in
/// the `Journal`.

public struct JournalKey<Value>: Sendable where Value: Sendable {

    let name: String
    let defaultValue: Value

    init(
        _ name: String,
        defaultValue: Value
    ) {
        self.name = name
        self.defaultValue = defaultValue
    }

}

public extension JournalKey where Value == Bool {

    /// Whether new sync mechanism (async stream) is used.

    static let isSyncV3Enabled = Self(
        "isSyncV3Enabled",
        defaultValue: false
    )

    /// Whether new sync mechanism (initial sync, incremental
    /// sync, live sync) is used.

    static let isSyncV2Enabled = Self(
        "isSyncV2Enabled",
        defaultValue: false
    )

    /// Whether an initial sync needs to be performed.

    static let isInitialSyncRequired = Self(
        "isInitialSyncRequired",
        defaultValue: false
    )

    /// Whether a core crypto key migration needs to be performed.

    static let isCoreCryptoKeyMigrationRequired = Self(
        "isCoreCryptoKeyMigrationRequired",
        defaultValue: true
    )

}
