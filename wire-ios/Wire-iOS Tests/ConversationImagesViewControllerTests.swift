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

extension SelfUser {

    // MARK: - Helper method

    /// setup self user as a team member if providing teamID with the name Tarja Turunen
    /// - Parameter teamID: when providing a team ID, self user is a team member
    static func setupMockSelfUser(inTeam teamID: UUID? = nil) {
        provider = SelfProvider(providedSelfUser: MockUserType.createSelfUser(name: "Tarja Turunen", inTeam: teamID))
    }
}

// MARK: - ConversationImagesViewControllerTests

final class ConversationImagesViewControllerTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationImagesViewController! = nil
    private var navigatorController: UINavigationController! = nil
    private var userSession: UserSessionMock!
    private var mockMainCoordinator: AnyMainCoordinator!

    override var needsCaches: Bool { true }

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        SelfUser.setupMockSelfUser()
        userSession = UserSessionMock()
        snapshotBackgroundColor = UIColor.white

        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let initialMessage = try! otherUserConversation.appendImage(from: image.imageData!)
        let imagesCategoryMatch = CategoryMatch(including: .image, excluding: .none)
        let collection = MockCollection(messages: [ imagesCategoryMatch: [initialMessage] ])
        let delegate = AssetCollectionMulticastDelegate()

        let assetWrapper = AssetCollectionWrapper(
            conversation: otherUserConversation,
            assetCollection: collection,
            assetCollectionDelegate: delegate,
            matchingCategories: [imagesCategoryMatch]
        )

        sut = ConversationImagesViewController(
            collection: assetWrapper,
            initialMessage: initialMessage,
            inverse: true,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol()
        )

        navigatorController = sut.wrapInNavigationController(navigationBarClass: UINavigationBar.self)

        snapshotHelper = .init()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForWrappedInNavigationController() {
        snapshotHelper.verify(matching: navigatorController.view)
    }

    func testThatItDisplaysCorrectToolbarForImage_Normal() {
        // GIVEN & WHEN
        sut.setBoundsSizeAsIPhone4_7Inch()

        // THEN
        snapshotHelper.verify(matching: navigatorController.view)
    }

    func testThatItDisplaysCorrectToolbarForImage_Ephemeral() {
        // GIVEN & WHEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)
        message.isEphemeral = true
        sut.currentMessage = message

        sut.setBoundsSizeAsIPhone4_7Inch()

        // Calls viewWillAppear
        sut.beginAppearanceTransition(true, animated: false)

        // THEN
        snapshotHelper.verify(matching: navigatorController.view)
    }

    // MARK: - Unit Tests

    // Update toolbar buttons for switching between ephemeral/normal messages

    func testThatToolBarIsUpdateAfterScollToAnEphemeralImage() {
        // GIVEN
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)
        message.isEphemeral = false
        sut.currentMessage = message

        // WHEN
        sut.viewDidLoad()

        // THEN
        XCTAssertEqual(
            sut.buttonsBar.buttons.map(\.accessibilityLabel),
            ["Sketch over picture", "Sketch emoji over picture", "Copy picture", "Save picture", "Reveal in conversation", "Delete picture"]
        )
        print(sut.buttonsBar.buttons.map { $0.accessibilityLabel })

        // WHEN
        message.isEphemeral = true
        sut.pageViewController(UIPageViewController(), didFinishAnimating: true, previousViewControllers: [], transitionCompleted: true)

        // THEN
        XCTAssertEqual(sut.buttonsBar.buttons.count, 1)
    }
}
