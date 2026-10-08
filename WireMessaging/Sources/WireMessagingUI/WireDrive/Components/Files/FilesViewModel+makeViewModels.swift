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

import WireFoundation
import WireMessagingDomain

extension FilesViewModel {
    func itemViewModel(index: Int) -> FilesItemViewModel {
        .init(
            item: state.items[index],
            selectedSortingKey: sortingSelection.sortingKey,
            conversationName: isBrowsing ? state.items[index].conversationName : nil,
            observeAssetUseCase: useCases.observeAsset,
            getAssetUseCase: useCases.getAsset,
            onItemAction: { [weak self] action, item in
                guard let self else { return }
                switch action {
                case .primaryAction:
                    await performPrimaryAction(item: item)
                case .deleteToRecycleBin:
                    await deleteItem(item, permanently: false)
                case .deletePermanently:
                    await deleteItem(item, permanently: true)
                case .restore:
                    await restoreItem(item)
                case .rename:
                    sheetNavigation = .renameFile(fileItem: item)
                case .editTags:
                    sheetNavigation = .editTags(fileItem: item)
                case .shareLink:
                    sheetNavigation = .shareLink(fileItem: item)
                case .moveToFolder:
                    sheetNavigation = .moveToFolder(fileItem: item)
                case .showVersionHistory:
                    sheetNavigation = .versionHistory(fileItem: item)
                case .edit:
                    isEditing = item
                case .makeAvailableOffline:
                    makeAssetAvailableOffline(item: item)
                case .removeAvailableOffline:
                    removeAssetAvailableOffline(item: item)
                }
            },
            isBrowsing: isBrowsing,
            isInRecycleBin: isRecycleBin,
        )
    }

    func createFileViewModel(target: WireDriveCreateFileUseCase.Target) -> CreateFileViewModel {
        // When navigation path is empty, file/folder is created at the root path (cell name)
        let path = navigationPath.last?.filePath ?? cellName ?? ""

        return .init(
            creationTarget: target,
            path: path,
            createFileUseCase: useCases.createFile,
            onNodeCreated: { [weak self] createdNode in
                guard let self else { return }
                if case .file = target {
                    isEditing = FilesViewItem.fromNode(createdNode)
                }
                Task {
                    await reload()
                }
            }
        )
    }

    func moveToFolderViewModel(item: FilesViewItem) -> MoveToFolderViewModel {
        let containerPath = item.filePath.components(separatedBy: "/").dropLast().joined(separator: "/")
        return .init(
            containerPath: containerPath,
            nodeID: item.id,
            nodeName: item.name,
            onFinish: { [weak self] in
                self?.sheetNavigation = nil
                Task { await self?.reload(refreshing: true) }
            },
            moveNodeUseCase: useCases.moveNode,
            createFileUseCase: useCases.createFile,
            fetchNodesUseCase: useCases.fetchNodes
        )
    }

    func editFileViewModel(item: FilesViewItem) -> EditFileViewModel {
        .init(
            nodeID: item.id,
            fileName: item.name,
            getEditingURLUseCase: useCases.getEditingURL
        )
    }

    func fileRenameViewModel(item: FilesViewItem) -> FileRenameViewModel {
        .init(
            renameNodeUseCase: useCases.renameNode,
            model: .init(
                nodeID: item.id,
                filename: item.name,
                filepath: item.filePath,
            ),
            kind: item.kind,
            onRenamed: { [weak self] in
                Task { await self?.reload() }
            }
        )
    }

    func shareLinkViewModel(item: FilesViewItem) -> ShareLinkView.ViewModel {
        .init(
            fileItem: item,
            useCases: ShareLinkView.ViewModel.UseCases(
                getLinkData: useCases.getPublicLinkData,
                createPublicLink: useCases.createPublicLink,
                deletePublicLink: useCases.deletePublicLink,
                updatePublicLinkExpiration: useCases.updatePublicLinkExpiration,
                updatePublicLinkPassword: useCases.updatePublicLinkPassword,
                getPublicLinkPasswordUseCase: WireDriveGetPublicLinkPasswordUseCase(keychain: Keychain()),
                storePublicLinkPasswordUseCase: WireDriveStorePublicLinkPasswordUseCase(keychain: Keychain()),
                deletePublicLinkPasswordUseCase: WireDriveDeletePublicLinkPasswordUseCase(keychain: Keychain())
            ),
            onLinkStateChanged: { [weak self] state in
                switch state {
                case .enabled, .disabled:
                    Task { await self?.reload() }
                default:
                    break
                }
            }
        )
    }

    func fileVersioningViewModel(item: FilesViewItem) -> FileVersioningViewModel {
        .init(
            nodeID: item.id,
            name: item.name,
            eTag: item.eTag,
            fetchNodeVersionsUseCase: useCases.fetchNodeVersions,
            restoreNodeVersionUseCase: useCases.restoreNodeVersion,
            getAssetUseCase: useCases.getAsset,
            onVersionRestored: { [weak self] in
                Task { await self?.reload() }
            }
        )
    }

    func filesSortingViewModel() -> FilesSortingViewModel {
        .init(
            isBrowsing: isBrowsing,
            subfolderName: navigationPath.last?.name
        ) { [weak self] sortingSelection in
            self?.sortingSelection = sortingSelection
            Task { await self?.reload() }
        }
    }
}
