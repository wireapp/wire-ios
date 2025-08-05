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

import Foundation
import GenericMessageProtocol
import XCTest

@testable import WireDataModel

class GenericMessageTests: XCTestCase {

    func testThatConsidersTextMessageTypeAsKnownMessage() {
        let textMessageType = GenericMessage(content: Text(content: "hello"))
        XCTAssertFalse(textMessageType.isContentUnknown)
    }

    func testThatItConsidersKnockMessageTypeAsKnownMessage() {
        let knockMessageType = GenericMessage(content: Knock())
        XCTAssertFalse(knockMessageType.isContentUnknown)
    }

    func testThatItConsidersLastReadMessageTypeAsKnownMessage() {
        let conversationID = QualifiedID(uuid: UUID.create(), domain: "")
        let lastReadMessageType = GenericMessage(content: LastRead(
            conversationID: conversationID,
            lastReadTimestamp: Date()
        ))
        XCTAssertFalse(lastReadMessageType.isContentUnknown)
    }

    func testThatItConsidersClearedMessageTypeAsKnownMessage() {
        let clearedMessageType = GenericMessage(content: Cleared(timestamp: Date(), conversationID: UUID.create()))
        XCTAssertFalse(clearedMessageType.isContentUnknown)
    }

    func testThatItConsidersExternalMessageTypeAsKnownMessage() {
        let sha256 = Data(base64Encoded: "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")!
        let otrKey = Data(base64Encoded: "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w=")!
        let externalMessageType = GenericMessage(content: External(withOTRKey: otrKey, sha256: sha256))

        XCTAssertFalse(externalMessageType.isContentUnknown)
    }

    func testThatItConsidersResetSessionMessageTypeAsKnownMessage() {
        let resetSessionMessageType = GenericMessage(clientAction: .resetSession)
        XCTAssertFalse(resetSessionMessageType.isContentUnknown)
    }

    func testThatItConsidersCallingMessageTypeAsKnownMessage() {
        let callingMessageType = GenericMessage(content: Calling(content: "Calling", conversationId: .random()))
        XCTAssertFalse(callingMessageType.isContentUnknown)
    }

    func testThatItConsidersAssetMessageTypeAsKnownMessage() {
        let assetMessageType = GenericMessage(content: GenericMessageProtocol.Asset(
            imageSize: .zero,
            mimeType: "image/jpeg",
            size: 0
        ))
        XCTAssertFalse(assetMessageType.isContentUnknown)
    }

    func testThatItConsidersHidingMessageTypeAsKnownMessage() {
        let hideMessageType = GenericMessage(content: MessageHide(
            conversationId: UUID.create(),
            messageId: UUID.create()
        ))
        XCTAssertFalse(hideMessageType.isContentUnknown)
    }

    func testThatItConsidersLocationMessageTypeAsKnownMessage() {
        let locationMessageType = GenericMessage(content: Location(latitude: 1, longitude: 2))
        XCTAssertFalse(locationMessageType.isContentUnknown)
    }

    func testThatItConsidersDeletionMessageTypeAsKnownMessage() {
        let deletionMessageType = GenericMessage(content: MessageDelete(messageId: UUID.create()))
        XCTAssertFalse(deletionMessageType.isContentUnknown)
    }

    func testThatItConsidersCreatingReactionMessageTypeAsKnownMessage() {
        let creatingReactionMessageType = GenericMessage(content: GenericMessageProtocol.Reaction.createReaction(
            emojis: ["❤️"],
            messageID: UUID.create()
        ))
        XCTAssertFalse(creatingReactionMessageType.isContentUnknown)
    }

    func testThatItConsidersAvailabilityMessageTypeAsKnownMessage() {
        let awayAvailabilityMessageType = GenericMessage(content: GenericMessageProtocol.Availability(.away))
        XCTAssertFalse(awayAvailabilityMessageType.isContentUnknown)
    }
}
