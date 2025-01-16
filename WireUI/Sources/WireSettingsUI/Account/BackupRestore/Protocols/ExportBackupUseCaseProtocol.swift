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

/// A use case to export the current app state using a provided `password`.
public protocol ExportBackupUseCaseProtocol {

    /// A backup file will be created and saved to a temporary location and the `export` closure is called.
    /// After the closure returns the backup file is cleaned up.
    func invoke(
        password: String,
        export: @escaping (_ url: URL) async -> Void
//        exportBackupActivityPresenter: some ExportBackupActivityProtocol
    ) async throws
}
