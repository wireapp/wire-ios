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
import WireFoundation

/// A key that pairs a raw string with a specific value in
/// the `Journal`.

public struct JournalKey<Value>: Sendable where Value: Sendable {

    public let name: String
    public let defaultValue: Value

    init(
        _ name: String,
        defaultValue: Value
    ) {
        self.name = name
        self.defaultValue = defaultValue
    }

}

public extension JournalKey where Value == Bool {

    /// Whether new sync mechanism (use consumable-notifications aka IncrementalSyncV2)

    static let isConsumableNotificationsEnabled = Self(
        "isConsumableNotificationsEnabled",
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

    /// Whether all conversations should be pulled from the backend.

    static let isConversationSyncRequired = Self(
        "isConversationSyncRequired",
        defaultValue: false
    )

    /// Whether the core crypto key needs to be migrated from string to bytes.

    static let isCoreCryptoKeyMigrationToBytesRequired = Self(
        "isCoreCryptoKeyMigrationRequired", // keeping old name for backwards compatibility
        defaultValue: true
    )

    /// Whether the core crypto key needs to be migrated from unscoped storage to a storage scoped by user.

    static let isCoreCryptoKeyMigrationToScopedKeyRequired = Self(
        "isCoreCryptoKeyMigrationToScopedKeyRequired",
        defaultValue: true
    )

    /// Whether the core crypto key needs to be rotated from an old key to a new key.

    static let isCoreCryptoKeyRotationRequired = Self(
        "isCoreCryptoKeyRotationRequired",
        defaultValue: true
    )

    /// Whether MLS is enabled on the backend.

    static let isBackendMLSEnabled = Self(
        "isBackendMLSEnabled",
        defaultValue: false
    )

    /// Whether the local domain needs to be added to entities
    /// in the database.

    static let isFederationMigrationRequired = Self(
        "isFederationMigrationRequired",
        defaultValue: false
    )

    /// Whether faulty MLS removal keys need to be repaired.

    static let isRepairFaultyMLSRemovalKeysRequired = Self(
        "isRepairFaultyMLSRemovalKeysRequired",
        defaultValue: false
    )

}

public extension JournalKey where Value == Set<String> {

    /// The set of MLS group IDs to be repaired.

    static let brokenMLSGroupIDs = Self(
        "brokenMLSGroupIDs",
        defaultValue: []
    )

}

extension JournalKey where Value == Date {

    /// The last time key packages were counted

    static let lastKeyPackageCountTime = Self(
        "lastKeyPackageCountTime",
        defaultValue: .distantPast
    )

}

// MARK: - KeyPackageCheckDates

/// Stores the last time key packages were checked for different ciphersuites.
/// The dictionary key is the MLSCipherSuite raw value.

public struct KeyPackageCheckDates: Codable, Sendable {

    public let values: [Int: Date]

    public init(values: [Int: Date] = [:]) {
        self.values = values
    }

}

extension JournalKey where Value == KeyPackageCheckDates {

    /// The last time key packages were checked, indexed by MLSCipherSuite raw value

    static let lastKeyPackageCheckDates = Self(
        "lastKeyPackageCheckDates",
        defaultValue: KeyPackageCheckDates()
    )

}
