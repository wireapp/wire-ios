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

package import Foundation
import UniformTypeIdentifiers
import WireLogging
import WireMessagingDomain

/// An item in the `FilesView`.
package struct FilesViewItem: Identifiable, Hashable, Sendable {

    /// The kind of item
    enum Kind {

        /// A file.
        case file

        /// A folder.
        case folder
    }

    /// Identifier of this item on the wire drive backend.
    package let id: UUID

    /// The ETag of this item.
    let eTag: String

    /// The id of the topmost folder in the recycle bin, if the item is not at the root of the recycle bin.
    /// Needed to restore items which are in folders rather than directly at the root of the recycle bin.
    var recycleBinTopFolderId: UUID?

    /// The kind of this item - file or folder.
    let kind: Kind

    /// The name of the this item.
    let name: String

    /// The filepath of the item.
    let filePath: String

    /// The name of the user who owns (uploaded) this file.
    let ownedBy: String?

    /// The date when the item was last modified.
    let modifiedAt: Date?

    /// The icon representing the item's type.
    let icon: WireDriveFileType

    /// The tags that users have added for that file.
    let tags: [String]

    /// Whether the item can be edited.
    let isEditable: Bool

    /// The public link identifier if the item has a public link.
    let publicLinkID: String?

    /// The name of the conversation the node is attached to.
    let conversationName: String?

    /// Restricts actions on this file, viewer mode only.
    let isReadOnly: Bool

    /// The size of of this item
    let size: UInt64?
}

extension FilesViewItem {
    static func fromNode(_ node: WireDriveNode) -> FilesViewItem? {
        guard let eTag = node.eTag else { return nil }

        // TODO: [WPB-26057] When backend ready, remove this code, the self user role (editor/viewer) on a file will come from the BE.
        guard let selfUser = node.conversation?.participants.first(where: \.isSelfUser) else {
            WireLogger.wireDrive.error("Self user not found - cannot establish file permission - discarding item")
            return nil
        }

        let url = URL(string: node.path)
        let kind: FilesViewItem.Kind = node.type == .collection ? .folder : .file
        return FilesViewItem(
            id: node.id,
            eTag: eTag,
            kind: kind,
            name: url?.lastPathComponent ?? node.path,
            filePath: node.path,
            ownedBy: node.ownerUserName,
            modifiedAt: node.modified,
            icon: kind == .folder ? .folder : .make(
                type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                fileExtension: url?.pathExtension
            ),
            tags: node.tags,
            isEditable: node.isEditable,
            publicLinkID: node.publicLinkID?.string,
            conversationName: node.conversation?.name,
            isReadOnly: selfUser.role == .viewer,
            size: node.size
        )
    }
}

extension FilesViewItem {
    static func fromLocalAsset(
        _ asset: WireDriveLocalAsset,
        conversationName: String?,
        isReadOnly: Bool,
        assetsPath: String?
    ) -> FilesViewItem {

        let fileUrl = URL(fileURLWithPath: asset.path)
        let fileExtension = fileUrl.pathExtension
        let fileType = UTType(filenameExtension: fileExtension)

        func nextFolderPath(from fullPath: String, basePath: String) -> String? {
            let baseComponents = basePath.split(separator: "/")
            let fullComponents = fullPath.split(separator: "/")

            let noMoreFolders = fullComponents.count == baseComponents.count + 1

            if noMoreFolders {
                return nil
            }

            guard fullComponents.starts(with: baseComponents) else {
                return nil
            }

            let nextCount = baseComponents.count + 1
            let nextComponents = fullComponents.prefix(nextCount)
            return nextComponents.joined(separator: "/") + "/"
        }

        let isAllConversations = conversationName == nil
        let basePath = assetsPath ?? asset.path.split(separator: "/").prefix(1).joined()
        let nextFolderPath = isAllConversations ? nil : nextFolderPath(from: asset.path, basePath: basePath)

        let filekind: FilesViewItem.Kind = if nextFolderPath != nil {
            .folder
        } else {
            .file
        }
        let filepath: String = if let nextFolderPath {
            nextFolderPath
        } else {
            asset.path
        }

        return .init(
            id: asset.nodeID,
            eTag: asset.eTag,
            kind: filekind,
            name: URL(fileURLWithPath: filepath).lastPathComponent,
            filePath: filepath,
            ownedBy: asset.ownerName,
            modifiedAt: asset.modified,
            icon: filekind == .folder ? .folder : .make(type: fileType, fileExtension: fileExtension),
            tags: [], // change later if we want to show tags in offline mode.
            isEditable: false, // change later if we want to edit files in offline mode.
            publicLinkID: nil, // change later if we want to be able to share a public link in offline mode.
            conversationName: asset.conversationName,
            isReadOnly: isReadOnly,
            size: asset.size
        )
    }
}
