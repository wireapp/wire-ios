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
import WireLocators
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// A view model for a single item in the `FilesView`.
///
/// A view model is needed as the item is _live_ - it can be updated remotely, it's file downloaded locally, and so on.
/// A locally downloaded file may also become out of date and need to be re-downloaded. Using a view model allows us to
/// have granular subscriptions to events that are cancelled when the view is no longer in view.
@MainActor
final class FilesItemViewModel: ObservableObject {

    private let nodeID: UUID
    let item: FilesViewItem
    private let observeAssetUseCase: WireDriveObserveAssetUseCase
    private let getAssetUseCase: WireDriveGetAssetUseCase
    private var cancellables = Set<AnyCancellable>()

    enum ItemAction {
        /// Can be open, download or cancel download, depening on the state of the file
        case primaryAction
        case showVersionHistory
        case edit
        case rename
        case moveToFolder
        case editTags
        case shareLink
        case restore
        case deleteToRecycleBin
        case deletePermanently
        case makeAvailableOffline
        case removeAvailableOffline
    }

    let onItemAction: (ItemAction, FilesViewItem) async -> Void

    @Published private var asset: WireDriveLocalAsset?
    @Published var fileTracker: WireDriveFileUITracker
    @Published var isPresentingDeleteFilePermanentlyConfirmation = false
    @Published var isPresentingDeleteFolderPermanentlyConfirmation = false
    @Published var isPresentingDeleteFileToRecycleBinConfirmation = false
    @Published var isPresentingDeleteFolderToRecycleBinConfirmation = false
    @Published var isPresentingRestoreFileConfirmation = false
    @Published var isPresentingRestoreFolderConfirmation = false
    @Published var isPresentingRestoreParentConfirmation = false

    @Published private var networkMonitor = NetworkMonitor.shared

    let fileName: String
    let subtitle: String?
    let icon: WireDriveFileType
    let isBrowsing: Bool
    let isInRecycleBin: Bool

    // TODO: [WPB-25941] Remove drive permissions flag when feature is complete
    // TODO: [WPB-19065] Use DeveloperFlag from WireFoundation package when migrated
    var isDrivePermissionsFlagEnabled: Bool = UserDefaults.standard.bool(forKey: "enableDrivePermissions")

    var showReadOnlyIcon: Bool {
        isDrivePermissionsFlagEnabled && item.isReadOnly && isBrowsing
    }

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
        observeAssetUseCase: WireDriveObserveAssetUseCase,
        getAssetUseCase: WireDriveGetAssetUseCase,
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
        self.observeAssetUseCase = observeAssetUseCase
        self.getAssetUseCase = getAssetUseCase

        self.isBrowsing = isBrowsing
        self.isInRecycleBin = isInRecycleBin

        self.fileTracker = .init()
        fileTracker.onSmallFileLoaded = { [weak self] in
            guard let asset = self?.asset, !asset.isAvailableOffline else { return }
            self?.performAction(.primaryAction)
        }

