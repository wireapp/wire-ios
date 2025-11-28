//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireFoundation
import XCTest

@testable import Wire

final class ConversationCollapsedMessageCellSnapshotTests: ConversationMessageSnapshotTestCase {

    var message: MockMessage!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.red)

        mockSelfUser = MockUserType.createDefaultSelfUser()
        message = MockMessageFactory.fileTransferMessage(sender: mockSelfUser)
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
    }

    override func tearDown() {
        message = nil
        mockSelfUser = nil
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }

    func testUploadedCell_fromThisDevice() {
        let messages: [String: MockMessage] = [
            "file": message,
            "audio": MockMessageFactory.audioMessage()!,
            "video": MockMessageFactory.videoMessage(),
            "image": MockMessageFactory.imageMessage(),
            "text": MockMessageFactory
                .textMessage(
                    withText:
                    """
                    Long long long Long long long Long long long Long long long Long long long Long long long\n
                    Long long long Long long long Long long long Long long long Long long long Long long long
                    Long long long Long long long Long long long Long long long Long long long Long long long
                    """
                )
        ]
        messages.forEach { verify(message: $0.value, named: $0.key) }
    }

    func testTextCollapsed() {
        let messages: [String: MockMessage] = [
            "singleLineText": MockMessageFactory.textMessage(withText: "Single Line text"),
            "twoLineText": MockMessageFactory.textMessage(withText: "First Line text\n Second line"),
            "threeLineText": MockMessageFactory.textMessage(
                withText: "Long long long Long long long Long long long Long long long Long long long Long long long"
            ),
            "moreThenThreeLineText": MockMessageFactory
                .textMessage(
                    withText:
                    """
                    Long long long Long long long Long long long Long long long Long long long Long long long\n
                    Long long long Long long long Long long long Long long long Long long long Long long long
                    Long long long Long long long Long long long Long long long Long long long Long long long
                    """
                )
        ]
        messages.forEach { verify(message: $0.value, named: $0.key) }

    }

    func testUploadedCell_fromThisDevice_collapseOwnMessagesDisabled() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false

        verify(message: message)
    }

    func testUploadedCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testWithErrorMessage() {
        message = MockMessageFactory.fileTransferMessage(sender: mockSelfUser)

        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        message.deliveryState = .failedToSend
        message.expirationReason = .timeout

        verify(message: message)
    }

}
