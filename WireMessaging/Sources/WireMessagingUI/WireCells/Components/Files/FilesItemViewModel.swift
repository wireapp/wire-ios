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
    private let item: FilesViewItem
    private let onOpen: (FilesViewItem) async -> Void
    private let onDelete: (FilesViewItem) async -> Void
    private let onRename: ((FilesViewItem) async -> Void)?
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published private var asset: WireCellsLocalAsset?
    @Published var isShowDeleteConfirmation = false

    let fileName: String
    let subtitle: String?
    let icon: FileIcon

    init(
        item: FilesViewItem,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        onOpen: @escaping (FilesViewItem) async -> Void,
        onDelete: @escaping (FilesViewItem) async -> Void,
        onRename: ((FilesViewItem) async -> Void)? = nil,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        self.nodeID = item.id
        self.item = item
        self.onOpen = onOpen
        self.onDelete = onDelete
        self.onRename = onRename
        self.fileName = item.filename
        self.subtitle = Self.subtitle(from: item, locale: locale, calendar: calendar, timeZone: timeZone)
        self.icon = item.icon
        self.localAssetRepository = localAssetRepository

        localAssetRepository.observeAsset(nodeID: nodeID).sink { [self] asset in
            self.asset = asset
        }.store(in: &cancellables)
    }

    var isDownloadOptionAvailable: Bool {
        switch asset?.downloadState {
        case .downloaded:
            true
        default:
            false
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

    func open() async {
        await onOpen(item)
    }

    func rename() async {
        await onRename?(item)
    }

    func download() async {
        // Ignore errors as these will be reported via the `asset` publisher.
        try? await localAssetRepository.downloadAsset(nodeID: nodeID)
    }

    func showDeleteConfirmation() {
        isShowDeleteConfirmation = true
    }

    func confirmDelete() async {
        await onDelete(item)
    }

    private static func subtitle(
        from item: FilesViewItem,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        let modifiedAt = item.modifiedAt.map { date in
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
        return if let modifiedAt, let ownedBy = item.ownedBy {
            L10n.Localizable.Conversation.WireCells.Files.Item.subtitle(modifiedAt, ownedBy)
        } else {
            [modifiedAt, item.ownedBy].compactMap(\.self).first
        }
    }

}