        observeAssetUseCase.invoke(nodeID: nodeID).sink { [weak self] asset in
            guard let self else { return }
            self.asset = asset
            if let asset {
                fileTracker.handleDownloadState(fromAsset: asset)
            }
        }.store(in: &cancellables)
    }

    var nameOfTopmostFolderInRecycleBin: String {
        item.filePath.split(separator: "/").dropFirst(2).first.flatMap { String($0) } ?? ""
    }

    var isDownloadOptionAvailable: Bool {
        guard item.kind == .file, !isOffline else { return false }

        return switch fileTracker.state {
        case .loaded:
            false
        default:
            true
        }
    }

    var isDownloadingForOfflineUse: Bool {
        switch fileTracker.state {
        case .loading where asset?.isAvailableOffline == true:
            true
        default:
            false
        }
    }

    var isDownloading: Bool {
        switch fileTracker.state {
        case .loading:
            true
        default:
            false
        }
    }

    var isEditable: Bool {
        item.isEditable
    }

    func isActionDisabled(_ action: ItemAction) -> Bool {
        switch action {
        case .shareLink, .makeAvailableOffline, .removeAvailableOffline:
            isDrivePermissionsFlagEnabled && item.isReadOnly && isBrowsing
        default:
            false
        }
    }

    func accessibilitylabel(for action: ItemAction) -> String {
        switch action {
        case .makeAvailableOffline where showReadOnlyIcon:
            Accessibility.Files.ViewerAccess.makeAvailableOffline
        case .shareLink where showReadOnlyIcon:
            Accessibility.Files.ViewerAccess.shareLink
        case .deletePermanently:
            Locators.WireDrive.RecycleBinPage.deletePermanently.rawValue
        default:
            "\(action)"
        }
    }

    func performAction(_ action: ItemAction) {
        switch action {
        case .restore:
            showRestoreConfirmation()
        case .deletePermanently:
            showDeleteConfirmation(deletePermanently: true)
        case .deleteToRecycleBin:
            showDeleteConfirmation(deletePermanently: false)
        case .makeAvailableOffline, .removeAvailableOffline:
            Task { await onItemAction(action, item) }
        default:
            Task { await onItemAction(action, item) }
        }
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
            if let asset, asset.isAvailableOffline {
                await onItemAction(.removeAvailableOffline, item)
            }
            await onItemAction(.deleteToRecycleBin, item)
        }
    }

    func confirmRestore() async {
        await onItemAction(.restore, item)
    }

    var isOffline: Bool {
        networkMonitor.currentStatus == .disconnected
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

    var menuActions: Set<ItemAction> {
        let isViewerMode = item.isReadOnly && isDrivePermissionsFlagEnabled

        if isViewerMode {
            return viewerMenuActions
        } else {
            return editorMenuActions
        }

    }

    private var viewerMenuActions: Set<ItemAction> {
        var actions: Set<ItemAction> = []

        actions.insert(.primaryAction)

        if !isInRecycleBin, !isOffline, isBrowsing {
            actions.insert(.shareLink) // action visible to the user but disabled
        }

        if !isEditable, !isInRecycleBin, isBrowsing, item.kind == .file {
            // actions visible to the user but disabled
            if isAvailableOffline {
                actions.insert(.removeAvailableOffline)
            } else {
                if !isOffline {
                    actions.insert(.makeAvailableOffline)
                }
            }
        }

        return actions
    }

    private var editorMenuActions: Set<ItemAction> {
        var actions: Set<ItemAction> = []

        actions.insert(.primaryAction)

        if !isInRecycleBin, !isOffline {
            actions.insert(.shareLink)
        }

        if !isEditable, !isInRecycleBin, item.kind == .file {
            if isAvailableOffline {
                actions.insert(.removeAvailableOffline)
            } else {
                if !isOffline {
                    actions.insert(.makeAvailableOffline)
                }
            }
        }

        if !isBrowsing, !isOffline {
            if isInRecycleBin {
                actions.formUnion([.restore, .deletePermanently])
            } else {
                if item.kind == .file, isEditable {
                    actions.insert(.showVersionHistory)
                }
                actions.formUnion([
                    .moveToFolder,
                    .rename,
                    .editTags,
                    .deleteToRecycleBin
                ])

                if isEditable {
                    actions.insert(.edit)
                }
            }
        }

        return actions
    }

    var isAvailableOffline: Bool {
        let isAvailableOffline = (try? getAssetUseCase.asset(nodeID: nodeID)?.isAvailableOffline) ?? false
        let isDownloaded = switch fileTracker.state {
        case .loaded:
            true
        default:
            false
        }

        let isFolder = item.kind == .folder

        return isAvailableOffline && isDownloaded && !isFolder
    }
}

// MARK: - Formatting

private extension FilesItemViewModel {
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
        var primary: String?

        if isBrowsing {
            switch selectedSortingKey {
            case .date:
                if let conversationName,
                   let date = formattedDate(
                       modifiedAt: modifiedAt,
                       locale: locale,
                       calendar: calendar,
                       timeZone: timeZone
                   ) {
                    primary = Strings.AllFiles.Item.subtitle(date, conversationName)
                }
            case .name:
                if let conversationName, let ownedBy {
                    primary = Strings.AllFiles.Item.subtitle(ownedBy, conversationName)
                }
            case .size:
                if let conversationName {
                    let size = formattedFileSize(size: size)
                    primary = Strings.AllFiles.Item.subtitle(size, conversationName)
                }
            default:
                break
            }

            return primary ?? defaultSubtitle(
                conversationName: conversationName,
                modifiedAt: modifiedAt,
                ownedBy: ownedBy,
                locale: locale,
                calendar: calendar,
                timeZone: timeZone
            )

        } else {
            switch selectedSortingKey {
            case .date:
                if let ownedBy, let date = formattedDate(
                    modifiedAt: modifiedAt,
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                ) {
                    primary = Strings.Files.Item.subtitle(date, ownedBy)
                }
            case .size:
                if let ownedBy {
                    let size = formattedFileSize(size: size)
                    primary = Strings.Files.Item.subtitle(size, ownedBy)
                }
            default:
                break
            }

            return primary ?? defaultSubtitle(
                modifiedAt: modifiedAt,
                ownedBy: ownedBy,
                locale: locale,
                calendar: calendar,
                timeZone: timeZone
            )
        }
    }

    private static func formattedFileSize(size: UInt64?) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(size ?? 0))
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
}

private extension [String] {
    var sortedAlphabetically: [String] {
        sorted { left, right in
            left.localizedCaseInsensitiveCompare(right) == .orderedAscending
        }
    }
}
