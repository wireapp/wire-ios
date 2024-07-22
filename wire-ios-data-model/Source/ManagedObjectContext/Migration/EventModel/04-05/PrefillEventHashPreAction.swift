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

@objc(PrefillEvenHashAction)
class PrefillEvenHashAction: NSEntityMigrationPolicy {
    private enum Keys: String {
        case eventHash
    }

    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        // create the dInstance
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        // mark it needing update
        let dInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first
        let uniqueKey = Int64.random(in: 0...Int64.max)
        let id = dInstance?.value(forKey: "eventId") as? String
        dInstance?.setValue(uniqueKey, forKey: Keys.eventHash.rawValue)
        WireLogger.localStorage.info("setting value \(uniqueKey) for event id: \(String(describing: id))")

    }
}
