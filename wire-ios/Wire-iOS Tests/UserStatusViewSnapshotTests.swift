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
@testable import WireSyncEngineSupport

final class UserStatusViewSnapshotTests: ZMSnapshotTestCase {

    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var userSession: UserSessionMock!
    var sut: UserStatusView!

    override func setUp() {
        super.setUp()

        otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.name = "Giovanni"
        selfUser = ZMUser.selfUser()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        selfUser = nil
        otherUser = nil
        userSession = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Self Profile

    func testThatItRendersCorrectly_SelfProfile_NoneAvailability() {
        createTest(options: .allowSettingStatus, availability: .none, user: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AvailableAvailability() {
        createTest(options: .allowSettingStatus, availability: .available, user: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AwayAvailability() {
        createTest(options: .allowSettingStatus, availability: .away, user: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_BusyAvailability() {
        createTest(options: .allowSettingStatus, availability: .busy, user: selfUser)
    }

    // MARK: - Headers profile

    func testThatItRendersCorrectly_Header_NoneAvailability_Light() {
        createTest(options: .header, availability: .none, user: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_NoneAvailability_Dark() {
        createTest(options: .header, availability: .none, user: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Light() {
        createTest(options: .header, availability: .available, user: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Dark() {
        createTest(options: .header, availability: .available, user: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Light() {
        createTest(options: .header, availability: .away, user: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Dark() {
        createTest(options: .header, availability: .away, user: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_Light() {
        createTest(options: .header, availability: .busy, user: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_Dark() {
        createTest(options: .header, availability: .busy, user: selfUser, userInterfaceStyle: .dark)
    }

    // MARK: - Other profile

    func testThatItRendersCorrectly_OtherProfile_NoneAvailability() {
        createTest(options: .hideActionHint, availability: .none, user: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() {
        createTest(options: .hideActionHint, availability: .available, user: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() {
        createTest(options: .hideActionHint, availability: .away, user: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() {
        createTest(options: .hideActionHint, availability: .busy, user: otherUser, userInterfaceStyle: .light)
    }

    // MARK: - Common methods

    private func createTest(
        options: UserStatusView.Options,
        availability: Availability,
        user: ZMUser,
        userInterfaceStyle: UIUserInterfaceStyle = .dark,
        file: StaticString = #file,
        line: UInt = #line,
        testName: String = #function
    ) {
        let sut = UserStatusView(
            options: options,
            userSession: userSession
        )
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        sut.backgroundColor = userInterfaceStyle == .dark ? .black : .white
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        sut.userStatus = .init(
            name: user.name ?? "",
            availability: availability,
            isCertified: false,
            isVerified: false
        )
        verify(matching: sut, file: file, testName: testName, line: line)
    }
}
