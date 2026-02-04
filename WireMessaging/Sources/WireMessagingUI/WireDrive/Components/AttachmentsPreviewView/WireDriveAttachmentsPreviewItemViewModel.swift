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
import SwiftUI
import UniformTypeIdentifiers
import WireLogging
import WireMessagingDomain

@MainActor
final class WireDriveAttachmentsPreviewItemViewModel: ObservableObject {

    enum DisplayStyle {
        case small
        case large
    }

    private let attachment: WireDriveMessageAttachment
    private let fetchCachedNodeUseCase: any WireDriveFetchCachedNodeUseCaseProtocol
    private let fetchNodeUseCase: WireDriveFetchNodeUseCase
    private let getAssetUseCase: WireDriveGetAssetUseCase
    private let lastOpenRequest: WireDriveLastOpenRequest
    private let nodeRenameNotifier: WireDriveNodeRenameNotifier
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let _displayStyle: DisplayStyle
    private var cancellables = Set<AnyCancellable>()
    private var pollingTask: Task<Void, Never>?

    let alignment: HorizontalAlignment

    @Published private var asset: WireDriveLocalAsset?
    @Published private var node: WireDriveNode?
    @Published private var isDeleted: Bool

    init(
        attachment: WireDriveMessageAttachment,
        alignment: HorizontalAlignment,
        fetchCachedNodeUseCase: any WireDriveFetchCachedNodeUseCaseProtocol,
        fetchNodeUseCase: WireDriveFetchNodeUseCase,
        getAssetUseCase: WireDriveGetAssetUseCase,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        lastOpenRequest: WireDriveLastOpenRequest,
        nodeRenameNotifier: WireDriveNodeRenameNotifier,
        displayStyle: DisplayStyle
    ) {
        self.attachment = attachment
        self.alignment = alignment
        self.fetchCachedNodeUseCase = fetchCachedNodeUseCase
        self.fetchNodeUseCase = fetchNodeUseCase
        self.getAssetUseCase = getAssetUseCase
        self.lastOpenRequest = lastOpenRequest
        self.nodeRenameNotifier = nodeRenameNotifier
        self.localAssetRepository = localAssetRepository
        self._displayStyle = displayStyle
        self.isDeleted = false

        setupBindings()

        if let cacheInfo = fetchCachedNodeUseCase.invoke(nodeID: attachment.nodeID) {
            updateNode(cacheInfo.node)
        }
    }

    var displayStyle: DisplayStyle {
        isDeleted ? .small : _displayStyle
    }

    var fileCategory: WireDriveFileCategory {
        if isDeleted {
            return .document
        }

        let fileType = contentType.flatMap { UTType(mimeType: $0) }
        return WireDriveFileCategory(fileType)
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
        preview?.url
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

    private var preview: WireDriveNodePreview? {
        node?.previews.sorted(by: { $0.dimension < $1.dimension }).last
    }

    private var isProcessing: Bool {
        preview?.processing ?? false
    }

    func refresh() async {
        do {
            let node = try await fetchNodeUseCase.invoke(nodeID: nodeID)
            updateNode(node)
        } catch {
            WireLogger.wireDrive.info("Failed to refresh node with ID: \(nodeID), error: \(error)")
        }
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }

            // Initial previews may not be immediately available after upload.
            // While the preview is still being processed, poll the server more frequently,
            // using an exponential backoff capped at 32 seconds.
            var initialPreviewSleep = 1
            let maxInitialPreviewSleep = 32

            let normalSleep = 30

            while !Task.isCancelled {
                await refresh()

                let needsInitialPreviewPolling = imagePreviewURL == nil && isProcessing
                let sleepSeconds = needsInitialPreviewPolling ? initialPreviewSleep : normalSleep

                try? await Task.sleep(for: .seconds(sleepSeconds))

                if needsInitialPreviewPolling {
                    initialPreviewSleep = min(initialPreviewSleep * 2, maxInitialPreviewSleep)
                }
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func open() async {
        guard !isDeleted, !isDownloading else { return }

        lastOpenRequest.nodeID = nodeID

        do {
            let url = try await getAssetUseCase.invoke(nodeID: nodeID, eTag: eTag)
            if lastOpenRequest.nodeID == nodeID {
                QuickLookPreviewPresenter.present(url: url)
            }
        } catch {
            WireLogger.wireDrive.error("Failed to open file with node ID: \(nodeID), error: \(error)")
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

    private func updateNode(_ node: WireDriveNode?) {
        self.node = node
        if let node {
            isDeleted = node.isRecycled
        } else {
            isDeleted = true
        }
    }

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
            .sink { [weak self] nodeID in
                guard nodeID == self?.attachment.nodeID else {
                    return
                }

                Task {
                    // this node has been renamed, refresh
                    await self?.refresh()
                }
            }.store(in: &cancellables)

        localAssetRepository.observeAsset(nodeID: attachment.nodeID)
            .sink { [weak self] asset in
                self?.asset = asset
            }.store(in: &cancellables)
    }

}
