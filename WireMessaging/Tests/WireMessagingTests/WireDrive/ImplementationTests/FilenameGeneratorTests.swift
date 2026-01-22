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
import Testing
import UniformTypeIdentifiers

@testable import WireMessagingDomain

struct FilenameGeneratorTests {

    let sut = FilenameGenerator(date: { try! Date("2023-10-01T12:10:05Z", strategy: .iso8601) })

    @Test
    func generateFilenames() async {
        #expect(await sut.generateFilename(type: .png) == "IMG_20231001_121005.png")
        #expect(await sut.generateFilename(type: .png) == "IMG_20231001_121005_1.png")
        #expect(await sut.generateFilename(type: .png) == "IMG_20231001_121005_2.png")
        #expect(await sut.generateFilename(type: .jpeg) == "IMG_20231001_121005.jpeg")
        #expect(await sut.generateFilename(type: .jpeg) == "IMG_20231001_121005_1.jpeg")
        #expect(await sut.generateFilename(type: .plainText) == "FILE_20231001_121005.txt")
        #expect(await sut.generateFilename(type: .plainText) == "FILE_20231001_121005_1.txt")
        #expect(await sut.generateFilename(type: .image) == "IMG_20231001_121005")
        #expect(await sut.generateFilename(type: .image) == "IMG_20231001_121005_1")
    }

}
