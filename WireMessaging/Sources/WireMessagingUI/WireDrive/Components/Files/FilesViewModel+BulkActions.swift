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

import Combine
import Foundation
import WireLogging
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// Manages selection and bulk actions: move, delete, restore, make available offline, and remove offline access.
/// Also determines offline action availability and folder warnings. Some methods are shared with per-item actions.
extension FilesViewModel {

    var isBulkActionsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "enableDriveBulkActions")
    }

    var offlineActionWarningMessage: String {
        let folderCount = selectedItems.filter { $0.kind == .folder }.count
        return folderCount > 1
            ? Strings.Files.Offline.folderSelectionWarningMultiple(folderCount)
            : Strings.Files.Offline.folderSelectionWarning
    }

    var canRemoveSelectedItemsOfflineAccess: Bool {
        let selectedIDs = Set(selectedItems.filter { $0.kind == .file }.map(\.id))
        return !selectedIDs.isDisjoint(with: offlineOrDownloadingAssetIDs)
    }

    var canMakeSelectedItemsAvailableOffline: Bool {
        let selectedIDs = Set(selectedItems.filter { $0.kind == .file }.map(\.id))
        let offlineIDs = Set(availableOfflineAssets.map(\.nodeID)).union(
            selectedAssets.values.filter(\.isAvailableOffline).map(\.nodeID)
        )
        return !selectedIDs.isSubset(of: offlineIDs)
    }

    private var offlineOrDownloadingAssetIDs: Set<UUID> {
        Set(availableOfflineAssets.map(\.nodeID)).union(
            selectedAssets.values.filter { asset in
                if case .downloading = asset.downloadState { return true }
                return asset.isAvailableOffline
            }.map(\.nodeID)
        )
    }

    func observeSelectedAssets() {
        selectedAssetSubscriptions.removeAll()
        selectedAssets.removeAll()
        for item in selectedItems where item.kind == .file {
            useCases.observeAsset.invoke(nodeID: item.id)
                .sink { [weak self] asset in
                    self?.selectedAssets[item.id] = asset
                }
                .store(in: &selectedAssetSubscriptions)
        }
    }

    func makeAssetsAvailableOffline(items: Set<FilesViewItem>) {
        // folders offline access not supported
        guard !items.contains(where: { $0.kind == .folder }) else {
            offlineActionWarningID = UUID()
            return
        }

        selectedItems = items
        multipleSelection = .inactive

        Task {
            let results = await useCases.makeAssetAvailableOffline.invoke(nodeIDs: items.map(\.id))
            for (nodeID, result) in results {
                switch result {
                case .success:
                    failedItemActions[nodeID] = nil
                case let .failure(error) where error is CancellationError:
                    WireLogger.wireDrive.error("Cancelled make asset available offline")
                case let .failure(error):
                    failedItemActions[nodeID] = .makeAvailableOffline
                    WireLogger.wireDrive.error("Failed to make asset available offline: \(String(describing: error))")
                }
            }

            await pullAvailableOfflineItems()
        }
    }

    func removeAssetAvailableOffline(items: Set<FilesViewItem>) {
        let files = items.filter { $0.kind == .file }
        selectedItems = files
        multipleSelection = .inactive

        Task {
            for item in files {
                do {
                    try await useCases.removeAssetAvailableOffline.invoke(nodeID: item.id)
                    failedItemActions[item.id] = nil
                } catch {
                    WireLogger.wireDrive
                        .error("Failed to remove asset from available offline: \(String(describing: error))")
                }
            }
            await pullAvailableOfflineItems()

            if isOffline {
                await reload()
            }
        }
    }

    func enableMultipleSelection(_ enabled: Bool) {
        multipleSelection = enabled ? .active : .inactive
        deselectAllItems()
    }

    func selectAllItems() {
        selectedItems = Set(state.items)
    }

    func deselectAllItems() {
        selectedItems.removeAll()
    }

    func moveSelectedItemsToFolder() {
        sheetNavigation = .moveToFolder(fileItems: Array(selectedItems))
    }

    func deleteSelectedItems() async {
        multipleSelection = .inactive
        await deleteItems(Array(selectedItems), permanently: isRecycleBin)
    }

    func restoreSelectedItems() async {
        multipleSelection = .inactive
        await restoreItems(Array(selectedItems))
    }

    func moveToFolder() {
        sheetNavigation = .moveToFolder(fileItems: Array(selectedItems))
    }
}
