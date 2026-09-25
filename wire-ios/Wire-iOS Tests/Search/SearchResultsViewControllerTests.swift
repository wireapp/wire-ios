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

import UIKit
import XCTest
@testable import Wire
@testable import WireSyncEngine

final class SearchResultsViewControllerTests: XCTestCase {
    weak var sut: SearchResultsViewController!
    private var coreDataFixture: CoreDataFixture!

    override func setUp() async throws {
        try await super.setUp()
        coreDataFixture = try await CoreDataFixture()
    }

    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }

    @MainActor
    func testThatUpdateSectionsKeepsSearchUserBackedApps_ButExcludesExistingParticipants() throws {
        let uiMOC = coreDataFixture.uiMOC!
        let selfUser = coreDataFixture.selfUser!
        let existingParticipantApp = coreDataFixture.otherUser!
        existingParticipantApp.type = .app

        let conversation = ZMConversation.createGroupConversation(
            moc: uiMOC,
            otherUser: existingParticipantApp,
            selfUser: selfUser
        )

        // A collaborator app already known locally as a `ZMUser`, but NOT a participant of this conversation -
        // wrapped in `ZMSearchUser`, as every apps search result is.
        let knownCollaboratorAppUser = coreDataFixture.createUser(name: "Collaborator App")
        knownCollaboratorAppUser.type = .app
        let knownCollaboratorAppSearchResult = ZMSearchUser(
            viewContext: uiMOC,
            name: "Collaborator App",
            handle: "collaborator-app",
            accentColor: nil,
            remoteIdentifier: knownCollaboratorAppUser.remoteIdentifier,
            domain: knownCollaboratorAppUser.domain,
            teamIdentifier: knownCollaboratorAppUser.teamIdentifier,
            providerIdentifier: nil,
            user: knownCollaboratorAppUser,
            searchUsersCache: nil,
            type: .app,
            summary: nil,
            isDeleted: false
        )

        // A collaborator app not known locally at all (no backing `ZMUser`) - the common case for apps
        // resolved purely from `/teams/:tid/collaborators` + `/users`.
        let remoteOnlyAppSearchResult = ZMSearchUser(
            viewContext: uiMOC,
            name: "Remote-Only App",
            handle: "remote-only-app",
            accentColor: nil,
            remoteIdentifier: UUID(),
            domain: nil,
            teamIdentifier: UUID(),
            providerIdentifier: nil,
            user: nil,
            searchUsersCache: nil,
            type: .app,
            summary: nil,
            isDeleted: false
        )

        var searchResult = SearchResult()
        searchResult.apps = [existingParticipantApp, knownCollaboratorAppSearchResult, remoteOnlyAppSearchResult]

        let mockUserSession = UserSessionMock(mockUser: MockUserType.createSelfUser(name: selfUser.name ?? ""))
        let sut = try XCTUnwrap(SearchResultsViewController(
            userSelection: UserSelection(),
            userSession: mockUserSession,
            isAddingParticipants: true,
            shouldIncludeGuests: true,
            isFederationEnabled: false
        ))
        sut.filterConversation = conversation

        sut.updateSections(withSearchResult: searchResult)

        let remainingRemoteIdentifiers = Set(sut.appsSection.apps.map(\.remoteIdentifier))
        XCTAssertEqual(remainingRemoteIdentifiers.count, 2)
        XCTAssertFalse(remainingRemoteIdentifiers.contains(existingParticipantApp.remoteIdentifier))
        XCTAssertTrue(remainingRemoteIdentifiers.contains(knownCollaboratorAppUser.remoteIdentifier))
        XCTAssertTrue(remainingRemoteIdentifiers.contains(remoteOnlyAppSearchResult.remoteIdentifier))
    }

    func testThatSearchResultsViewControllerIsNotRetained() {
        autoreleasepool {
            // GIVEN
            let selfUser = MockUserType.createSelfUser(name: "Bobby McFerrin")
            let mockUserSession = UserSessionMock(mockUser: selfUser)
            var searchResultsViewController: SearchResultsViewController! = .init(
                userSelection: UserSelection(),
                userSession: mockUserSession,
                isAddingParticipants: false,
                shouldIncludeGuests: true,
                isFederationEnabled: false
            )
            sut = searchResultsViewController

            // WHEN
            searchResultsViewController.viewDidLoad()

            searchResultsViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }

    func testThatSelectionChangesDoNotReloadContacts() {
        let fixture = makeContactsSectionController()

        fixture.selection.add(fixture.user)
        fixture.selection.remove(fixture.user)
        fixture.selection.replace([fixture.user])

        XCTAssertEqual(fixture.collectionView.reloadDataCallCount, 0)
    }

    private func makeContactsSectionController() -> (
        sectionController: ContactsSectionController,
        selection: UserSelection,
        collectionView: ReloadTrackingCollectionView,
        user: UserType
    ) {
        let sectionController = ContactsSectionController()
        let selection = UserSelection()
        let collectionView = ReloadTrackingCollectionView()
        let user = MockUserType.createUser(name: "Alice")

        sectionController.selection = selection
        sectionController.allowsSelection = true
        sectionController.contacts = [user]
        sectionController.prepareForUse(in: collectionView)

        return (sectionController, selection, collectionView, user)
    }
}

private final class ReloadTrackingCollectionView: UICollectionView {

    private(set) var reloadDataCallCount = 0

    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reloadData() {
        reloadDataCallCount += 1
        super.reloadData()
    }
}
