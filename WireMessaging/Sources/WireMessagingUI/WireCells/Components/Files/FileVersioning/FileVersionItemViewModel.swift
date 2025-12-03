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
import WireFoundation
import WireMessagingDomain

@MainActor
final class FileVersionItemViewModel: ObservableObject {

    private let nodeID: UUID
    private let versionID: UUID
    private let onRestore: (FileVersionItem) async -> Void
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private var subscriptions = Set<AnyCancellable>()

    let item: FileVersionItem
    let accentColor: WireAccentColor

    @Published private var asset: WireCellsLocalAsset?

    var isDownloadOptionAvailable: Bool {
        switch asset?.downloadState {
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

    init(
        nodeID: UUID,
        item: FileVersionItem,
        accentColor: WireAccentColor,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        onRestore: @escaping (FileVersionItem) async -> Void
    ) {
        self.nodeID = nodeID
        self.versionID = item.id
        self.item = item
        self.accentColor = accentColor
        self.onRestore = onRestore
        self.localAssetRepository = localAssetRepository

        localAssetRepository.observeAsset(nodeID: item.id)
            .sink { [weak self] asset in
                self?.asset = asset
            }.store(in: &subscriptions)
    }

    func restore() async {
        await onRestore(item)
    }

    func download() async {
        try? await localAssetRepository.downloadAsset(source: .nodeVersion(node: nodeID, version: item.id))
    }
}
