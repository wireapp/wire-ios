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

// sourcery: AutoMockable
package protocol WireCellsCreateFolderUseCaseProtocol: Sendable {

    /// Creates a new folder on the server.
    ///
    /// This method sends a request to create a folder within the specified container.
    /// If `subfoldersPath` is provided, the new folder is created inside that subpath.
    ///
    /// - Parameters:
    ///   - rootPath: The root container (aka cell name) in which the folder will be created.
    ///   - subfoldersPath: The path of the subfolder where the new folder should be created. Pass `nil` to create it directly under the root container.
    ///   - folderName: The name of the folder to create.
    func invoke(
        rootPath: String,
        subfoldersPath: String?,
        folderName: String
    ) async throws

}
