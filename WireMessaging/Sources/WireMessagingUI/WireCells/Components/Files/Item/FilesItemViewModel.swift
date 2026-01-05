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

/// A view model for a single item in the `FilesView`.
///
/// A view model is needed as the item is _live_ - it can be updated remotely, it's file downloaded locally, and so on.
/// A locally downloaded file may also become out of date and need to be re-downloaded. Using a view model allows us to
/// have granular subscriptions to events that are cancelled when the view is no longer in view.
@MainActor
final class FilesItemViewModel: ObservableObject {

    private let nodeID: UUID
    let item: FilesViewItem
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    enum ItemAction {
        case open
        case showVersionHistory
        case edit
        case rename
        case moveToFolder
        case editTags
        case restore
        case deleteToRecycleBin
        case deletePermanently
    }

    let onItemAction: (ItemAction, FilesViewItem) async -> Void

    @Published private var asset: WireCellsLocalAsset?

    @Published var isPresentingDeleteFilePermanentlyConfirmation = false
    @Published var isPresentingDeleteFolderPermanentlyConfirmation = false
    @Published var isPresentingDeleteFileToRecycleBinConfirmation = false
    @Published var isPresentingDeleteFolderToRecycleBinConfirmation = false

    @Published var isPresentingRestoreFileConfirmation = false
    @Published var isPresentingRestoreFolderConfirmation = false
    @Published var isPresentingRestoreParentConfirmation = false

    let fileName: String
    let subtitle: String?
    let icon: FileIcon
    let isInRecycleBin: Bool
    let isFoldersEnabled: Bool

    struct TagsInfo {
        let firstTag: String?
        let additionalTagsIndicator: String?
    }

    private let additionalTagNumberFormatter = {
        let formatter = NumberFormatter()
        formatter.positivePrefix = formatter.plusSign
        return formatter
    }()

    init(
        item: FilesViewItem,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        onItemAction: @escaping (ItemAction, FilesViewItem) async -> Void,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent,
        isInRecycleBin: Bool,
        isFoldersEnabled: Bool

    ) {
        self.nodeID = item.id
        self.item = item
        self.onItemAction = onItemAction
        self.fileName = item.name
        self.subtitle = Self.subtitle(
            modifiedAt: item.modifiedAt,
            ownedBy: item.ownedBy,
            locale: locale,
            calendar: calendar,
            timeZone: timeZone
        )
        self.icon = item.icon
        self.localAssetRepository = localAssetRepository
        self.isInRecycleBin = isInRecycleBin
        self.isFoldersEnabled = isFoldersEnabled

        localAssetRepository.observeAsset(nodeID: nodeID).sink { [weak self] asset in
            self?.asset = asset
        }.store(in: &cancellables)
    }

    var nameOfTopmostFolderInRecycleBin: String {
        item.filePath.split(separator: "/").dropFirst(2).first.flatMap { String($0) } ?? ""
    }

    var isDownloadOptionAvailable: Bool {
        guard item.kind == .file else { return false }

        return switch asset?.downloadState {
        case .downloaded:
            false
        default:
            true
        }
    }

    var isDownloading: Bool {
        switch asset?.downloadState {
        case .downloading:
            true
        default:
            false
        }
    }

    var progress: Double? {
        switch asset?.downloadState {
        case let .downloading(progress):
            progress
        case .failed:
            1 // We show a full red progress bar on failure
        default:
            nil
        }
    }

    var showErrorState: Bool {
        switch asset?.downloadState {
        case .failed:
            true
        default:
            false
        }
    }

    var isEditable: Bool {
        item.isEditable
    }

    func performMenuAction(_ action: ItemAction) {
        switch action {
        case .restore:
            showRestoreConfirmation()
        case .deletePermanently:
            showDeleteConfirmation(deletePermanently: true)
        case .deleteToRecycleBin:
            showDeleteConfirmation(deletePermanently: false)
        default:
            Task { await onItemAction(action, item) }
        }
    }

    func download() async {
        precondition(item.kind == .file)

        // Ignore errors as these will be reported via the `asset` publisher.
        try? await localAssetRepository.downloadAsset(nodeID: nodeID)
    }

    func showDeleteConfirmation(deletePermanently: Bool) {
        switch (deletePermanently, item.kind) {
        case (true, .file):
            isPresentingDeleteFilePermanentlyConfirmation = true
        case (false, .file):
            isPresentingDeleteFileToRecycleBinConfirmation = true
        case (true, .folder):
            isPresentingDeleteFolderPermanentlyConfirmation = true
        case (false, .folder):
            isPresentingDeleteFolderToRecycleBinConfirmation = true
        }
    }

    func showRestoreConfirmation() {
        let isInRecycleBinRoot = item.filePath.split(separator: "/").count <= 3
        if isInRecycleBinRoot {
            switch item.kind {
            case .file:
                isPresentingRestoreFileConfirmation = true
            case .folder:
                isPresentingRestoreFolderConfirmation = true
            }
        } else {
            isPresentingRestoreParentConfirmation = true
        }
    }

    func confirmDelete(permanently: Bool) async {
        if permanently {
            await onItemAction(.deletePermanently, item)
        } else {
            await onItemAction(.deleteToRecycleBin, item)
        }
    }

    func confirmRestore() async {
        await onItemAction(.restore, item)
    }

    static func subtitle(
        modifiedAt: Date?,
        ownedBy: String?,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        let modifiedAt = modifiedAt.map { date in
            let style = Date.FormatStyle(
                date: .abbreviated,
                time: .shortened,
                locale: locale,
                calendar: calendar,
                timeZone: timeZone,
                capitalizationContext: .beginningOfSentence
            )
            return date.formatted(style)
        }
        return if let modifiedAt, let ownedBy {
            L10n.Localizable.Conversation.WireCells.Files.Item.subtitle(modifiedAt, ownedBy)
        } else {
            [modifiedAt, ownedBy].compactMap(\.self).first
        }
    }

    var tagsInfo: TagsInfo {
        let additionalTags = item.tags.count - 1
        let formattedNumber: String? = if additionalTags > 0 {
            additionalTagNumberFormatter.string(for: additionalTags) ?? "+\(additionalTags)"
        } else {
            nil
        }
        return .init(
            firstTag: item.tags.sortedAlphabetically.first,
            additionalTagsIndicator: formattedNumber
        )
    }
}

extension [FilesItemViewModel.ItemAction] {
    static func menuActions(browsing: Bool, recycleBin: Bool, foldersEnabled: Bool, collaboraEnabled: Bool) -> Self {
        var actions: [FilesItemViewModel.ItemAction] = []

        if !recycleBin {
            actions.append(.open)
        }

        if !browsing {
            if !recycleBin {
                if collaboraEnabled {
                    actions.append(.showVersionHistory)
                }
                if foldersEnabled {
                    actions.append(.moveToFolder)
                }
                actions.append(.edit)
                actions.append(.rename)
                actions.append(.editTags)
            }

            if recycleBin {
                actions.append(.restore)
            }

            if recycleBin || !foldersEnabled {
                actions.append(.deletePermanently)
            } else {
                actions.append(.deleteToRecycleBin)
            }
        }

        return actions
    }
}

private extension [String] {
    var sortedAlphabetically: [String] {
        sorted { left, right in
            left.localizedCaseInsensitiveCompare(right) == .orderedAscending
        }
    }
}
