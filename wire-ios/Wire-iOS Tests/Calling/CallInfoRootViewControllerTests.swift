//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import SnapshotTesting
import WireUtilities

final class CallInfoRootViewControllerTests: ZMSnapshotTestCase {

    var sut: CallInfoRootViewController!
    var mockSelfUser: MockUserType!
    var mockOtherUser: MockUserType!
    var mockUsers: [MockUserType]!
    var defaultFixture: CallInfoTestFixture!

    override func setUp() {
        super.setUp()

        mockOtherUser = MockUserType.createConnectedUser(name: "Bruno", inTeam: nil)
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        mockUsers = SwiftMockLoader.mockUsers()
        defaultFixture = CallInfoTestFixture(otherUser: mockOtherUser, selfUser: mockSelfUser, mockUsers: mockUsers)
        CallingConfiguration.config = .largeConferenceCalls

        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.deprecatedCallingUI
        flag.isOn = true
    }

    override func tearDown() {
        sut = nil
        mockSelfUser = nil
        mockOtherUser = nil
        mockUsers = nil
        defaultFixture = nil
        CallingConfiguration.resetDefaultConfig()

        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneOutgoingAudioRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedVBR() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedPhoneX() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        _ = verifySnapshot(matching: sut,
                           as: .image(on: SnapshotTesting.ViewImageConfig.iPhoneX),
                           snapshotDirectory: snapshotDirectory(file: #file))
    }

    func testOneToOneAudioEstablishedPoorConnection() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedPoorNetwork, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Group Audio

    func testGroupOutgoingAudioRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_SmallGroup() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        isRecording = true
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, selfUser: mockSelfUser, groupSize: .small, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_LargeGroup() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser,
                                          selfUser: mockSelfUser,
                                          groupSize: .large,
                                          mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() throws  {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedScreenSharing() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedScreenSharing, selfUser: mockSelfUser)
        
        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Landscape
    func disable_testOneToOneAudioOutgoingLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneOutgoingAudioRinging)
    }

    func disable_testOneToOneAudioIncomingLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneIncomingAudioRinging)
    }

    func disable_testOneToOneAudioEstablishedLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneAudioEstablished)
    }

    func testLandscape(configuration: CallInfoViewControllerInput, testName: String = #function) {
        sut = CallInfoRootViewController(configuration: configuration, selfUser: mockSelfUser)
        XCUIDevice.shared.orientation = .landscapeLeft
        let mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut)
        mockParentViewController.setOverrideTraitCollection(UITraitCollection(verticalSizeClass: .compact), forChild: sut)

        // then
        verifyAllIPhoneSizes(matching: mockParentViewController, orientation: .landscape, testName: testName)
    }

    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    // MARK: - Classification

    func testOneToOneClassifiedIncomingVideoRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedIncomingVideoRinging() throws {
        throw XCTSkip("this is old UI new PR is updating these screenshots")
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
}
