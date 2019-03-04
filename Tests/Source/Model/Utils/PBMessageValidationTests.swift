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

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {

        let builder = ZMLastRead.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setLastReadTimestamp(25_000)

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setLastRead(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {

        let builder = ZMLastRead.builder()!
        builder.setConversationId("null")
        builder.setLastReadTimestamp(25_000)

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setLastRead(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {

        let builder = ZMCleared.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setClearedTimestamp(25_000)

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setCleared(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {

        let builder = ZMCleared.builder()!
        builder.setConversationId("wirewire")
        builder.setClearedTimestamp(25_000)

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setCleared(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {

        let builder = ZMMessageHide.builder()!
        builder.setConversationId("8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setHidden(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateHideWithInvalidFields() {

        let invalidConversationBuilder = ZMMessageHide.builder()!
        invalidConversationBuilder.setConversationId("")
        invalidConversationBuilder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let invalidConversationMessageBuilder = genericMessageBuilder()
        invalidConversationMessageBuilder.setHidden(invalidConversationBuilder.build())
        let invalidConversationHide = invalidConversationMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidConversationHide)

        let invalidMessageBuilder = ZMMessageHide.builder()!
        invalidMessageBuilder.setConversationId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        invalidMessageBuilder.setMessageId("")

        let invalidMessageMessageBuilder = genericMessageBuilder()
        invalidMessageMessageBuilder.setHidden(invalidMessageBuilder)
        let invalidMessageHide = invalidMessageMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidMessageHide)

        let invalidHideBuilder = ZMMessageHide.builder()!
        invalidHideBuilder.setConversationId("")
        invalidHideBuilder.setMessageId("")

        let invalidHideMessageBuilder = genericMessageBuilder()
        invalidHideMessageBuilder.setHidden(invalidHideBuilder)
        let invalidHide = invalidHideMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidHide)

    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {

        let builder = ZMMessageDelete.builder()!
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setDeleted(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {

        let builder = ZMMessageDelete.builder()!
        builder.setMessageId("invalid")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setDeleted(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let text = ZMText.builder()!
        text.setContent("Hello")

        let builder = ZMMessageEdit.builder()!
        builder.setText(text)
        builder.setReplacingMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setEdited(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {

        let text = ZMText.builder()!
        text.setContent("Hello")

        let builder = ZMMessageEdit.builder()!
        builder.setText(text)
        builder.setReplacingMessageId("N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setEdited(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: Message Confirmation

    func testThatItCreatesConfirmationWithValidFields() {

        let builder = ZMConfirmation.builder()!
        builder.setType(.DELIVERED)
        builder.setFirstMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        builder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229"])

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setConfirmation(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {

        let invalidFirstIDBuilder = ZMConfirmation.builder()!
        invalidFirstIDBuilder.setType(.DELIVERED)
        invalidFirstIDBuilder.setFirstMessageId("invalid")
        invalidFirstIDBuilder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229"])

        let invalidFirstIDMessageBuilder = genericMessageBuilder()
        invalidFirstIDMessageBuilder.setConfirmation(invalidFirstIDBuilder.build())
        let invalidFirstIDMessage = invalidFirstIDMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidFirstIDMessage)

        let invalidArrayBuilder = ZMConfirmation.builder()!
        invalidArrayBuilder.setType(.DELIVERED)
        invalidArrayBuilder.setFirstMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        invalidArrayBuilder.setMoreMessageIdsArray(["54A6E947-1321-42C6-BA99-F407FDF1A229", 150])

        let invalidArrayMessageBuilder = genericMessageBuilder()
        invalidArrayMessageBuilder.setConfirmation(invalidArrayBuilder.build())
        let invalidArrayMessage = invalidArrayMessageBuilder.buildAndValidate()
        XCTAssertNil(invalidArrayMessage)

    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {

        let builder = ZMReaction.builder()!
        builder.setMessageId("8B496992-E74D-41D2-A2C4-C92EEE777DCE")
        builder.setEmoji("🤩")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setReaction(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNotNil(message)

    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {

        let builder = ZMReaction.builder()!
        builder.setMessageId("Not-A-UUID")
        builder.setEmoji("🤩")

        let messageBuilder = genericMessageBuilder()
        messageBuilder.setReaction(builder.build())

        let message = messageBuilder.buildAndValidate()
        XCTAssertNil(message)

    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {

        let builder = ZMUserId.builder()!
        builder.setUuid(NSUUID().data())

        let userID = builder.build().validatingFields()
        XCTAssertNotNil(userID)

    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {

        let tooSmallBuilder = ZMUserId.builder()!
        tooSmallBuilder.setUuid(Data())

        let tooSmall = tooSmallBuilder.build().validatingFields()
        XCTAssertNil(tooSmall)

    }

    // MARK: - Assets

    func testThatItCreatesMessageWithValidAsset() {

        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token=", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", preview: false))

    }

    func testThatItDoesNotCreateMessageWithInvalidAsset() {

        // Invalid asset ID
        XCTAssertNil(genericMessage(assetId: "asset:id", assetToken: "token", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset/id", assetToken: "token", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset.id", assetToken: "token", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset@id", assetToken: "token", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset[id", assetToken: "token", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset`id", assetToken: "token", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset{id", assetToken: "token", preview: true))

        // Invalid asset token
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "5@shay_a3wAY4%$@#$@%)!@-pOe==", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "aV0TGxF3ugpawm3wAYPmew===", preview: false))
        XCTAssertNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew=Hello", preview: true))
        XCTAssertNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==Hello", preview: false))


        // Both
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", preview: true))
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", preview: false))


    }

    // MARK: - Utilities

    private func genericMessageBuilder() -> ZMGenericMessageBuilder {
        let builder = ZMGenericMessage.builder()!
        builder.setMessageId(UUID.create().uuidString)
        return builder
    }

    private func genericMessage(assetId: String, assetToken: String?, preview: Bool) -> ZMGenericMessage? {

        let builder = ZMAsset.builder()!

        if preview {

            let metaBuilder = ZMAssetImageMetaData.builder()!
            metaBuilder.setWidth(1000)
            metaBuilder.setHeight(1000)
            metaBuilder.setTag("tag")

            let preview = ZMAssetPreview.preview(withSize: 1000,
                                                 mimeType: "image/png",
                                                 remoteData: assetRemoteData(id: assetId, token: assetToken),
                                                 imageMetadata: metaBuilder.build())

            builder.setPreview(preview)

        }

        builder.setUploaded(assetRemoteData(id: assetId, token: assetToken))

        return ZMGenericMessage.message(content: builder.buildPartial()!).validatingFields()

    }

    private func assetRemoteData(id: String, token: String?) -> ZMAssetRemoteData {

        let dataBuilder = ZMAssetRemoteData.builder()!
        dataBuilder.setAssetId(id)
        dataBuilder.setAssetToken(token)
        dataBuilder.setOtrKey(Data("pFHd6iVTvOVP2wFAd2yVlA==".utf8))
        dataBuilder.setSha256(Data("8fab1b98a5b5ac2b07f0f77c739980bd4c895db23a09a3bed9ecec584d3ed3e0".utf8))
        dataBuilder.setEncryption(.AESCBC)

        return dataBuilder.build()

    }

}
