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
        createTest(options: .header, userName: selfUser.name ?? "", availability: .available, userInterfaceStyle: .light, isMLSCertified: true)
    }

    func testThatItRendersCorrectly_Header_AvailableAvailability_Certified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .available, userInterfaceStyle: .dark, isMLSCertified: true)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Verified_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .away, userInterfaceStyle: .light, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_AwayAvailability_Verified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .away, userInterfaceStyle: .dark, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_CertifiedAndVerified_Light() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .busy, userInterfaceStyle: .light, isMLSCertified: true, isProteusVerified: true)
    }

    func testThatItRendersCorrectly_Header_BusyAvailability_CertifiedAndVerified_Dark() {
        createTest(options: .header, userName: selfUser.name ?? "", availability: .busy, userInterfaceStyle: .dark, isMLSCertified: true, isProteusVerified: true)
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
        isMLSCertified: Bool = false,
        isProteusVerified: Bool = false,
        file: StaticString = #file,
        line: UInt = #line,
        testName: String = #function
    ) {
        let sut = UserStatusView(
            options: options,
            userSession: userSession
        )
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        sut.backgroundColor = .systemBackground
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        sut.userStatus = .init(
            name: userName,
            availability: availability,
            isCertified: isMLSCertified,
            isVerified: isProteusVerified
        )

        verify(matching: sut, file: file, testName: testName, line: line)
    }
}
