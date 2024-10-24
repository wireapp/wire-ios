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

import WireDataModel
import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - CollectionsViewControllerTests

final class CollectionsViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    private var emptyCollection: AssetCollectionWrapper!
    private var imageMessage: ZMConversationMessage!
    private var videoMessage: ZMConversationMessage!
    private var audioMessage: ZMConversationMessage!
    private var fileMessage: ZMConversationMessage!
    private var linkMessage: ZMConversationMessage!

    private var expiredImageMessage: ZMConversationMessage!
    private var expiredVideoMessage: ZMConversationMessage!
    private var expiredAudioMessage: ZMConversationMessage!
    private var expiredFileMessage: ZMConversationMessage!
    private var expiredLinkMessage: ZMConversationMessage!

    private var deletedImageMessage: ZMConversationMessage!
    private var deletedVideoMessage: ZMConversationMessage!
    private var deletedAudioMessage: ZMConversationMessage!
    private var deletedFileMessage: ZMConversationMessage!
    private var deletedLinkMessage: ZMConversationMessage!

    private var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .blue
        snapshotHelper = .init()
        userSession = UserSessionMock()

        let conversation = MockGroupDetailsConversation()
        let assetCollection = MockCollection.empty
        let delegate = AssetCollectionMulticastDelegate()
        emptyCollection = AssetCollectionWrapper(
            conversation: conversation,
            assetCollection: assetCollection,
            assetCollectionDelegate: delegate,
            matchingCategories: []
        )

        imageMessage = MockMessageFactory.imageMessage()
        videoMessage = MockMessageFactory.videoMessage()
        audioMessage = MockMessageFactory.audioMessage()
        fileMessage = MockMessageFactory.fileTransferMessage()
        linkMessage = MockMessageFactory.linkMessage()

        expiredImageMessage = MockMessageFactory.expiredImageMessage()
        expiredVideoMessage = MockMessageFactory.expiredVideoMessage()
        expiredFileMessage = MockMessageFactory.expiredFileMessage()
        expiredLinkMessage = MockMessageFactory.expiredLinkMessage()
        expiredAudioMessage = MockMessageFactory.expiredAudioMessage()

        deletedImageMessage = MockMessageFactory.deletedImageMessage()
        deletedVideoMessage = MockMessageFactory.deletedVideoMessage()
        deletedFileMessage = MockMessageFactory.deletedFileMessage()
        deletedLinkMessage = MockMessageFactory.deletedLinkMessage()
        deletedAudioMessage = MockMessageFactory.deletedAudioMessage()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        emptyCollection = nil
        imageMessage = nil
        videoMessage = nil
        audioMessage = nil
        fileMessage = nil
        linkMessage = nil

        expiredImageMessage = nil
        expiredVideoMessage = nil
        expiredAudioMessage = nil
        expiredFileMessage = nil
        expiredLinkMessage = nil

        deletedImageMessage = nil
        deletedVideoMessage = nil
        deletedAudioMessage = nil
        deletedFileMessage = nil
        deletedLinkMessage = nil

        userSession = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatNoElementStateIsShownWhenCollectionIsEmpty() {
        let controller = CollectionsViewController(
            collection: emptyCollection,
            fetchingDone: true,
            userSession: userSession,
            mainCoordinator: .mock
        )
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testThatLoadingIsShownWhenFetching() {
        let controller = CollectionsViewController(
            collection: emptyCollection,
            fetchingDone: false,
            userSession: userSession,
            mainCoordinator: .mock
        )
        controller.view.layer.speed = 0 // Disable animations so that the spinner would always be in the same phase
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenNotFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenFull() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, fileMessage, fileMessage, fileMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenNotFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenFull() {
        let assetCollection = MockCollection(linkMessages: [linkMessage, linkMessage, linkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    // MARK: - Expiration

    func testImagesSectionWhenExpired() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [expiredImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, expiredVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, expiredFileMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testAudioSectionWhenExpired() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, expiredAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenExpired() {
        let assetCollection = MockCollection(linkMessages: [expiredLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    // MARK: - Expiration: Deletion

    func testImagesSectionWhenDeleted() {
        let assetCollection = MockCollection(messages: [
            MockCollection.onlyImagesCategory: [deletedImageMessage],
            MockCollection.onlyVideosCategory: [videoMessage, deletedVideoMessage]])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testFilesSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [fileMessage, deletedFileMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testAudioSectionWhenDeleted() {
        let assetCollection = MockCollection(fileMessages: [audioMessage, deletedAudioMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    func testLinksSectionWhenDeleted() {
        let assetCollection = MockCollection(linkMessages: [deletedLinkMessage, linkMessage])
        let controller = createController(showingCollection: assetCollection)
        snapshotHelper.verifyInAllIPhoneSizes(matching: controller)
    }

    // MARK: - Helper method

    private func createController(showingCollection assetCollection: MockCollection) -> CollectionsViewController {
        let conversation = MockGroupDetailsConversation()
        let delegate = AssetCollectionMulticastDelegate()
        let collection = AssetCollectionWrapper(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate, matchingCategories: [])

        let controller = CollectionsViewController(
            collection: collection,
            userSession: userSession,
            mainCoordinator: .mock
        )
        _ = controller.view
        delegate.assetCollectionDidFetch(collection: assetCollection, messages: assetCollection.messages, hasMore: false)
        delegate.assetCollectionDidFinishFetching(collection: assetCollection, result: .success)
        return controller
    }
}
