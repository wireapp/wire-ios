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
import WireFoundation
import WireLogging
import WireMessagingDomain
import WireMessagingDomainSupport

struct LoadOfflineAvailableFilesUIAction {
    struct Input {
        let conversationName: String?
        let assetsPath: String?
        let getAsset: WireDriveGetAssetUseCase
        let getOfflineAvailableAssets: WireDriveFetchOfflineAvailableAssetsUseCase
    }

    let input: Input

    func callAsFunction() async throws -> [FilesViewItem] {
        let offlineAssets = try await input.getOfflineAvailableAssets.invoke(
            conversationName: input.conversationName,
            assetsPath: input.assetsPath
        )

        let items: [FilesViewItem] = offlineAssets.map { asset in
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

            let isAllConversations = input.conversationName == nil
            let basePath = input.assetsPath ?? asset.path.split(separator: "/").prefix(1).joined()
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
                size: asset.size
            )
        }

        let itemsWithCreationDates: [(item: FilesViewItem, creationDate: Date)] = await items.asyncMap { item in
            let url = try? await input.getAsset.invoke(nodeID: item.id, eTag: item.eTag)
            let creationDate = (try? url?.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            return (item: item, creationDate: creationDate)
        }

        return itemsWithCreationDates.sorted { lhs, rhs in
            lhs.creationDate.compare(rhs.creationDate) == .orderedDescending
        }
        .map(\.item)
        .reduce(into: [FilesViewItem]()) { result, item in
            let isDuplicate = result.map(\.filePath).contains(item.filePath) // removes duplicated folders

            if !isDuplicate {
                result.append(item)
            }
        }
    }
}

private extension Sequence {
    @MainActor
    func asyncMap<T>(_ transform: @MainActor (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}
