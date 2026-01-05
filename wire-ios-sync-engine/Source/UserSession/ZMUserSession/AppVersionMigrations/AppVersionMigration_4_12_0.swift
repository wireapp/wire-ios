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

import Foundation
import WireDomain

/// **Issue:**: Faulty MLS removal keys need repair - [WPB-22447]
struct AppVersionMigration_4_12_0: AppVersionMigration {

    let version: SemanticVersion = "4.12.0"
    let journal: any JournalProtocol
    let repairGenerator: RepairFaultyMLSRemovalKeysGenerator?

    func perform() async throws {
        // Mark that faulty MLS removal keys need to be repaired
        journal[.isRepairFaultyMLSRemovalKeysRequired] = true

        // Submit the work item now that the flag is set
        repairGenerator?.submitWorkItemIfNeeded()
    }

}
