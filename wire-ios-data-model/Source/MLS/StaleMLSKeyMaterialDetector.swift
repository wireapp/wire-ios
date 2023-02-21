//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

protocol StaleMLSKeyDetectorProtocol {

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

final class StaleMLSKeyDetector: StaleMLSKeyDetectorProtocol {

    // MARK: - Properties

    var refreshIntervalInDays: UInt
    let context: NSManagedObjectContext

    // MARK: - Life cycle

    init(
        refreshIntervalInDays: UInt,
        context: NSManagedObjectContext
    ) {
        self.refreshIntervalInDays = refreshIntervalInDays
        self.context = context
    }

    var groupsWithStaleKeyingMaterial: Set<MLSGroupID> {
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

    func keyingMaterialUpdated(for groupID: MLSGroupID) {
        Logging.mls.info("Tracking key material update date for group (\(groupID))")

        MLSGroup.updateOrCreate(
            id: groupID,
            inSyncContext: context
        ) {
            $0.lastKeyMaterialUpdate = Date()
        }
    }

    // MARK: - Helpers

    private func isKeyingMaterialStale(for group: MLSGroup) -> Bool {
        guard let lastUpdateDate = group.lastKeyMaterialUpdate else {
            Logging.mls.info("last key material update date for group (\(String(describing: group.id)) doesn't exist... considering stale")
            return true
        }

        guard lastUpdateDate.ageInDays > refreshIntervalInDays else {
            return false
        }

        Logging.mls.info("key material for group (\(String(describing: group.id))) is stale")
        return true
    }

}
