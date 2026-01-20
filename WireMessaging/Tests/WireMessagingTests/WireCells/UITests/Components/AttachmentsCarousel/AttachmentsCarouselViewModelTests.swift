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

import Testing
import UIKit

import Combine

@testable import WireMessagingDomain
@testable import WireMessagingUI

@MainActor
final class AttachmentsCarouselViewModelTests {

    private let thumbnailGenerator = ThumbnailGeneratorMock()
    private lazy var sut = AttachmentsCarouselViewModel(items: [], thumbnailGenerator: thumbnailGenerator)
    private var capturedItems: [[AttachmentsCarouselItem]] = []
    private var cancellables: Set<AnyCancellable> = []

    init() {
        sut.$items.dropFirst().sink { [weak self] items in
            self?.capturedItems.append(items)
        }.store(in: &cancellables)
    }

    @Test
    func updateWhenSuccess() async throws {
        // given
        var imageDraft = WireCellsDraft.fixture(
            versionID: UUID(),
            fileType: .jpeg,
            status: .uploading(progress: 0.5),
            name: "image.jpg",
            bytes: 1024,
        )

        var videoDraft = WireCellsDraft.fixture(
            versionID: UUID(),
            fileType: .mpeg4Movie,
            status: .uploading(progress: 0.5),
            name: "video.mp4",
            bytes: 1_000_000,
        )

        var audioDraft = WireCellsDraft.fixture(
            versionID: UUID(),
            fileType: .mp3,
            status: .uploading(progress: 0.5),
            name: "audio.mp3",
            bytes: 3_000_000,
        )

        var documentDraft = WireCellsDraft.fixture(
            versionID: UUID(),
            fileType: .spreadsheet,
            status: .uploading(progress: 0.5),
            name: "spreadsheet.xlsx",
            bytes: 2_000_000,
        )

        // when
        sut.update(with: [imageDraft, videoDraft, audioDraft, documentDraft])

        try await awaitUntilCapturedItemsCount(3)

        // then 3 updates are expected to be published - an immediate update, and 2 further updates as the image & video
        // thumbnails are generated

        // update 1 - all items are uploading
        var imageItem = AttachmentsCarouselItem(
            id: imageDraft.nodeID,
            state: .uploading(progress: 0.5),
            kind: .image(thumbnail: nil),
            name: "image",
            fileExtension: "jpg",
            size: "1 kB",
            fileIcon: .image
        )

        var videoItem = AttachmentsCarouselItem(
            id: videoDraft.nodeID,
            state: .uploading(progress: 0.5),
            kind: .video(thumbnail: nil),
            name: "video",
            fileExtension: "mp4",
            size: "1 MB",
            fileIcon: .video
        )

        var audioItem = AttachmentsCarouselItem(
            id: audioDraft.nodeID,
            state: .uploading(progress: 0.5),
            kind: .audio(samples: []),
            name: "audio",
            fileExtension: "mp3",
            size: "3 MB",
            fileIcon: .audio
        )

        var documentItem = AttachmentsCarouselItem(
            id: documentDraft.nodeID,
            state: .uploading(progress: 0.5),
            kind: .document,
            name: "spreadsheet",
            fileExtension: "xlsx",
            size: "2 MB",
            fileIcon: .spreadsheet
        )
        #expect(capturedItems[0] == [imageItem, videoItem, audioItem, documentItem])

        // update 2 - all items are uploading, but image OR video thumbnail is generated - it's non deterministic so
        // just a sanity check
        #expect(capturedItems[1].map(\.id) == [imageItem.id, videoItem.id, audioItem.id, documentItem.id])

        // update 3 - all items are uploading, but image AND video thumbnails are generated
        imageItem.kind = .image(thumbnail: UIImage.fixture())
        videoItem.kind = .video(thumbnail: UIImage.fixture())
        #expect(capturedItems[2] == [imageItem, videoItem, audioItem, documentItem])

        // when upload completes
        imageDraft.status = .uploaded(isDraft: true)
        videoDraft.status = .uploaded(isDraft: true)
        audioDraft.status = .uploaded(isDraft: true)
        documentDraft.status = .uploaded(isDraft: true)

        sut.update(with: [imageDraft, videoDraft, audioDraft, documentDraft])

        try await awaitUntilCapturedItemsCount(4)

        // then a final update is expected
        imageItem.state = .uploaded
        videoItem.state = .uploaded
        audioItem.state = .uploaded
        documentItem.state = .uploaded
        #expect(capturedItems[3] == [imageItem, videoItem, audioItem, documentItem])
    }

    @Test
    func updateWhenFailure() async throws {
        // given
        var documentDraft = WireCellsDraft.fixture(
            versionID: UUID(),
            fileType: .spreadsheet,
            status: .uploading(progress: 0.5),
            name: "spreadsheet.xlsx",
            bytes: 2_000_000,
        )

        // when
        sut.update(with: [documentDraft])

        documentDraft.status = .failed(error: .fileNotFound)
        sut.update(with: [documentDraft])

        try await awaitUntilCapturedItemsCount(2)

        // then
        try #require(capturedItems.count == 2)

        // update 1 - document uploading
        var documentItem = AttachmentsCarouselItem(
            id: documentDraft.nodeID,
            state: .uploading(progress: 0.5),
            kind: .document,
            name: "spreadsheet",
            fileExtension: "xlsx",
            size: "2 MB",
            fileIcon: .spreadsheet
        )
        #expect(capturedItems[0] == [documentItem])

        // update 2 - document upload failed
        documentItem.state = .failed
        #expect(capturedItems[1] == [documentItem])
    }

    func awaitUntilCapturedItemsCount(_ count: Int) async throws {
        guard capturedItems.count < count else { return }

        for await _ in sut.$items.values where capturedItems.count >= count {
            break
        }
    }

}

private actor ThumbnailGeneratorMock: ThumbnailGenerator {

    func generateThumbnail(fileAt url: URL, size: CGSize, scale: Double) async throws -> UIImage {
        UIImage.fixture()
    }

}
