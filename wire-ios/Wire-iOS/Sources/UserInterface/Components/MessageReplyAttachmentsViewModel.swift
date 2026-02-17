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

import UniformTypeIdentifiers
import WireDataModel
import WireMessagingDomain
import WireMessagingUI

final class MessageReplyAttachmentsViewModel {
    private let fetchCachedNodeUseCase: any WireDriveFetchCachedNodeUseCaseProtocol
    private let fetchNodeUseCase: any WireDriveFetchNodeUseCaseProtocol
    private var task: Task<Void, Error>?
    private var fetchVisibleNodeIDsTask: Task<Set<UUID>, Error>?
    private let cache = UIImage.defaultUserImageCache.cache

    struct PreviewImageInfo {
        let image: UIImage
        let isVideo: Bool
    }

    @Published var previewImageInfo: PreviewImageInfo?

    init(
        fetchCachedNodeUseCase: any WireDriveFetchCachedNodeUseCaseProtocol,
        fetchNodeUseCase: any WireDriveFetchNodeUseCaseProtocol
    ) {
        self.fetchCachedNodeUseCase = fetchCachedNodeUseCase
        self.fetchNodeUseCase = fetchNodeUseCase
    }

    // MARK: - Public

    func loadPreviewImage(
        for attachment: MultipartMessageData.Attachment
    ) {
        task = Task { [weak self] in
            guard let self else { return }

            guard let node = try? await fetchNodeUseCase.invoke(nodeID: attachment.nodeID) else { return }

            try await downloadImage(
                from: node,
                isVideo: attachment.isVideo
            )
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        fetchVisibleNodeIDsTask?.cancel()
        fetchVisibleNodeIDsTask = nil
    }

    @MainActor
    func cachedVisibleAttachments(attachments: [MultipartMessageData.Attachment]) -> [MultipartMessageData.Attachment] {
        attachments.filter { attachment in
            if let cacheInfo = fetchCachedNodeUseCase.invoke(nodeID: attachment.nodeID) {
                !cacheInfo.isDeletedOrRecycled
            } else {
                true // If we have no cache info, assume it is not deleted
            }
        }
    }

    @MainActor
    func latestVisibleAttachments(
        attachments: [MultipartMessageData.Attachment]
    ) async throws -> [MultipartMessageData.Attachment] {
        let task = Task { [fetchNodeUseCase] in
            try await withThrowingTaskGroup(of: WireDriveNode?.self, returning: Set<UUID>.self) { group in
                for attachment in attachments {
                    group.addTask { try await fetchNodeUseCase.invoke(nodeID: attachment.nodeID) }
                }

                return try await group.reduce(into: Set<UUID>()) { result, node in
                    if let node, !node.isRecycled {
                        result.insert(node.id)
                    }
                }
            }
        }
        fetchVisibleNodeIDsTask = task

        let visibleNodeIDs = try await task.value
        return attachments.filter { visibleNodeIDs.contains($0.nodeID) }
    }

    // MARK: - Private

    private func downloadImage(
        from node: WireDriveNode,
        isVideo: Bool
    ) async throws {
        guard let smallPreview = node.previews.min(by: {
            $0.dimension < $1.dimension
        }), let smallPreviewURL = smallPreview.url else { return }

        let cacheKey: NSString = {
            if let eTag = node.eTag {
                return "\(node.id.uuidString)-\(eTag)" as NSString
            }
            return node.id.uuidString as NSString
        }()

        if let cachedImage = cache.object(forKey: cacheKey) {
            previewImageInfo = .init(image: cachedImage, isVideo: isVideo)
            return
        }

        guard task?.isCancelled == false else { return }

        let (data, _) = try await URLSession.shared.data(from: smallPreviewURL)
        guard let image = UIImage(data: data) else { return }
        cache.setObject(image, forKey: cacheKey)
        previewImageInfo = PreviewImageInfo(image: image, isVideo: isVideo)
    }
}

extension MultipartMessageData.Attachment {
    var filePreviewInfo: (UIImage, String) {
        let fileType = contentType.flatMap { UTType(mimeType: $0) }
        let fileURL = initialName.flatMap(URL.init(string:))

        let icon = FileIcon.make(
            type: fileType,
            fileExtension: fileURL?.pathExtension
        ).image

        let filename = fileURL?
            .deletingPathExtension()
            .lastPathComponent ?? ""

        return (icon, filename)
    }

    var isVideo: Bool {
        switch initialMetadata {
        case .video:
            true
        default:
            false
        }
    }

    var isImage: Bool {
        switch initialMetadata {
        case .image:
            true
        default:
            false
        }
    }
}
