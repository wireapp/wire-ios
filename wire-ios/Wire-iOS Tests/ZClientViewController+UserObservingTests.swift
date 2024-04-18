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

import WireCommonComponents
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import Wire

final class ZClientViewController_UserObservingTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var selfUser: ZMUser!
    private var isSelfUserE2EICertifiedUseCaseMock: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var userSessionMock: MockUserSession!
    private var imageTransformerMock: MockImageTransformer!
    private var sut: ZClientViewController!

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await CoreDataStackHelper().createStack()
        await coreDataStack.viewContext.perform { [self] in
            selfUser = ModelHelper().createSelfUser(in: coreDataStack.viewContext)
        }
    }

    override func setUp() {
        super.setUp()

        FontScheme.configure(with: .large)

        isSelfUserE2EICertifiedUseCaseMock = .init()
        isSelfUserE2EICertifiedUseCaseMock.invoke_MockValue = false

        userSessionMock = .init()
        userSessionMock.selfUser = selfUser
        userSessionMock.isSelfUserE2EICertifiedUseCase = isSelfUserE2EICertifiedUseCaseMock
        userSessionMock.addUserObserverFor_MockValue = NSObject()
        userSessionMock.conversationDirectory = coreDataStack.viewContext.conversationListDirectory()
        userSessionMock.conversationList_MockValue = coreDataStack.viewContext.conversationListDirectory().unarchivedConversations
        userSessionMock.enqueue_MockMethod = { _ in }
        userSessionMock.addConferenceCallingUnavailableObserver_MockMethod = { _ in }

        imageTransformerMock = .init()
        imageTransformerMock.adjustInputSaturationValueImage_MockMethod = { _, image in image }

        sut = .init(
            account: .mockAccount(imageData: mockImageData),
            userSession: userSessionMock,
            imageTransformer: imageTransformerMock
        )
    }

    override func tearDown() {
        sut = nil
        userSessionMock = nil
        isSelfUserE2EICertifiedUseCaseMock = nil
        selfUser = nil
        coreDataStack = nil
        imageTransformerMock = nil

        super.tearDown()
    }

    func testBackgroundViewControllerAccentColorIsChanged() {

        // Given
        sut.loadViewIfNeeded()

        // When
        let accentColor = ZMAccentColor.brightYellow
        selfUser.accentColorValue = accentColor
        let changeInfo = UserChangeInfo(object: selfUser)
        changeInfo.changedKeys = [#keyPath(ZMUser.accentColorValue)]
        sut.userDidChange(changeInfo)

        // Then
        XCTAssertEqual(sut.backgroundViewController.accentColor, .init(fromZMAccentColor: accentColor))
    }

    func testBackgroundViewControllerBackgroundImageChanged() throws {

        // Given
        sut.loadViewIfNeeded()

        // When
        let backgroundImage = try XCTUnwrap(image(inTestBundleNamed: "unsplash_burger.jpg"))
        let mockUser = MockUserType()
        mockUser.completeImageData = backgroundImage.pngData()
        let changeInfo = UserChangeInfo(object: mockUser)
        changeInfo.changedKeys = [#keyPath(UserType.completeImageData)]
        sut.userDidChange(changeInfo)

        // Then
        let predicate = NSPredicate { [sut] _, _ in
            sut?.backgroundViewController.backgroundImage != nil
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        wait(for: [expectation], timeout: 5)
    }
}
