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
import SwiftUI
import UniformTypeIdentifiers
import WireLogging
import WireMessagingDomain

@MainActor
final class WireCellsAttachmentsPreviewItemViewModel: ObservableObject {

    private let fetchNodeUseCase: WireCellsFetchNodeUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    let alignment: HorizontalAlignment

    @Published private var item: WireCellsAttachmentsPreviewViewItem
    @Published var viewingURL: URL?
    @Published private var asset: WireCellsLocalAsset?

    init(
        item: WireCellsAttachmentsPreviewViewItem,
        alignment: HorizontalAlignment,
        fetchNodeUseCase: WireCellsFetchNodeUseCase,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest,
        nodeRenameNotifier: WireCellsNodeRenameNotifier
    ) {
        self.item = item
        self.alignment = alignment
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.lastOpenRequest = lastOpenRequest
        self.nodeRenameNotifier = nodeRenameNotifier
        self.localAssetRepository = localAssetRepository

        setupBindings()
    }

    var headerText: String {
        if item.isDeleted {
            return ""
        } else {
            let fileSize = (item.fileSize?.formatted(.byteCount(style: .decimal)) as String?).map { "(\($0))" }
            return [item.fileExtension?.uppercased(), fileSize].compactMap(\.self).joined(separator: " ")
        }
    }

    var fileName: String {
        item.isDeleted ? L10n.Localizable.Conversation.Message.Attachment.notAvailable : item.fileName ?? ""
    }

    var icon: ImageResource {
        item.isDeleted ? .fileIconNotAvailable : item.fileIcon.resource
    }

    var progress: Double {
        switch asset?.downloadState {
        case let .downloading(progress):
            progress
        case .failed:
            1 // We show a full red progress bar on failure
        default:
            0
        }
    }

    var isError: Bool {
        switch asset?.downloadState {
        case .failed:
            true
        default:
            false
        }
    }

    func refresh() async {
        do {
            for try await node in fetchNodeUseCase.invoke(nodeID: item.nodeID) {
                if let node {
                    item = WireCellsAttachmentsPreviewViewItem(node)
                } else {
                    item = WireCellsAttachmentsPreviewViewItem(
                        nodeID: item.nodeID,
                        fileIcon: item.fileIcon,
                        fileName: item.fileName,
                        fileExtension: item.fileExtension,
                        fileSize: item.fileSize,
                        isDeleted: true
                    )
                }
            }
        } catch {
            WireLogger.wireCells.info("Failed to refresh node with ID: \(item.nodeID), error: \(error)")
        }
    }

    func open() async {
        guard !item.isDeleted, !isDownloading else { return }

        lastOpenRequest.nodeID = item.nodeID

        do {
            let url = try await getAssetUseCase.invoke(nodeID: item.nodeID)
            if lastOpenRequest.nodeID == item.nodeID {
                viewingURL = url
            }
        } catch {
            WireLogger.wireCells.error("Failed to open file with node ID: \(item.nodeID), error: \(error)")
        }
    }

    // MARK: - Private

    private func setupBindings() {
        nodeRenameNotifier.publisher
            .sink { [self] nodeID in
                guard nodeID == item.nodeID else {
                    return
                }

                Task {
                    // this node has been renamed, refresh
                    await self.refresh()
                }
            }.store(in: &cancellables)

        localAssetRepository.observeAsset(nodeID: item.nodeID)
            .sink { [self] asset in
                self.asset = asset
            }.store(in: &cancellables)
    }

    private var fileSize: String? {
        item.fileSize.map { Int($0).formatted(.byteCount(style: .decimal)) }
    }

    private var isDownloading: Bool {
        asset?.downloadState.isDownloading == true
    }

}

private extension WireCellsAttachmentsPreviewViewItem {

    init(_ value: WireCellsMessageAttachment, isDeleted: Bool) {
        let url = value.initialName.flatMap { URL(string: $0) }
        let fileType = value.contentType.flatMap { UTType(mimeType: $0) }
        let fileExtension = url?.pathExtension

        self.nodeID = value.nodeID
        self.fileIcon = .make(type: fileType, fileExtension: fileExtension)
        self.fileName = url?.deletingPathExtension().lastPathComponent
        self.fileExtension = fileExtension
        self.fileSize = value.initialSize
        self.isDeleted = isDeleted
    }

    init(_ value: WireCellsNode) {
        let url = URL(string: value.path)
        let fileType = value.mimeType.flatMap { UTType(mimeType: $0) }
        let fileExtension = url?.pathExtension

        self.nodeID = value.id
        self.fileIcon = .make(type: fileType, fileExtension: value.path)
        self.fileName = url?.deletingPathExtension().lastPathComponent
        self.fileExtension = fileExtension
        self.fileSize = value.size.map { Int($0) }
        self.isDeleted = value.isRecycled
    }

}
