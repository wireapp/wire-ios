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

import WireMessagingDomain
import WireDataModel
import Combine
import UniformTypeIdentifiers
import WireMessagingUI

final class MessageReplyAttachmentsViewModel {
    private let fetchNodeUseCase: any WireCellsFetchNodeUseCaseProtocol
    private var task: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private let cache = UIImage.defaultUserImageCache.cache
    
    struct PreviewImageInfo {
        let image: UIImage
        let isVideo: Bool
    }
    
    @Published var previewImageInfo: PreviewImageInfo?
    
    init(fetchNodeUseCase: any WireCellsFetchNodeUseCaseProtocol) {
        self.fetchNodeUseCase = fetchNodeUseCase
    }
    
    // MARK: - Public
    
    func loadPreviewImage(
        for attachment: MultipartMessageData.Attachment
    ) {
        task = Task { [weak self] in
            guard let self else { return }

            guard let node = try? await fetchNodeUseCase
                .invoke(nodeID: attachment.nodeID)
                .compactMap(\.self)
                .first(where: { $0.id == attachment.nodeID })
            else { return }

            setPreviewImage(from: node, isVideo: attachment.isVideo)
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        subscriptions.removeAll()
    }
    
    // MARK: - Private

    private func setPreviewImage(
        from node: WireCellsNode,
        isVideo: Bool
    ) {
        guard let smallPreview = node.previews.min(by: {
            $0.dimension < $1.dimension
        }) else { return }

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

        URLSession.shared.dataTaskPublisher(for: smallPreview.url)
            .map(\.data)
            .compactMap(UIImage.init(data:))
            .handleEvents(receiveOutput: { [weak self] image in
                guard let self else { return }
                cache.setObject(image, forKey: cacheKey)
            })
            .map { PreviewImageInfo(image: $0, isVideo: isVideo) }
            .sink { _ in } receiveValue: { [weak self] in
                guard let self else { return }
                previewImageInfo = $0
            }.store(in: &subscriptions)
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
}
