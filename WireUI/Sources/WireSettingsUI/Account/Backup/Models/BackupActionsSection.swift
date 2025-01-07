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
import SwiftUI

/// The section that will be displayed in the backup actions
struct BackupActionsSection: Identifiable {

    enum Section {
        case backup
        case restore

        var title: Text {
            switch self {
            case .backup:
                Text(L10n.Settings.ExportBackup.action)
            case .restore:
                Text(L10n.Settings.RestoreFromBackup.action)
            }
        }

        var footer: Text {
            switch self {
            case .backup:
                Text(L10n.Settings.ExportBackup.description)
            case .restore:
                Text(L10n.Settings.RestoreFromBackup.description)
            }
        }
    }

    /// Unique identifier for the section
    let id: UUID

    /// The section type
    let type: Section

    init(
        id: UUID = UUID(),
        type: Section
    ) {
        self.id = id
        self.type = type
    }

}
