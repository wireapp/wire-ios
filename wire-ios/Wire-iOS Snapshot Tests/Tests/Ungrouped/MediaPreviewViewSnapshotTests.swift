//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class MediaPreviewViewSnapshotTests: XCTestCase {

    var sut: MediaPreviewView!

    override func setUp() {
        super.setUp()

        sut = MediaPreviewView()
        sut.titleLabel.text = "Demo Media"
        sut.previewImageView.image = image(inTestBundleNamed: "unsplash_matterhorn.jpg")

        // MediaPreviewView is portrait in messsage cell
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }
}
