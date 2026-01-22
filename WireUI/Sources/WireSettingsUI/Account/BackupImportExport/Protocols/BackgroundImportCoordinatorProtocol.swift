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

// sourcery: AutoMockable
@MainActor
public protocol BackgroundImportCoordinatorProtocol {

    /// Starts a new import with background continuation support
    ///
    /// - Parameters:
    ///   - url: URL to the backup file (temporary copy created by ViewModel)
    ///   - password: Password for encrypted backups (nil if unencrypted)
    /// - Returns: An async throwing stream of import progress events
    ///
    func startImport(
        for url: URL,
        password: String?
    ) -> AsyncThrowingStream<ImportBackupProgress, any Error>

    /// Cancels the current import
    func cancelImport()
}
