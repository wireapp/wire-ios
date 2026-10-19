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

import Foundation

enum TestServiceMediaFixtures {

    struct MediaURLs {
        let imageURL: URL
        let imageExtension: String
        let gifURL: URL
        let gifType: String
        let videoURL: URL
        let videoExtension: String
    }

    static func mediaURLs(relativeTo filePath: String) -> MediaURLs {
        let testDataDirectory = URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData")

        let imageURL = testDataDirectory.appendingPathComponent("Img/testImage.jpg")
        let gifURL = testDataDirectory.appendingPathComponent("Img/testGIF.gif")
        let videoURL = testDataDirectory.appendingPathComponent("Video/testVideo.mp4")

        return MediaURLs(
            imageURL: imageURL,
            imageExtension: imageURL.pathExtension,
            gifURL: gifURL,
            gifType: "image/gif",
            videoURL: videoURL,
            videoExtension: videoURL.pathExtension
        )
    }

    static func audioMetadata() -> [String: Any] {
        [
            "durationInMillis": 5000,
            "normalizedLoudness": (0 ..< 10).map { _ in Int.random(in: 0 ... 255) }
        ]
    }
}
