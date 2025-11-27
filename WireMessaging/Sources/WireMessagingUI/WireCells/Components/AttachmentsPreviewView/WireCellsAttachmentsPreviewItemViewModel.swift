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

    enum DisplayStyle {
        case small
        case large
    }

    private let attachment: WireCellsMessageAttachment
    private let fetchNodeUseCase: WireCellsFetchNodeUseCase
    private let getAssetUseCase: WireCellsGetAssetUseCase
    private let lastOpenRequest: WireCellsLastOpenRequest
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    let alignment: HorizontalAlignment
    let displayStyle: DisplayStyle

    @Published var viewingURL: URL?
    @Published private var asset: WireCellsLocalAsset?
    @Published private var node: WireCellsNode?
    @Published private var isDeleted: Bool

    init(
        attachment: WireCellsMessageAttachment,
        alignment: HorizontalAlignment,
        fetchNodeUseCase: WireCellsFetchNodeUseCase,
        getAssetUseCase: WireCellsGetAssetUseCase,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        lastOpenRequest: WireCellsLastOpenRequest,
        nodeRenameNotifier: WireCellsNodeRenameNotifier,
        displayStyle: DisplayStyle
    ) {
        self.attachment = attachment
        self.alignment = alignment
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.lastOpenRequest = lastOpenRequest
        self.nodeRenameNotifier = nodeRenameNotifier
        self.localAssetRepository = localAssetRepository
        self.displayStyle = displayStyle
        self.isDeleted = false

        setupBindings()
    }

    var fileCategory: WireCellsFileCategory {
        let fileType = contentType.flatMap { UTType(mimeType: $0) }
        return WireCellsFileCategory(fileType)
    }

    var headerText: String {
        if isDeleted {
            return ""
        } else {
            let fileSizeString = fileSize.map { "(\($0))" }
            let fileExtension = pathURL?.pathExtension.uppercased()
            return [fileExtension, fileSizeString].compactMap(\.self).joined(separator: " ")
        }
    }

    var fileName: String {
        if isDeleted {
            L10n.Localizable.Conversation.Message.Attachment.notAvailable
        } else {
            pathURL?.deletingPathExtension().lastPathComponent ?? ""
        }
    }

    var icon: ImageResource {
        if isDeleted {
            return .fileIconNotAvailable
        } else {
            let fileType = contentType.flatMap { UTType(mimeType: $0) }
            let fileExtension = pathURL?.pathExtension
            return FileIcon.make(type: fileType, fileExtension: fileExtension).resource
        }
    }

    var imagePreviewURL: URL? {
        node?.previews.sorted(by: { $0.dimension < $1.dimension }).last?.url
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

    var isAssetDownloadError: Bool {
        switch asset?.downloadState {
        case .failed:
            true
        default:
            false
        }
    }

    func refresh() async {
        do {
            for try await node in fetchNodeUseCase.invoke(nodeID: nodeID) {
                self.node = node

                if let node {
                    isDeleted = node.isRecycled
                } else {
                    isDeleted = true
                }
            }
        } catch {
            WireLogger.wireCells.info("Failed to refresh node with ID: \(nodeID), error: \(error)")
        }
    }

    func open() async {
        guard !isDeleted, !isDownloading else { return }

        lastOpenRequest.nodeID = nodeID

        do {
            let url = try await getAssetUseCase.invoke(nodeID: nodeID, eTag: eTag)
            if lastOpenRequest.nodeID == nodeID {
                viewingURL = url
            }
        } catch {
            WireLogger.wireCells.error("Failed to open file with node ID: \(nodeID), error: \(error)")
        }
    }

    private var previewSize: CGSize? {
        guard let size = attachment.initialMetadata?.dimension, size.width > 0, size.height > 0 else {
            return nil
        }

        return size
    }

    var previewAspectRatio: Double {
        guard let size = previewSize else { return 1 }

        return size.width / size.height
    }

    var previewWidth: Double? {
        previewSize?.width as? Double // Explicit conversion necessary due to compiler bug
    }

    var attachmentDuration: String? {
        let fileType = attachment.contentType.flatMap { UTType(mimeType: $0) }

        guard fileType == .video || fileType == .audio else {
            return nil
        }

        guard let durationInMS = attachment.initialMetadata?.duration else {
            return nil
        }

        let duration = Duration.milliseconds(durationInMS)
        return duration.formatted(.time(pattern: .minuteSecond))
    }

    // MARK: - Private

    private var nodeID: UUID {
        node?.id ?? attachment.nodeID
    }

    private var eTag: String? {
        node?.eTag
    }

    private var pathURL: URL? {
        let path = node?.path ?? attachment.initialName
        return path.flatMap { URL(string: $0) }

    }

    private var contentType: String? {
        node?.mimeType ?? attachment.contentType
    }

    private var fileSize: String? {
        let fileSize = node?.size.map { Int($0) } ?? attachment.initialSize
        return fileSize.map { $0.formatted(.byteCount(style: .decimal)) }
    }

    private var isDownloading: Bool {
        asset?.downloadState.isDownloading == true
    }

    private func setupBindings() {
        nodeRenameNotifier.publisher
            .sink { [self] nodeID in
                guard nodeID == attachment.nodeID else {
                    return
                }

                Task {
                    // this node has been renamed, refresh
                    await self.refresh()
                }
            }.store(in: &cancellables)

        localAssetRepository.observeAsset(nodeID: attachment.nodeID)
            .sink { [self] asset in
                self.asset = asset
            }.store(in: &cancellables)
    }

}
