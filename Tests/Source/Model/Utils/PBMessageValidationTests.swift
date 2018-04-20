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

import Foundation
import XCTest
@testable import WireDataModel

class ModelValidationTests: XCTestCase {

    // MARK: Generic Message

    func testThatItCreatesGenericMessageWithValidFields() {

        let text = ZMText.builder()!
        text.setContent("Hello hello hello")

        let builder = ZMGenericMessage.builder()!
        builder.setText(text)
        builder.setMessageId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")

        let message = builder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateGenericMessageWithInvalidFields() {

        let text = ZMText.builder()!
        text.setContent("Hieeee!")

        let builder = ZMGenericMessage.builder()!
        builder.setText(text)
        builder.setMessageId("nonce")

        let message = builder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: Mention

    func testThatItCreatesMentionWithValidFields() {

        let builder = ZMMention.builder()!
        builder.setUserName("John Appleseed")
        builder.setUserId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")

        let mention = builder.buildAndValidate()
        XCTAssertNotNil(mention)

    }

    func testThatItDoesNotCreateMentionWithInvalidFields() {

        let builder = ZMMention.builder()!
        builder.setUserName("Jane Appleseed")
        builder.setUserId("user\u{0}")

        let mention = builder.buildAndValidate()
        XCTAssertNil(mention)

    }

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {

        let builder = ZMLastRead.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setLastReadTimestamp(25_000)

        let lastRead = builder.buildAndValidate()
        XCTAssertNotNil(lastRead)

    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {

        let builder = ZMLastRead.builder()!
        builder.setConversationId("null")
        builder.setLastReadTimestamp(25_000)

        let lastRead = builder.buildAndValidate()
        XCTAssertNil(lastRead)

    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {

        let builder = ZMCleared.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setClearedTimestamp(25_000)

        let cleared = builder.buildAndValidate()
        XCTAssertNotNil(cleared)

    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {

        let builder = ZMCleared.builder()!
        builder.setConversationId("wirewire")
        builder.setClearedTimestamp(25_000)

        let cleared = builder.buildAndValidate()
        XCTAssertNil(cleared)

    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {

        let builder = ZMMessageHide.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let hide = builder.buildAndValidate()
        XCTAssertNotNil(hide)

    }

    func testThatItDoesNotCreateHideWithInvalidFields() {

        let invalidConversationBuilder = ZMMessageHide.builder()!
        invalidConversationBuilder.setConversationId("")
        invalidConversationBuilder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let invalidConversationHide = invalidConversationBuilder.buildAndValidate()
        XCTAssertNil(invalidConversationHide)

        let invalidMessageBuilder = ZMMessageHide.builder()!
        invalidMessageBuilder.setConversationId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        invalidMessageBuilder.setMessageId("")

        let invalidMessageHide = invalidMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidMessageHide)

        let invalidHideBuilder = ZMMessageHide.builder()!
        invalidHideBuilder.setConversationId("")
        invalidHideBuilder.setMessageId("")

        let invalidHide = invalidHideBuilder.buildAndValidate()
        XCTAssertNil(invalidHide)

    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {

        let builder = ZMMessageDelete.builder()!
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let delete = builder.buildAndValidate()
        XCTAssertNotNil(delete)

    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {

        let builder = ZMMessageDelete.builder()!
        builder.setMessageId("invalid")

        let delete = builder.buildAndValidate()
        XCTAssertNil(delete)

    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let text = ZMText.builder()!
        text.setContent("Hello")

        let builder = ZMMessageEdit.builder()!
        builder.setText(text)
        builder.setReplacingMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let edit = builder.buildAndValidate()
        XCTAssertNotNil(edit)

    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {

        let text = ZMText.builder()!
        text.setContent("Hello")

        let builder = ZMMessageEdit.builder()!
        builder.setText(text)
        builder.setReplacingMessageId("N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!")

        let edit = builder.buildAndValidate()
        XCTAssertNil(edit)

    }

    // MARK: Message Confirmation

    func testThatItCreatesConfirmationWithValidFields() {

        let builder = ZMConfirmation.builder()!
        builder.setType(.DELIVERED)
        builder.setFirstMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        builder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229"])

        let confirmation = builder.buildAndValidate()
        XCTAssertNotNil(confirmation)

    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {

        let invalidFirstIDBuilder = ZMConfirmation.builder()!
        invalidFirstIDBuilder.setType(.DELIVERED)
        invalidFirstIDBuilder.setFirstMessageId("invalid")
        invalidFirstIDBuilder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229"])

        let invalidFirstID = invalidFirstIDBuilder.buildAndValidate()
        XCTAssertNil(invalidFirstID)

        let invalidArrayBuilder = ZMConfirmation.builder()!
        invalidArrayBuilder.setType(.DELIVERED)
        invalidArrayBuilder.setFirstMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        invalidArrayBuilder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229", 150])

        let invalidArray = invalidArrayBuilder.buildAndValidate()
        XCTAssertNil(invalidArray)

    }

    // MARK: Asset Remote Data

    func testThatItCreatesAssetWithValidFields() {

        let builder = ZMAssetRemoteData.builder()!
        builder.setAssetId("671F7546-C5CF-434D-95C7-32629780FC08")
        builder.setOtrKey(Data())
        builder.setSha256(Data())
        builder.setAssetToken("token")
        builder.setEncryption(ZMEncryptionAlgorithm.AESCBC)

        let asset = builder.buildAndValidate()
        XCTAssertNotNil(asset)

    }

    func testThatItDoesNotCreateAssetWithInvalidFields() {

        let builder = ZMAssetRemoteData.builder()!
        builder.setAssetId("nil")
        builder.setOtrKey(Data())
        builder.setSha256(Data())
        builder.setAssetToken("token")
        builder.setEncryption(ZMEncryptionAlgorithm.AESCBC)

        let asset = builder.buildAndValidate()
        XCTAssertNil(asset)

    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {

        let builder = ZMReaction.builder()!
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        builder.setEmoji("🤩")

        let reaction = builder.buildAndValidate()
        XCTAssertNotNil(reaction)

    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {

        let builder = ZMReaction.builder()!
        builder.setMessageId("Not-A-UUID")
        builder.setEmoji("🤩")

        let reaction = builder.buildAndValidate()
        XCTAssertNil(reaction)

    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {

        let builder = ZMUserId.builder()!
        builder.setUuid(NSUUID().data())

        let userID = builder.buildAndValidate()
        XCTAssertNotNil(userID)

    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {

        let tooSmallBuilder = ZMUserId.builder()!
        tooSmallBuilder.setUuid(Data())

        let tooSmall = tooSmallBuilder.buildAndValidate()
        XCTAssertNil(tooSmall)

    }

}
