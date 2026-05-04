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
import XCTest

@testable import WireDataModel

final class PBMessageValidationTests: XCTestCase {
    // MARK: Generic Message

    func testThatItCreatesGenericMessageWithValidFields() {
        let text = Text.with {
            $0.content = "Hello hello hello"
        }

        let message = GenericMessage.with {
            text.setContent(on: &$0)
            $0.messageID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
        }

        XCTAssertTrue(message.validateFields())
    }

    func testThatItDoesNotCreateGenericMessageWithInvalidFields() {
        let text = Text.with {
            $0.content = "Hello hello hello"
        }

        let message = GenericMessage.with {
            text.setContent(on: &$0)
            $0.messageID = "nonce"
        }

        XCTAssertFalse(message.validateFields())
    }

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {
        let lastRead = LastRead.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.lastReadTimestamp = 25_000
        }

        XCTAssertTrue(GenericMessage(content: lastRead).validateFields())
    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {
        let lastRead = LastRead.with {
            $0.conversationID = "null"
            $0.lastReadTimestamp = 25_000
        }

        XCTAssertFalse(GenericMessage(content: lastRead).validateFields())
    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {
        let cleared = Cleared.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.clearedTimestamp = 25_000
        }

        XCTAssertTrue(GenericMessage(content: cleared).validateFields())
    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {
        let cleared = Cleared.with {
            $0.conversationID = "wirewire"
            $0.clearedTimestamp = 25_000
        }

        XCTAssertFalse(GenericMessage(content: cleared).validateFields())
    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {
        let messageHide = MessageHide.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertTrue(GenericMessage(content: messageHide).validateFields())
    }

    func testThatItDoesNotCreateHideWithInvalidFields() {
        var invalidMessageHide: MessageHide

        invalidMessageHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertFalse(GenericMessage(content: invalidMessageHide).validateFields())

        invalidMessageHide = MessageHide.with {
            $0.conversationID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.messageID = ""
        }

        XCTAssertFalse(GenericMessage(content: invalidMessageHide).validateFields())

        invalidMessageHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = ""
        }

        XCTAssertFalse(GenericMessage(content: invalidMessageHide).validateFields())
    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {
        let messageDelete = MessageDelete.with {
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertTrue(GenericMessage(content: messageDelete).validateFields())
    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {
        let messageDelete = MessageDelete.with {
            $0.messageID = "invalid"
        }

        XCTAssertFalse(GenericMessage(content: messageDelete).validateFields())
    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let messageEdit = MessageEdit.with {
            $0.text = Text.with { $0.content = "Hello" }
            $0.replacingMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertTrue(GenericMessage(content: messageEdit).validateFields())
    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {
        let messageEdit = MessageEdit.with {
            $0.text = Text.with { $0.content = "Hello" }
            $0.replacingMessageID = "N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!"
        }

        XCTAssertFalse(GenericMessage(content: messageEdit).validateFields())
    }

    // MARK: Confirmation

    func testThatItCreatesConfirmationWithValidFields() {
        let confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }

        XCTAssertTrue(GenericMessage(content: confirmation).validateFields())
    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {
        var confirmation: Confirmation

        confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "invalid"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }

        XCTAssertFalse(GenericMessage(content: confirmation).validateFields())

        confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229", "invalid"]
        }

        XCTAssertFalse(GenericMessage(content: confirmation).validateFields())
    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {
        let reaction = GenericMessageProtocol.Reaction.with {
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.emoji = "🤩"
        }

        XCTAssertTrue(GenericMessage(content: reaction).validateFields())
    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {
        let reaction = GenericMessageProtocol.Reaction.with {
            $0.messageID = "Not-A-UUID"
            $0.emoji = "🤩"
        }

        XCTAssertFalse(GenericMessage(content: reaction).validateFields())
    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {
        let userId = Proteus_UserId.with { $0.uuid = NSUUID().data() }

        XCTAssertNotNil(userId.validatingFields())
    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {
        let userId = Proteus_UserId.with { $0.uuid = Data() }

        XCTAssertNil(userId.validatingFields())
    }

    // MARK: Assets

    func testThatItCreatesMessageWithValidAsset() {
        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNotNil(genericMessage(
            assetId: "asset-id",
            assetToken: "token=",
            assetDomain: "domain",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(
            assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNotNil(genericMessage(
            assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==",
            assetDomain: "wire.com",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(
            assetId: "C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "",
            assetDomain: "",
            preview: true
        ))
        XCTAssertNotNil(genericMessage(
            assetId: "c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "",
            assetDomain: "",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "", preview: false))
    }

    func testThatItDoesNotCreateMessageWithInvalidAsset() {
        // Invalid asset ID
        XCTAssertNil(genericMessage(assetId: "asset:id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset/id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset.id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset@id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset[id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset`id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset{id", assetToken: "token", assetDomain: "domain", preview: true))

        // Invalid asset token
        XCTAssertNil(genericMessage(
            assetId: "asset-id",
            assetToken: "5@shay_a3wAY4%$@#$@%)!@-pOe==",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "asset-id",
            assetToken: "aV0TGxF3ugpawm3wAYPmew===",
            assetDomain: "wire.com",
            preview: false
        ))
        XCTAssertNil(genericMessage(
            assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew=Hello",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==Hello",
            assetDomain: "wire.com",
            preview: false
        ))

        // Both
        XCTAssertNil(genericMessage(
            assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "token?name=foo",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "token?name=foo",
            assetDomain: "wire.com",
            preview: false
        ))
    }

    // MARK: - Utilities

    private func genericMessage(
        assetId: String,
        assetToken: String?,
        assetDomain: String?,
        preview: Bool
    ) -> GenericMessage? {
        var assetPreview: GenericMessageProtocol.Asset.Preview!

        if preview {
            let metadata = GenericMessageProtocol.Asset.ImageMetaData.with {
                $0.width = 1000
                $0.height = 1000
                $0.tag = "tag"
            }

            assetPreview = GenericMessageProtocol.Asset.Preview.with {
                $0.size = 1000
                $0.mimeType = "image/png"
                $0.remote = assetRemoteData(id: assetId, token: assetToken!, domain: assetDomain!)
                $0.image = metadata
            }
        }

        let asset = GenericMessageProtocol.Asset.with {
            if preview {
                $0.preview = assetPreview
            }
            $0.uploaded = assetRemoteData(id: assetId, token: assetToken!, domain: assetDomain!)
        }

        let message = GenericMessage(content: asset)
        if !message.validateFields() {
            return nil
        }
        return message
    }

    private func assetRemoteData(id: String, token: String, domain: String) -> GenericMessageProtocol.Asset.RemoteData {
        GenericMessageProtocol.Asset.RemoteData.with {
            $0.assetID = id
            $0.assetToken = token
            $0.assetDomain = domain
            $0.otrKey = Data("pFHd6iVTvOVP2wFAd2yVlA==".utf8)
            $0.sha256 = Data("8fab1b98a5b5ac2b07f0f77c739980bd4c895db23a09a3bed9ecec584d3ed3e0".utf8)
            $0.encryption = .aesCbc
        }
    }

}

final class ModelValidationTests: XCTestCase {

    // MARK: Generic Message

    func testThatItCreatesGenericMessageWithValidFields() {

        let text = Text(content: "Hello hello hello")
        var genericMessage = GenericMessage(content: text)
        genericMessage.messageID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
        let isValid = genericMessage.validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateGenericMessageWithInvalidFields() {

        let text = Text(content: "Hieeee!")
        var genericMessage = GenericMessage(content: text)
        genericMessage.messageID = "nonce"
        let isValid = genericMessage.validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {

        guard let uuid = UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F") else {
            XCTFail("There's no uuid")
            return
        }
        let conversationID = QualifiedID(uuid: uuid, domain: "")
        let lastRead = LastRead(conversationID: conversationID, lastReadTimestamp: Date(timeIntervalSince1970: 25_000))
        let isValid = GenericMessage(content: lastRead).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {

        let lastRead = LastRead.with {
            $0.lastReadTimestamp = 25_000
        }
        let isValid = GenericMessage(content: lastRead).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {

        let cleared = Cleared(
            timestamp: Date(timeIntervalSince1970: 25_000),
            conversationID: UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")!
        )
        let isValid = GenericMessage(content: cleared).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {

        let cleared = Cleared.with {
            $0.clearedTimestamp = 25_000
            $0.conversationID = "wirewire"
        }
        let isValid = GenericMessage(content: cleared).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {

        let messageHide = MessageHide(
            conversationId: UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")!,
            messageId: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!
        )
        let isValid = GenericMessage(content: messageHide).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateHideWithInvalidFields() {

        let invalidConversation = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }
        var isValid = GenericMessage(content: invalidConversation).validateFields()
        XCTAssertFalse(isValid)

        let invalidMessage = MessageHide.with {
            $0.conversationID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.messageID = ""
        }
        isValid = GenericMessage(content: invalidMessage).validateFields()
        XCTAssertFalse(isValid)

        let invalidHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = ""
        }
        isValid = GenericMessage(content: invalidHide).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {

        let delete = MessageDelete(messageId: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!)
        let isValid = GenericMessage(content: delete).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {

        let delete = MessageDelete.with {
            $0.messageID = "invalid"
        }
        let isValid = GenericMessage(content: delete).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let text = Text(content: "Hello")
        let messageEdit = MessageEdit(
            replacingMessageID: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!,
            text: text
        )
        let isValid = GenericMessage(content: messageEdit).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {

        let text = Text(content: "Hello")
        let messageEdit = MessageEdit.with {
            $0.replacingMessageID = "N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!"
            $0.text = text
        }
        let isValid = GenericMessage(content: messageEdit).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Message Confirmation

    func testThatItCreatesConfirmationWithValidFields() {

        let confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }
        let isValid = GenericMessage(content: confirmation).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {

        let invalidFirstID = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "invalid"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }
        var isValid = GenericMessage(content: invalidFirstID).validateFields()
        XCTAssertFalse(isValid)

        let invalidArray = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229", "150"]
        }
        isValid = GenericMessage(content: invalidArray).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {

        let reaction = GenericMessageProtocol.Reaction.createReaction(
            emojis: ["🤩"],
            messageID: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!
        )
        let isValid = GenericMessage(content: reaction).validateFields()
        XCTAssertTrue(isValid)
    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {

        let reaction = GenericMessageProtocol.Reaction.with {
            $0.emoji = "🤩"
            $0.messageID = "Not-A-UUID"
        }
        let isValid = GenericMessage(content: reaction).validateFields()
        XCTAssertFalse(isValid)
    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {

        let userId = Proteus_UserId.with { $0.uuid = NSUUID().data() }

        XCTAssertNotNil(userId.validatingFields())
    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {

        let userId = Proteus_UserId.with { $0.uuid = Data() }

        XCTAssertNil(userId.validatingFields())
    }

    // MARK: - Assets

    func testThatItCreatesMessageWithValidAsset() {

        XCTAssertNotNil(genericMessage(
            assetId: "asset-id",
            assetToken: "token",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNotNil(genericMessage(
            assetId: "asset-id",
            assetToken: "token=",
            assetDomain: "wire.com",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(
            assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNotNil(genericMessage(
            assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==",
            assetDomain: "wire.com",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(
            assetId: "C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNotNil(genericMessage(
            assetId: "c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "",
            assetDomain: "wire.com",
            preview: false
        ))

        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "wire.com", preview: false))

    }

    func testThatItDoesNotCreateMessageWithInvalidAsset() {

        // Invalid asset ID
        XCTAssertNil(genericMessage(assetId: "asset:id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset/id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset.id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset@id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset[id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset`id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset{id", assetToken: "token", assetDomain: "wire.com", preview: true))

        // Invalid asset token
        XCTAssertNil(genericMessage(
            assetId: "asset-id",
            assetToken: "5@shay_a3wAY4%$@#$@%)!@-pOe==",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "asset-id",
            assetToken: "aV0TGxF3ugpawm3wAYPmew===",
            assetDomain: "wire.com",
            preview: false
        ))
        XCTAssertNil(genericMessage(
            assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew=Hello",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8",
            assetToken: "aV0TGxF3ugpawm3wAYPmew==Hello",
            assetDomain: "wire.com",
            preview: false
        ))

        // Both
        XCTAssertNil(genericMessage(
            assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "token?name=foo",
            assetDomain: "wire.com",
            preview: true
        ))
        XCTAssertNil(genericMessage(
            assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8",
            assetToken: "token?name=foo",
            assetDomain: "wire.com",
            preview: false
        ))

    }

    // MARK: - Utilities

    private func genericMessage(
        assetId: String,
        assetToken: String?,
        assetDomain: String?,
        preview: Bool
    ) -> GenericMessage? {

        var asset = GenericMessageProtocol.Asset()

        if preview {
            let imageMetaData = GenericMessageProtocol.Asset.ImageMetaData.with {
                $0.tag = "tag"
                $0.width = 1000
                $0.height = 1000
            }

            let remoteData = GenericMessageProtocol.Asset.RemoteData.with {
                $0.assetID = assetId
                $0.assetToken = assetToken ?? ""
            }
            let preview = GenericMessageProtocol.Asset.Preview(
                size: 1000,
                mimeType: "image/png",
                remoteData: remoteData,
                imageMetadata: imageMetaData
            )
            asset.preview = preview
        }

        asset.uploaded = GenericMessageProtocol.Asset.RemoteData.with {
            $0.assetID = assetId
            $0.assetToken = assetToken ?? ""
            $0.assetDomain = assetDomain ?? ""
        }

        let message = GenericMessage(content: asset)
        if !message.validateFields() {
            return nil
        }
        return message
    }
}
