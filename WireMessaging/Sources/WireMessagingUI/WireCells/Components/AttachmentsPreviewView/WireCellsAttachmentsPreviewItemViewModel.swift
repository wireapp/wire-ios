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

import Combine
import Foundation
import WireMessagingDomain

@MainActor
final class WireCellsAttachmentsPreviewItemViewModel: ObservableObject {

    private let item: WireCellsAttachmentsPreviewViewItem

    let headerText: String
    let fileName: String

    init(item: WireCellsAttachmentsPreviewViewItem) {
        let fileSize = (item.fileSize?.formatted(.byteCount(style: .decimal)) as String?).map { "(\($0))" }

        self.item = item
        self.headerText = [item.fileExtension?.uppercased(), fileSize].compactMap { $0 }.joined(separator: " ")
        self.fileName = [item.fileName, item.fileExtension].compactMap { $0 }.joined(separator: ".")
    }

    var icon: FileIcon {
        item.fileIcon
    }

    var progress: Double {
        0.0
    }

    var isError: Bool {
        false
    }

}
