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

import Foundation
import GenericMessageProtocol

extension ZMImagePreprocessingTrackerTests {
    func testCompletionFromBeforeAQueuedEditDoesNotAdvanceTheNewPreview() throws {
        let message = linkPreviewMessage1!
        try message.setUnderlyingMessage(GenericMessage(content: Text(content: "old text"), nonce: message.nonce!))
        try message.enqueueInOutbox(operation: .initialMessage)
        message.linkPreviewState = .downloaded
        imagePreprocessingQueue.isSuspended = true
        defer { imagePreprocessingQueue.isSuspended = false }
        sut.addTrackedObjects([message])
        let completion = sut.preprocessingCompleteOperation(for: message)

        try message.setUnderlyingMessage(GenericMessage(content: Text(content: "new text"), nonce: message.nonce!))
        completion?.start()

        XCTAssertEqual(message.linkPreviewState, .downloaded)
        XCTAssertEqual(message.messageText, "new text")
    }

    @objc
    func setUpLinkPreviewMessage() {
        linkPreviewMessage1 = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: coreDataStack.viewContext)
        linkPreviewMessage2 = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: coreDataStack.viewContext)
        linkPreviewMessage3 = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: coreDataStack.viewContext)
        linkPreviewMessageExcludedByPredicate = ZMClientMessage(
            nonce: NSUUID.create(),
            managedObjectContext: coreDataStack.viewContext
        )
    }

    @objc
    func setupSut() {
        sut = ZMImagePreprocessingTracker(
            managedObjectContext: coreDataStack.viewContext,
            imageProcessingQueue: imagePreprocessingQueue,
            fetch: fetchPredicate,
            needsProcessingPredicate: needsProcessingPredicate,
            entityClass: ZMClientMessage.self,
            preprocessor: (preprocessor as! ZMAssetsPreprocessor)
        )
    }

    func testThatItReturnsTheCorrectFetchRequest() {
        // when
        let request = sut.fetchRequestForTrackedObjects()

        // then
        let expectedRequest = ZMClientMessage.sortedFetchRequest(with: fetchPredicate)
        XCTAssertEqual(request, expectedRequest)
    }

    @objc
    func assertHasOutstandingItems() {
        XCTAssertFalse(
            sut.hasOutstandingItems,
            "\(sut.imageOwnersThatNeedPreprocessing.description) / \(sut.imageOwnersBeingPreprocessed.description)"
        )

    }

    func testThatItHasNoOutstandingItems() {
        assertHasOutstandingItems()
    }
}
