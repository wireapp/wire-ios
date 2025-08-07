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

import Testing
import UIKit

@testable import WireMessagingDomain
@testable import WireMessagingUI

@MainActor
final class AttachmentsCarouselViewModelTests {

    private let thumbnailGenerator = ThumbnailGeneratorMock()

    @Test func updateWhenSuccess() async throws {
        let sut = AttachmentsCarouselViewModel(items: [], thumbnailGenerator: thumbnailGenerator)
        var capturesUpdates: [[AttachmentsCarouselItem]] = []

        let itemUpdates = sut.$items.values

        var imageDraft = WireCellsDraft.fixture(
            fileType: .jpeg,
            status: .uploading(progress: 0.5),
            name: "image.jpg",
            bytes: 1024,
        )

        var videoDraft = WireCellsDraft.fixture(
            fileType: .mpeg4Movie,
            status: .uploading(progress: 0.5),
            name: "video.mp4",
            bytes: 1_000_000,
        )

        var audioDraft = WireCellsDraft.fixture(
            fileType: .mp3,
            status: .uploading(progress: 0.5),
            name: "audio.mp3",
            bytes: 3_000_000,
        )

        var documentDraft = WireCellsDraft.fixture(
            fileType: .spreadsheet,
            status: .uploading(progress: 0.5),
            name: "spreadsheet.xlsx",
            bytes: 2_000_000,
        )

        sut.update(with: [imageDraft, videoDraft, audioDraft, documentDraft])

        for await update in itemUpdates.prefix(3) {
            capturesUpdates.append(update)
        }

        // when uploading completes
        imageDraft.status = .uploaded(isDraft: true)
        videoDraft.status = .uploaded(isDraft: true)
        audioDraft.status = .uploaded(isDraft: true)
        documentDraft.status = .uploaded(isDraft: true)


        sut.update(with: [imageDraft, videoDraft, audioDraft, documentDraft])

        // wait for the next update
        for await update in itemUpdates.prefix(1) { capturesUpdates.append(update) }

        // then

        // first update
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

        try #require(capturesUpdates.count == 4)
        #expect(capturesUpdates[0] == [imageItem, videoItem, audioItem, documentItem])

        // second update
        // Either the image OR video thumbnail has been generated so it is hard to test. Lets just sanity check.
        #expect(capturesUpdates[1].map { $0.id } == [imageItem.id, videoItem.id, audioItem.id, documentItem.id])

        // third update
        imageItem.kind = .image(thumbnail: UIImage.fixture())
        videoItem.kind = .video(thumbnail: UIImage.fixture())
        #expect(capturesUpdates[2] == [imageItem, videoItem, audioItem, documentItem])

        // forth update
        imageItem.state = .uploaded
        videoItem.state = .uploaded
        audioItem.state = .uploaded
        documentItem.state = .uploaded
        #expect(capturesUpdates[3] == [imageItem, videoItem, audioItem, documentItem])
    }

}

private actor ThumbnailGeneratorMock: ThumbnailGenerator {

    func generateThumbnail(fileAt url: URL, size: CGSize, scale: Double) async throws -> UIImage {
        return UIImage.fixture()
    }

}
