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

import XCTest
@testable import Wire

final class AvailabilityTitleViewTests: ZMSnapshotTestCase {

    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var userSession: UserSessionMock!
    var sut: AvailabilityTitleView!

    override func setUp() {
        super.setUp()

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser?.name = "Giovanni"
        selfUser = ZMUser.selfUser()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        userSession = nil
        selfUser = nil
        otherUser = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Self Profile

    func testThatItRendersCorrectly_SelfProfile_NoneAvailability() {
        createTest(for: [.allowSettingStatus], with: .none, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AvailableAvailability() {
        createTest(for: [.allowSettingStatus], with: .available, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AwayAvailability() {
        createTest(for: [.allowSettingStatus], with: .away, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_BusyAvailability() {
        createTest(for: [.allowSettingStatus], with: .busy, on: selfUser)
    }

    // MARK: - Headers profile

    func testThatItRendersCorrectly_Header_NoneAvailability() {
        createTest(for: .header, with: .none, on: selfUser)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability() {
        createTest(for: .header, with: .available, on: selfUser)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability() {
        createTest(for: .header, with: .away, on: selfUser)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability() {
        createTest(for: .header, with: .busy, on: selfUser)
    }

    // MARK: - Other profile

    func testThatItRendersCorrectly_OtherProfile_NoneAvailability() {
        createTest(for: [.hideActionHint], with: .none, on: otherUser!, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() {
        createTest(for: [.hideActionHint], with: .available, on: otherUser!, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() {
        createTest(for: [.hideActionHint], with: .away, on: otherUser!, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() {
        createTest(for: [.hideActionHint], with: .busy, on: otherUser!, userInterfaceStyle: .light)
    }

    // MARK: - Common methods

    private func createTest(
        for options: AvailabilityTitleView.Options,
        with availability: Availability,
        on user: ZMUser,
        userInterfaceStyle: UIUserInterfaceStyle = .dark,
        file: StaticString = #file,
        line: UInt = #line,
        testName: String = #function
    ) {
        updateAvailability(for: user, newValue: availability)

        sut = AvailabilityTitleView(user: user, options: options, userSession: userSession)
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        sut.backgroundColor = .systemBackground
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))

        verify(matching: sut, file: file, testName: testName, line: line)
    }

    func updateAvailability(for user: ZMUser, newValue: Availability) {
        if user == ZMUser.selfUser() {
            user.availability = newValue
        } else {
            // if the user is not self, force the update of the availability
            user.updateAvailability(newValue)
        }
    }
}
