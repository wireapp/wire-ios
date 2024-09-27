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

// MARK: - StaleMLSKeyDetectorProtocol

// sourcery: AutoMockable
public protocol StaleMLSKeyDetectorProtocol {
    /// The number of days before a key is considered stale.

    var refreshIntervalInDays: UInt { get set }

    /// All group IDs for groups requiring a key update.

    var groupsWithStaleKeyingMaterial: Set<MLSGroupID> { get }

    /// Notify the detector that keying material was updated.
    ///
    /// - Parameters:
    ///   - groupID: the ID of the group in which the keying material was updated

    func keyingMaterialUpdated(for groupID: MLSGroupID)
}

// MARK: - StaleMLSKeyDetector

/// A class responsible for keeping track of groups that have stale key material.
/// It relies on Core Data for storage.

public final class StaleMLSKeyDetector: StaleMLSKeyDetectorProtocol {
    // MARK: Lifecycle

    public init(
        refreshIntervalInDays: UInt = StaleMLSKeyDetector.keyMaterialRefreshIntervalInDays,
        context: NSManagedObjectContext
    ) {
        self.refreshIntervalInDays = refreshIntervalInDays
        self.context = context
    }

    // MARK: Public

    // MARK: - Constants

    public static var keyMaterialRefreshIntervalInDays: UInt {
        // To ensure that a group's key material does not exceed its maximum age,
        // refresh pre-emptively so that it doesn't go stale while the user is offline.
        keyMaterialMaximumAgeInDays - backendMessageHoldTimeInDays
    }

    // MARK: - Properties

    public var refreshIntervalInDays: UInt

    public var groupsWithStaleKeyingMaterial: Set<MLSGroupID> {
        var result = Set<MLSGroupID>()

        context.performAndWait {
            result = Set(
                MLSGroup.fetchAllObjects(in: context).lazy
                    .filter(isKeyingMaterialStale)
                    .map(\.id)
            )
        }

        return result
    }

    public func keyingMaterialUpdated(for groupID: MLSGroupID) {
        WireLogger.mls.info("Tracking key material update date for group (\(groupID))")

        context.performGroupedBlock {
            MLSGroup.updateOrCreate(
                id: groupID,
                inSyncContext: self.context
            ) {
                $0.lastKeyMaterialUpdate = Date()
            }
        }
    }

    // MARK: Internal

    let context: NSManagedObjectContext

    // MARK: Private

    /// The maximum age of a group's key material before it's considered stale.

    private static let keyMaterialMaximumAgeInDays: UInt = 90

    /// The number of days the backend will hold a message.

    private static let backendMessageHoldTimeInDays: UInt = 28

    // MARK: - Helpers

    private func isKeyingMaterialStale(for group: MLSGroup) -> Bool {
        guard let lastUpdateDate = group.lastKeyMaterialUpdate else {
            WireLogger.mls
                .info(
                    "last key material update date for group (\(String(describing: group.id)) doesn't exist... considering stale"
                )
            return true
        }

        guard lastUpdateDate.ageInDays > refreshIntervalInDays else {
            return false
        }

        WireLogger.mls.info("key material for group (\(String(describing: group.id))) is stale")
        return true
    }
}
