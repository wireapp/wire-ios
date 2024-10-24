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

import WireTestingPackage
import XCTest

@testable import Wire
@testable import WireSyncEngineSupport

final class UserStatusViewSnapshotTests: ZMSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var selfUser: ZMUser!
    private var otherUser: ZMUser!
    private var userSession: UserSessionMock!
    private var sut: UserStatusView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.name = "Giovanni"
        selfUser = ZMUser.selfUser()
        userSession = UserSessionMock()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        selfUser = nil
        otherUser = nil
        userSession = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    // MARK: - Self Profile

    func testThatItRendersCorrectly_SelfProfile_NoneAvailability() {
        createTest(options: .allowSettingStatus, userName: selfUser.name ?? "", availability: .none)
    }

    func testThatItRendersCorrectly_SelfProfile_AvailableAvailability() {
        createTest(options: .allowSettingStatus, userName: selfUser.name ?? "", availability: .available)
    }

    func testThatItRendersCorrectly_SelfProfile_AwayAvailability() {
        createTest(options: .allowSettingStatus, userName: selfUser.name ?? "", availability: .away)
    }

    func testThatItRendersCorrectly_SelfProfile_BusyAvailability() {
        createTest(options: .allowSettingStatus, userName: selfUser.name ?? "", availability: .busy)
    }

    // MARK: - Headers profile

    func testThatItRendersCorrectly_Header_NoneAvailability_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .none, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_Header_NoneAvailability_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .none, userInterfaceStyle: .dark)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Certified_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .available, userInterfaceStyle: .light, isE2EICertified: true)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Certified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .available, userInterfaceStyle: .dark, isE2EICertified: true)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Verified_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .away, userInterfaceStyle: .light, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Verified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .away, userInterfaceStyle: .dark, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_CertifiedAndVerified_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .busy, userInterfaceStyle: .light, isE2EICertified: true, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_CertifiedAndVerified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .busy, userInterfaceStyle: .dark, isE2EICertified: true, isProteusVerified: true)
    }

    // MARK: - Other profile

    func testThatItRendersCorrectly_OtherProfile_NoneAvailability() {
        createTest(options: .hideActionHint, userName: otherUser.name ?? "", availability: .none, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() {
        createTest(options: .hideActionHint, userName: otherUser.name ?? "", availability: .available, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() {
        createTest(options: .hideActionHint, userName: otherUser.name ?? "", availability: .away, userInterfaceStyle: .light)
    }

    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() {
        createTest(options: .hideActionHint, userName: otherUser.name ?? "", availability: .busy, userInterfaceStyle: .light)
    }

    // MARK: - Common methods

    private func createTest(
        options: UserStatusView.Options,
        userName: String,
        availability: Availability,
        userInterfaceStyle: UIUserInterfaceStyle = .dark,
        isE2EICertified: Bool = false,
        isProteusVerified: Bool = false,
        file: StaticString = #file,
        line: UInt = #line,
        testName: String = #function
    ) {
        let sut = UserStatusView(options: options)
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        sut.backgroundColor = .systemBackground
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        sut.userStatus = .init(
            displayName: userName,
            availability: availability,
            isE2EICertified: isE2EICertified,
            isProteusVerified: isProteusVerified
        )
        snapshotHelper
            .withUserInterfaceStyle(userInterfaceStyle)
            .verify(matching: sut, file: file, testName: testName, line: line)
    }
}
