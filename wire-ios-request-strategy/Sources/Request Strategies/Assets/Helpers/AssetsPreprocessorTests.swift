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

import XCTest
@testable import WireRequestStrategy

class AssetsPreprocessorTests: MessagingTestBase {

    var sut: AssetsPreprocessor!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()

        sut = AssetsPreprocessor(managedObjectContext: uiMOC)
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
    }

    override func tearDown() {
        sut = nil
        conversation = nil

        super.tearDown()
    }

    func testTearDownPreventsNewOutboxProcessingAndIgnoresLateDownsampleResults() throws {
        let message = try XCTUnwrap(conversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()), nonce: UUID()
        ) as? ZMAssetClientMessage)
        try message.enqueueInOutbox(operation: .initialMessage)
        try uiMOC.save()
        let original = uiMOC.zm_fileAssetCache.originalImageData(for: message)
        let content = message.underlyingMessage
        let asset = try XCTUnwrap(message.assets.first)

        sut.tearDown()
        sut.objectsDidChange([message])
        sut.completedDownsampleOperation(
            LateAssetDownsampleOperation(), imageOwner: AssetImageOwnerAdapter(asset: asset)
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertFalse(asset.hasEncrypted)
        XCTAssertEqual(message.underlyingMessage, content)
        XCTAssertEqual(uiMOC.zm_fileAssetCache.originalImageData(for: message), original)
        XCTAssertEqual(message.outboxState, .queued)
        XCTAssertFalse(message.hasChanges)
    }

    func testReleasingPreprocessorWhileImagesAreQueuedBalancesContextGroups() throws {
        let message = try XCTUnwrap(conversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()), nonce: UUID()
        ) as? ZMAssetClientMessage)
        try message.enqueueInOutbox(operation: .initialMessage)
        try uiMOC.save()
        let queue = sut.imageProcessingQueue
        // Keep completion operations alive beyond the preprocessor so the regression exercises
        // group cleanup after deallocation, rather than an ordinary teardown with finished work.
        queue.isSuspended = true
        defer { queue.isSuspended = false }
        sut.objectsDidChange([message])
        weak var releasedPreprocessor = sut

        sut.tearDown()
        sut = nil
        XCTAssertNil(releasedPreprocessor)
        queue.isSuspended = false

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 2))
        XCTAssertFalse(message.assets.contains(where: \.hasEncrypted))
        XCTAssertEqual(message.outboxState, .queued)
    }

    func testThatItPreprocessAssetMessage() {
        // given
        let message = try! conversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()),
            nonce: UUID()
        ) as! ZMAssetClientMessage
        let asset = message.assets.first!
        let messageSet: Set<NSManagedObject> = [message]

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(asset.hasEncrypted)
        XCTAssertFalse(asset.hasPreprocessed)
    }

    func testThatItPreprocessAssetMessageWithMultipleAssets() {
        // given
        let message = try! conversation.appendFile(with: ZMVideoMetadata(
            fileURL: fileURL(forResource: "video", extension: "mp4"),
            thumbnail: verySmallJPEGData()
        )) as! ZMAssetClientMessage
        let messageSet: Set<NSManagedObject> = [message]
        let assets = message.assets
        XCTAssertEqual(assets.count, 2)

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        for asset in assets {
            XCTAssertTrue(asset.hasEncrypted)

            if asset.needsPreprocessing {
                XCTAssertFalse(asset.hasPreprocessed)
            }
        }
    }

    func testThatItMarksTheTransferStateAsModifiedAfterItsDoneProcessing() {
        // given
        let message = try! conversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()),
            nonce: UUID()
        ) as! ZMAssetClientMessage
        let messageSet: Set<NSManagedObject> = [message]

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(message.modifiedKeys!.contains(#keyPath(ZMAssetClientMessage.transferState)))
    }

}

private final class LateAssetDownsampleOperation: NSObject, ZMImageDownsampleOperationProtocol {
    var downsampleImageData: Data { Data([1, 2, 3]) }
    var format: ZMImageFormat { .medium }
    var properties: ZMIImageProperties {
        ZMIImageProperties(size: CGSize(width: 1, height: 1), length: 3, mimeType: "image/jpeg")
    }
}
