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

import WireSidebarUI
import WireAccountImageUI

extension WireSidebarUI.SidebarAccountInfo.AccountImageContent {

    /// Since `WireAccountImageUI.AccountImageView.Content` does not know about the type `WireSidebarUI`,
    /// this function serves as an adapter from `WireSidebarUI.SidebarAccountInfo.AccountImageContent` to `WireAccountImageUI.AccountImageView.Content`.

    func mapToAccountImageViewContent() -> WireAccountImageUI.AccountImageView.Content {
        switch self {
        case .image(let image):
                .image(image)
        case .text(let text):
                .text(text)
        }
    }
}
