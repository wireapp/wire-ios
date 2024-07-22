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
import WireUtilities

class CRLDistributionPointsStorageMigrator {

    typealias Key = CRLDistributionPointsRepository.Key

    func migrate(
        from oldStorage: PrivateUserDefaults<Key>,
        to newStorage: PrivateUserDefaults<Key>
    ) {
        // Check if we have distribution points in the old storage
        // And if we don't have them in the new storage
        guard
            let distributionPoints = oldStorage.object(forKey: Key.distributionPoints) as? [String],
            newStorage.object(forKey: Key.distributionPoints) == nil
        else {
            return
        }

        // Move distribution points from the old storage to the new storage
        // And remove them from the old storage

        newStorage.set(distributionPoints, forKey: Key.distributionPoints)
        oldStorage.removeObject(forKey: Key.distributionPoints)

        // Move expiration dates from the old storage to the new storage
        // And remove them from the old storage

        for distributionPoint in distributionPoints {
            let key = Key.expirationDate(dp: distributionPoint)
            let expirationDate = oldStorage.date(forKey: key)

            guard newStorage.object(forKey: key) == nil else {
                continue
            }

            newStorage.set(expirationDate, forKey: key)
            oldStorage.removeObject(forKey: key)
        }
    }
}
