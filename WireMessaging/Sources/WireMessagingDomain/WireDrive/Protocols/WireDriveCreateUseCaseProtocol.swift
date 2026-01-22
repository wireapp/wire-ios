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

// sourcery: AutoMockable
package protocol WireDriveCreateUseCaseProtocol: Sendable {

    /// Creates a new file or folder on the server.
    ///
    /// This method sends a request to create a folder at the specified path.
    ///
    /// - Parameters:
    ///   - creationTarget: Whether a folder or a specific file (document, spreadsheet, presentation..).
    ///   - path: The path of the file/folder.
    ///   - name: The name of the file/folder to create.
    /// - Returns: The created node.
    func invoke(
        creationTarget: CreationTarget,
        path: String,
        name: String
    ) async throws -> WireDriveNode

}
