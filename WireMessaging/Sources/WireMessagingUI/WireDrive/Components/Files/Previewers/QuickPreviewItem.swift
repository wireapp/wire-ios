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
import UniformTypeIdentifiers
import WireLogging
import WireMessagingDomain

/// This model contains the information required to open and display the actual
/// full-screen file preview shown to the user, independently from the attachment
/// thumbnail representation.
struct QuickPreviewItem: Equatable {
    let url: URL
    let fileType: WireDriveFileType
    let filename: String
    let isReadOnly: Bool
    var openFrom: OpenFrom

    enum OpenFrom: Equatable {
        case conversation
        case drive
    }
}

extension QuickPreviewItem {
    static func fromNode(_ node: WireDriveNode?, url: URL) -> QuickPreviewItem? {
        guard let node else { return nil }

        guard let selfUser = node.conversation?.participants.first(where: \.isSelfUser) else {
            WireLogger.wireDrive.error("Self user not found - cannot establish file permission - discarding item")
            return nil
        }

        let isReadOnly = selfUser.role == .viewer
        let kind: FilesViewItem.Kind = node.type == .collection ? .folder : .file

        return QuickPreviewItem(
            url: url,
            fileType: kind == .folder ? .folder : .make(
                type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                fileExtension: url.pathExtension
            ),
            filename: url.lastPathComponent,
            isReadOnly: isReadOnly,
            openFrom: .conversation
        )

    }

    static func fromFilesViewItem(_ item: FilesViewItem, url: URL) -> QuickPreviewItem {
        .init(
            url: url,
            fileType: item.icon,
            filename: item.name,
            isReadOnly: item.isReadOnly,
            openFrom: .drive
        )
    }
}
