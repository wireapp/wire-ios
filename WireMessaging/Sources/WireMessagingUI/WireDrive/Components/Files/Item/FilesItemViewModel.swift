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
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// A view model for a single item in the `FilesView`.
///
/// A view model is needed as the item is _live_ - it can be updated remotely, it's file downloaded locally, and so on.
/// A locally downloaded file may also become out of date and need to be re-downloaded. Using a view model allows us to
/// have granular subscriptions to events that are cancelled when the view is no longer in view.
@MainActor
final class FilesItemViewModel: ObservableObject {

    private let nodeID: UUID
    let item: FilesViewItem
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    enum ItemAction {
        case open
        case showVersionHistory
        case edit
        case rename
        case moveToFolder
        case editTags
        case shareLink
        case restore
        case deleteToRecycleBin
        case deletePermanently
    }

    let onItemAction: (ItemAction, FilesViewItem) async -> Void

    @Published private var asset: WireDriveLocalAsset?

    @Published var isPresentingDeleteFilePermanentlyConfirmation = false
    @Published var isPresentingDeleteFolderPermanentlyConfirmation = false
    @Published var isPresentingDeleteFileToRecycleBinConfirmation = false
    @Published var isPresentingDeleteFolderToRecycleBinConfirmation = false
    @Published var isPresentingRestoreFileConfirmation = false
    @Published var isPresentingRestoreFolderConfirmation = false
    @Published var isPresentingRestoreParentConfirmation = false
    @Published var menuActions: Set<ItemAction> = []

    let fileName: String
    let subtitle: String?
    let icon: WireDriveFileType

    let isBrowsing: Bool
    let isInRecycleBin: Bool

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
        selectedSortingKey: FilesSortingViewModel.SortingKey?,
        conversationName: String?,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        onItemAction: @escaping (ItemAction, FilesViewItem) async -> Void,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent,
        isBrowsing: Bool,
        isInRecycleBin: Bool
    ) {
        self.nodeID = item.id
        self.item = item
        self.onItemAction = onItemAction
        self.fileName = item.name
        self.subtitle = Self.subtitle(
            selectedSortingKey: selectedSortingKey,
            isBrowsing: isBrowsing,
            conversationName: conversationName,
            modifiedAt: item.modifiedAt,
            size: item.size,
            ownedBy: item.ownedBy,
            locale: locale,
            calendar: calendar,
            timeZone: timeZone
        )
        self.icon = item.icon
        self.localAssetRepository = localAssetRepository

        self.isBrowsing = isBrowsing
        self.isInRecycleBin = isInRecycleBin

        self.menuActions = makeMenuActions()

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

    private static func subtitle(
        selectedSortingKey: FilesSortingViewModel.SortingKey?,
        isBrowsing: Bool,
        conversationName: String?,
        modifiedAt: Date?,
        size: UInt64?,
        ownedBy: String?,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        if isBrowsing {
            switch selectedSortingKey {
            case .date:
                if let conversationName, let date = formattedDate(
                    modifiedAt: modifiedAt,
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                ) {
                    Strings.AllFiles.Item.subtitle(date, conversationName)
                } else {
                    defaultSubtitle(
                        conversationName: conversationName,
                        modifiedAt: modifiedAt,
                        ownedBy: ownedBy,
                        locale: locale,
                        calendar: calendar,
                        timeZone: timeZone
                    )
                }
            case .name:
                if let conversationName, let ownedBy {
                    Strings.AllFiles.Item.subtitle(ownedBy, conversationName)
                } else {
                    defaultSubtitle(
                        conversationName: conversationName,
                        modifiedAt: modifiedAt,
                        ownedBy: ownedBy,
                        locale: locale,
                        calendar: calendar,
                        timeZone: timeZone
                    )
                }
            case .size:
                if let conversationName, let size = formattedFileSize(size: size) {
                    Strings.AllFiles.Item.subtitle(size, conversationName)
                } else {
                    defaultSubtitle(
                        conversationName: conversationName,
                        modifiedAt: modifiedAt,
                        ownedBy: ownedBy,
                        locale: locale,
                        calendar: calendar,
                        timeZone: timeZone
                    )
                }
            default:
                defaultSubtitle(
                    conversationName: conversationName,
                    modifiedAt: modifiedAt,
                    ownedBy: ownedBy,
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                )
            }
        } else {
            switch selectedSortingKey {
            case .date:
                if let ownedBy {
                    Strings.Files.Item.subtitle(Strings.Sorting.Key.date, ownedBy)
                } else {
                    defaultSubtitle(
                        modifiedAt: modifiedAt,
                        ownedBy: ownedBy,
                        locale: locale,
                        calendar: calendar,
                        timeZone: timeZone
                    )
                }
            case .name:
                defaultSubtitle(
                    modifiedAt: modifiedAt,
                    ownedBy: ownedBy,
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                )
            case .size:
                if let size = formattedFileSize(size: size), let ownedBy {
                    Strings.Files.Item.subtitle(size, ownedBy)
                } else {
                    defaultSubtitle(
                        modifiedAt: modifiedAt,
                        ownedBy: ownedBy,
                        locale: locale,
                        calendar: calendar,
                        timeZone: timeZone
                    )
                }
            default:
                defaultSubtitle(
                    modifiedAt: modifiedAt,
                    ownedBy: ownedBy,
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                )
            }
        }

    }

    private static func formattedFileSize(size: UInt64?) -> String? {
        guard let size else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private static func formattedDate(
        modifiedAt: Date?,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        modifiedAt.map { date in
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
    }

    private static func defaultSubtitle(
        conversationName: String? = nil,
        modifiedAt: Date?,
        ownedBy: String?,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        let modifiedAt = formattedDate(modifiedAt: modifiedAt, locale: locale, calendar: calendar, timeZone: timeZone)

        if let conversationName, let ownedBy {
            return L10n.Localizable.Conversation.WireCells.AllFiles.Item.subtitle(ownedBy, conversationName)
        } else {
            return if let modifiedAt, let ownedBy {
                L10n.Localizable.Conversation.WireCells.Files.Item.subtitle(modifiedAt, ownedBy)
            } else {
                [modifiedAt, ownedBy].compactMap(\.self).first
            }
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

    private func makeMenuActions() -> Set<ItemAction> {
        var actions: Set<ItemAction> = []

        if !isInRecycleBin {
            actions.insert(.open)
            actions.insert(.shareLink)
        }

        if !isBrowsing {
            if isInRecycleBin {
                actions.insert(.restore)
                actions.insert(.deletePermanently)
            } else {
                if item.kind == .file {
                    actions.insert(.showVersionHistory)
                }
                actions.insert(.moveToFolder)
                actions.insert(.rename)
                actions.insert(.editTags)
                actions.insert(.deleteToRecycleBin)

                if isEditable {
                    actions.insert(.edit)
                }
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
