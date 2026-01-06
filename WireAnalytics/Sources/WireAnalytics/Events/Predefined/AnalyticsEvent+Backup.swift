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

public import WireFoundation

public extension AnalyticsEvent {

    enum Backup {

        /// An event tracking when the user fails to export a backup.

        public static let exportFailed = AnalyticsEvent(name: "backup.export_failed")

        /// An event tracking when the user successuflly restores a backup.

        public static let restored = AnalyticsEvent(name: "backup.restore_succeeded")

        /// An event tracking when the user fails to restores a backup.

        public static let restoredFailed = AnalyticsEvent(name: "backup.restore_failed")

    }
}
