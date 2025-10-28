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

import Foundation
import Testing

@testable import WireMessagingData
@testable import WireMessagingDomain

struct WireCellsDraftMetadataRepositoryTests {

    typealias Metadata = WireCellsDraft.Metadata

    private let sut = WireCellsDraftMetadataRepository()

    @Test(arguments: [
        (name: "animated.gif", expected: Metadata.image(width: 640, height: 400)),
        (name: "orientation_1.png", expected: Metadata.image(width: 400, height: 250)),
        (name: "orientation_2.png", expected: Metadata.image(width: 400, height: 250)),
        (name: "orientation_3.png", expected: Metadata.image(width: 400, height: 250)),
        (name: "orientation_4.png", expected: Metadata.image(width: 400, height: 250)),
        (name: "orientation_5.png", expected: Metadata.image(width: 250, height: 400)),
        (name: "orientation_6.png", expected: Metadata.image(width: 250, height: 400)),
        (name: "orientation_7.png", expected: Metadata.image(width: 250, height: 400)),
        (name: "orientation_8.png", expected: Metadata.image(width: 250, height: 400))
    ])
    func testImageMetadata(name: String, expected: Metadata) async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: name, withExtension: nil))

        // when
        let metadata = try await sut.imageMetadata(fileURL: fileURL)

        // then
        #expect(metadata == expected)
    }

    @Test(arguments: [
        (name: "video_portrait.mp4", expected: Metadata.video(width: 360, height: 480, duration: 1623)),
        (name: "video_portrait_upside_down.mp4", expected: Metadata.video(width: 360, height: 480, duration: 1208)),
        (name: "video_landscape_left.mp4", expected: Metadata.video(width: 480, height: 360, duration: 1083)),
        (name: "video_landscape_right.mp4", expected: Metadata.video(width: 480, height: 360, duration: 1123))
    ])
    func testVideoMetadata(name: String, expected: Metadata) async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: name, withExtension: nil))

        // when
        let metadata = try await sut.videoMetadata(fileURL: fileURL)

        // then
        #expect(metadata == expected)
    }

    @Test
    func testAudioMetadata() async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: "audio", withExtension: "m4a"))

        // when
        let metadata = try await sut.audioMetadata(fileURL: fileURL)

        // then
        #expect(metadata == .audio(duration: 934))
    }

}
