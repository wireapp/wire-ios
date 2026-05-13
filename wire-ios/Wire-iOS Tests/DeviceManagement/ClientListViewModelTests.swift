//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class ClientListViewModelTests: XCTestCase, CoreDataFixtureTestHelper {

    var coreDataFixture: CoreDataFixture!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        coreDataFixture = try await CoreDataFixture()
    }

    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }

    @MainActor
    func testItBuildsCurrentAndActiveSections() throws {
        let selfClient = mockUserClient()
        let otherClient = mockUserClient()

        let sut = ClientListViewModel(
            clientsList: [selfClient, otherClient],
            selfClient: selfClient,
            showTemporary: true,
            showLegalHold: true,
            showsDeviceDetails: true
        )

        XCTAssertEqual(sut.numberOfSections, 2)
        XCTAssertEqual(sut.numberOfRows(in: 0), 1)
        XCTAssertEqual(sut.numberOfRows(in: 1), 1)
        XCTAssertFalse(try XCTUnwrap(sut.rowModel(at: IndexPath(row: 0, section: 0))).isEditable)
        XCTAssertTrue(try XCTUnwrap(sut.rowModel(at: IndexPath(row: 0, section: 1))).isEditable)
    }

    @MainActor
    func testItSortsActiveClientsByActivationDateDescending() {
        let olderClient = mockUserClient()
        olderClient.activationDate = Date(timeIntervalSince1970: 1)
        olderClient.model = "older"

        let newerClient = mockUserClient()
        newerClient.activationDate = Date(timeIntervalSince1970: 2)
        newerClient.model = "newer"

        let sut = ClientListViewModel(
            clientsList: [olderClient, newerClient],
            selfClient: nil,
            showTemporary: true,
            showLegalHold: true,
            showsDeviceDetails: true
        )

        XCTAssertEqual(sut.rowModel(at: IndexPath(row: 0, section: 0))?.cellViewModel.title, "newer")
        XCTAssertEqual(sut.rowModel(at: IndexPath(row: 1, section: 0))?.cellViewModel.title, "older")
    }

    @MainActor
    func testItDisablesEditingWhenThereAreNoActiveClients() {
        let selfClient = mockUserClient()
        let sut = ClientListViewModel(
            clientsList: [selfClient],
            selfClient: selfClient,
            showTemporary: true,
            showLegalHold: true,
            showsDeviceDetails: true
        )

        sut.setEditing(true)

        XCTAssertFalse(sut.isEditing)
        XCTAssertFalse(sut.showsEditButton)
        XCTAssertFalse(sut.hidesBackButton)
    }

    @MainActor
    func testItRoutesSelectionToDeviceDetailsWhenEnabled() {
        let client = mockUserClient()
        let sut = ClientListViewModel(
            clientsList: [client],
            selfClient: nil,
            showTemporary: true,
            showLegalHold: true,
            showsDeviceDetails: true
        )

        guard case let .deviceDetails(selectedClient) = sut.routeForSelectingRow(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("Expected device details route")
        }

        XCTAssertTrue(selectedClient === client)
    }

}
