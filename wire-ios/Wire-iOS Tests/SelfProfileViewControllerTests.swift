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

import WireDataModelSupport
import WireDesign
import WireTestingPackage
import XCTest

@testable import Wire

final class SelfProfileViewControllerTests: XCTestCase, CoreDataFixtureTestHelper {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    var coreDataFixture: CoreDataFixture!
    private var sut: SelfProfileViewController!
    private var selfUser: MockUserType!
    private var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        coreDataFixture = CoreDataFixture()

        SelfUser.provider = coreDataFixture.selfUserProvider
        selfUser = MockUserType.createSelfUser(name: "", inTeam: UUID())

        userSession = UserSessionMock(mockUser: selfUser)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        coreDataFixture = nil
        SelfUser.provider = nil
        selfUser = nil
        userSession = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForAUserWithNoTeam() {
        createSut(userName: "Tarja Turunen", teamMember: false)
        snapshotHelper.verify(matching: sut.view)
    }

    func testForAUserWithALongName() {
        createSut(userName: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", teamMember: true)
        snapshotHelper.verify(matching: sut.view)
    }

    // MARK: - Unit Tests

    func testItRequestsToRefreshTeamMetadataIfSelfUserIsTeamMember() {
        createSut(userName: "Tarja Turunen", teamMember: true)
        XCTAssertEqual(selfUser.refreshTeamDataCount, 1)
    }

    func testItDoesNotRequestToRefreshTeamMetadataIfSelfUserIsNotTeamMember() {
        createSut(userName: "Tarja Turunen", teamMember: false)
        XCTAssertEqual(selfUser.refreshTeamDataCount, 0)
    }

    func testContentOfLoginAlertController_WithASingleClient() throws {
        // GIVEN
        let mockClient = MockUserClient()
        mockClient.model = "iPhone X"
        mockClient.activationDate = Calendar.current.date(from: DateComponents(year: 2022, month: 1, day: 1))

        let model = try XCTUnwrap(mockClient.model, "Model is nil")
        let activationDate = try XCTUnwrap(mockClient.activationDate, "Activation date is nil")
        let formattedDate = activationDate.formattedDate

        let clients = [mockClient]

        // WHEN
        let alertController = UIAlertController(forNewSelfClients: clients)

        let deviceActivationDate = L10n.Localizable.Registration.Devices.activated(formattedDate)
        let expectedDeviceNameAndDate = "\(model) \(deviceActivationDate)"

        let expectedTitle = L10n.Localizable.Self.NewDeviceAlert.title
        let expectedMessage = L10n.Localizable.Self.NewDeviceAlert.message(expectedDeviceNameAndDate)

        let actualMessage = try XCTUnwrap(alertController.message, "AlertController's message is nil.")

        // THEN
        XCTAssertEqual(alertController.title, expectedTitle)
        XCTAssertEqual(actualMessage, expectedMessage)
    }

    func testContentOfLoginAlertController_WithMultipleClients() throws {
        // GIVEN
        let mockClient1 = MockUserClient()
        mockClient1.model = "iPhone X"
        mockClient1.activationDate = Calendar.current.date(from: DateComponents(year: 2022, month: 1, day: 1))

        let mockClient2 = MockUserClient()
        mockClient2.model = "iPad Pro"
        mockClient2.activationDate = Calendar.current.date(from: DateComponents(year: 2022, month: 1, day: 2))

        let clients = [mockClient1, mockClient2]

        // WHEN
        let alertController = UIAlertController(forNewSelfClients: clients)

        var expectedDeviceNameAndDates = [String]()
        for client in clients {
            let model = try XCTUnwrap(client.model, "Model is nil")
            let activationDate = try XCTUnwrap(client.activationDate, "Activation date is nil")
            let formattedDate = activationDate.formattedDate
            let deviceActivationDate = L10n.Localizable.Registration.Devices.activated(formattedDate)
            expectedDeviceNameAndDates.append("\(model) \(deviceActivationDate)")
        }

        let expectedDevicesNameAndDate = expectedDeviceNameAndDates.joined(separator: "\n\n")
        let expectedTitle = L10n.Localizable.Self.NewDeviceAlert.title
        let expectedMessage = L10n.Localizable.Self.NewDeviceAlert.messagePlural(expectedDevicesNameAndDate)

        let actualMessage = try XCTUnwrap(alertController.message, "AlertController's message is nil.")

        // THEN
        XCTAssertEqual(alertController.title, expectedTitle)
        XCTAssertEqual(actualMessage, expectedMessage)
    }

    // MARK: Helper Method

    private func createSut(userName: String, teamMember: Bool) {
        // prevent app crash when checking Analytics.shared.isOptout
        Analytics.shared = Analytics(optedOut: true)
        selfUser = MockUserType.createSelfUser(name: userName, inTeam: teamMember ? UUID() : nil)
        sut = SelfProfileViewController(
            selfUser: selfUser,
            userRightInterfaceType: MockUserRight.self,
            userSession: userSession,
            accountSelector: MockAccountSelector()
        )
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault
    }
}
