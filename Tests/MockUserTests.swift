//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import WireMockTransport

class MockUserTests: MockTransportSessionTests {
    func testImageAccessorsReturnsCorrectImages() {
        // GIVEN
        let user = sut.insertUser(withName: "some")
        
        // WHEN
        var pictures = sut.addProfilePicture(to: user)
        
        // THEN
        XCTAssertEqual(user.mediumImage, pictures["medium"])
        XCTAssertEqual(user.smallProfileImage, pictures["smallProfile"])
        XCTAssertEqual(user.mediumImageIdentifier, pictures["medium"]?.identifier)
        XCTAssertEqual(user.smallProfileImageIdentifier, pictures["smallProfile"]?.identifier)
    }
    
    func testThatProfileImageV3IsSetCorrectly() {
        // GIVEN
        let user = sut.insertUser(withName: "some")
        
        // WHEN
        var pictures = sut.addV3ProfilePicture(to: user)

        // THEN
        XCTAssertEqual(user.previewProfileAssetIdentifier, pictures["preview"]?.identifier)
        XCTAssertEqual(user.completeProfileAssetIdentifier, pictures["complete"]?.identifier)

    }
}
