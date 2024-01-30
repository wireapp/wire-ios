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

final class AvailabilityTitleViewTests: ZMSnapshotTestCase {

    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var userSession: UserSessionMock!
    var sut: AvailabilityTitleView!

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

    func testThatItRendersCorrectly_SelfProfile_NoneAvailability() async {
        await createTest(for: .allowSettingStatus, with: .none, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AvailableAvailability() async {
        await createTest(for: .allowSettingStatus, with: .available, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_AwayAvailability() async {
        await createTest(for: .allowSettingStatus, with: .away, on: selfUser)
    }

    func testThatItRendersCorrectly_SelfProfile_BusyAvailability() async {
        await createTest(for: .allowSettingStatus, with: .busy, on: selfUser)
    }

    // MARK: - Headers profile

    func testThatItRendersCorrectly_Header_NoneAvailability_Light() async {
        await createTest(for: .header, with: .none, on: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_NoneAvailability_Dark() async {
        await createTest(for: .header, with: .none, on: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Light() async {
        await createTest(for: .header, with: .available, on: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Dark() async {
        await createTest(for: .header, with: .available, on: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Light() async {
        await createTest(for: .header, with: .away, on: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Dark() async {
        await createTest(for: .header, with: .away, on: selfUser, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_Light() async {
        await createTest(for: .header, with: .busy, on: selfUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_Dark() async {
        await createTest(for: .header, with: .busy, on: selfUser, userInterfaceStyle: .dark)
    }

    // MARK: - Other profile

    func testThatItRendersCorrectly_OtherProfile_NoneAvailability() async {
        await createTest(for: .hideActionHint, with: .none, on: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() async {
        await createTest(for: .hideActionHint, with: .available, on: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() async {
        await createTest(for: .hideActionHint, with: .away, on: otherUser, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() async {
        await createTest(for: .hideActionHint, with: .busy, on: otherUser, userInterfaceStyle: .light)
    }

    // MARK: - Common methods

    @MainActor
    private func createTest(
        for options: AvailabilityTitleView.Options,
        with availability: Availability,
        on user: ZMUser,
        userInterfaceStyle: UIUserInterfaceStyle = .dark,
        file: StaticString = #file,
        line: UInt = #line,
        testName: String = #function
    ) async {
        updateAvailability(for: user, newValue: availability)
        let sut = AvailabilityTitleView(
            user: user,
            options: options,
            userSession: userSession
        )

        sut.overrideUserInterfaceStyle = userInterfaceStyle
        sut.backgroundColor = userInterfaceStyle == .dark ? .black : .white
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        await Task.yield()
        verify(matching: sut, file: file, testName: testName, line: line)
    }

    private func updateAvailability(for user: ZMUser, newValue: Availability) {
        if user == ZMUser.selfUser() {
            user.availability = newValue
        } else {
            // if the user is not self, force the update of the availability
            user.updateAvailability(newValue)
        }
    }
}
