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

@testable import WireMessagingUI

extension FilesViewItem {

    static func fixture(
        id: UUID = UUID(),
        filename: String = "filename.png",
        filePath: String = "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image filename.png",
        ownedBy: String? = nil,
        modifiedAt: Date? = nil,
        icon: FileIcon = .image
    ) -> FilesViewItem {
        FilesViewItem(
            id: id,
            filename: filename,
            filePath: filePath,
            ownedBy: ownedBy,
            modifiedAt: modifiedAt,
            icon: icon
        )
    }

}
