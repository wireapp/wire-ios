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

import CoreData
import Foundation

// MARK: - DataPatchInterface

public protocol DataPatchInterface: CaseIterable {
    var version: Int { get }
    func execute(in context: NSManagedObjectContext)
}

// MARK: - PatchApplicator

public final class PatchApplicator<T: DataPatchInterface> {
    // MARK: - Properties

    public let name: String

    var lastRunVersionKey: String {
        "\(name)_LastRunVersion"
    }

    private lazy var logger = WireLogger(tag: "patch applicator - \(name)")

    // MARK: - Life cycle

    public init(name: String) {
        self.name = name
    }

    // MARK: - Methods

    public func applyPatches(in context: NSManagedObjectContext) {
        // Get the current version
        let currentVersion = T.allCases.count

        logger.info("current version is \(currentVersion)")

        defer {
            logger.info("updating last run version with current version")
            context.setPersistentStoreMetadata(currentVersion, key: self.lastRunVersionKey)
            context.saveOrRollback()
        }

        // Get the previous version
        guard let previousVersion = context.persistentStoreMetadata(forKey: lastRunVersionKey) as? Int else {
            // no version was run, this is a fresh install, skipping...
            logger.info("no previous version found, this is a fresh install, skipping...")
            return
        }

        logger.info("previous version is \(previousVersion)")

        let patchesToApply = T.allCases.filter {
            $0.version > previousVersion
        }

        logger.info("there are \(patchesToApply.count) patches to apply...")

        for patch in patchesToApply {
            patch.execute(in: context)
        }
    }
}
