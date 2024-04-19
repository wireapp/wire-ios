//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import XCTest

@testable import Wire

final class BackgroundViewControllerTests: BaseSnapshotTestCase {

    private var sut: BackgroundViewController!

    override func setUp() {
        super.setUp()
        sut = .init(
            accentColor: .init(fromZMAccentColor: .violet),
            imageTransformer: .coreImageBased(context: .shared)
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItShowsUserWithoutImage() throws {
        verify(matching: sut)
    }

    @MainActor
    func testThatItShowsUserWithImage() async throws {

        // WHEN
        let imageData = try XCTUnwrap(image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData())
        try await sut.setBackgroundImage(XCTUnwrap(UIImage(from: imageData, withMaxSize: 40)))

        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromAccentColor() {

        // WHEN
        sut.accentColor = .init(fromZMAccentColor: .brightOrange)

        // THEN
        verify(matching: sut)
    }

    @MainActor
    func testThatItUpdatesForUserAccentColorUpdate_fromUserImage() async throws {

        // WHEN
        let imageData = try XCTUnwrap(image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData())
        try await sut.setBackgroundImage(XCTUnwrap(UIImage(from: imageData, withMaxSize: 40)))
        sut.accentColor = .init(fromZMAccentColor: .brightOrange)

        // THEN
        verify(matching: sut)
    }

    @MainActor
    func testThatItUpdatesForUserImageUpdate_fromUserImage() async throws {

        // WHEN
        let imageData = try XCTUnwrap(image(inTestBundleNamed: "unsplash_burger.jpg").pngData())
        try await sut.setBackgroundImage(XCTUnwrap(UIImage(from: imageData, withMaxSize: 40)))

        // THEN
        verify(matching: sut)
    }
}
