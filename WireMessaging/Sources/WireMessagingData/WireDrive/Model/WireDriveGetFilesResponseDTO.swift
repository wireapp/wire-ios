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

import CellsSDK
import Foundation

package struct WireDriveGetFilesResponseDTO: Equatable, Hashable, Sendable {
    package let nodes: [WireDriveNodeNetworkModel]

    package init(nodes: [WireDriveNodeNetworkModel]) {
        self.nodes = nodes
    }
}

package extension RestNodeCollection {
    func toDTO() -> WireDriveGetFilesResponseDTO {
        WireDriveGetFilesResponseDTO(
            // /!\ Will silently filter out nil values that could not be mapped to DTOs
            nodes: nodes?.compactMap { $0.toDTO() } ?? []
        )
    }
}
