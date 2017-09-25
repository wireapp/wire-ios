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
@testable import WireDataModel


final class AccountTests: ZMConversationTestsBase {

    func testThatItCanSerializeAnAccountToDisk() throws {
        // given
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/AccountTests")
        defer { try? FileManager.default.removeItem(at: url) }

        let account = Account(
            userName: "Bruno",
            userIdentifier: .create(),
            teamName: "Wire",
            imageData: verySmallJPEGData()
        )

        // when
        try account.write(to: url)

        // then the test did not fail
    }

    func testThatItCanLoadAnAccountFromDisk() throws {
        // given
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/AccountTests")
        defer { try? FileManager.default.removeItem(at: url) }
        let userName = "Bruno", team = "Wire", id = UUID.create(), image = verySmallJPEGData(), count = 14

        // we create and store an account
        do {
            let account = Account(userName: userName,
                                  userIdentifier: id,
                                  teamName: team,
                                  imageData: image,
                                  unreadConversationCount: count)
            try account.write(to: url)
        }

        // when
        guard let account = Account.load(from: url) else { return XCTFail("Unable to load account") }

        // then
        XCTAssertEqual(account.userName, userName)
        XCTAssertEqual(account.teamName, team)
        XCTAssertEqual(account.userIdentifier, id)
        XCTAssertEqual(account.imageData, image)
        XCTAssertEqual(account.unreadConversationCount, count)
    }

}
