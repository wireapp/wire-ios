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

struct WireCellsDraftMetadataRepositoryTests {

    private let sut = WireCellsDraftMetadataRepository()

    @Test func testImageMetadata() async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: "animated", withExtension: "gif"))

        // when
        let metadata = try await sut.imageMetadata(fileURL: fileURL)

        // then
        #expect(metadata == .image(width: 640, height: 400))
    }

    @Test func testVideoMetadata() async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: "video", withExtension: "mp4"))

        // when
        let metadata = try await sut.videoMetadata(fileURL: fileURL)

        // then
        #expect(metadata == .video(width: 568, height: 320, duration: 3003))
    }

    @Test func testAudioMetadata() async throws {
        // given
        let fileURL = try #require(Bundle.module.url(forResource: "audio", withExtension: "m4a"))

        // when
        let metadata = try await sut.audioMetadata(fileURL: fileURL)

        // then
        #expect(metadata ==  .audio(duration: 934))
    }

}
