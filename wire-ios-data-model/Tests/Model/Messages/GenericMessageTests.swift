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

final class GenericMessageTests: XCTestCase {

    func testThatConsidersTextMessageTypeAsKnownMessage() {
        let textMessageType = GenericMessage(content: Text(content: "hello"))
        XCTAssertNotNil(textMessageType.content)
    }

    func testThatItConsidersKnockMessageTypeAsKnownMessage() {
        let knockMessageType = GenericMessage(content: Knock())
        XCTAssertNotNil(knockMessageType.content)
    }

    func testThatItConsidersLastReadMessageTypeAsKnownMessage() {
        let conversationID = QualifiedID(uuid: UUID.create(), domain: "")
        let lastReadMessageType = GenericMessage(content: LastRead(
            conversationID: conversationID,
            lastReadTimestamp: Date()
        ))
        XCTAssertNotNil(lastReadMessageType.content)
    }

    func testThatItConsidersClearedMessageTypeAsKnownMessage() {
        let clearedMessageType = GenericMessage(content: Cleared(timestamp: Date(), conversationID: UUID.create()))
        XCTAssertNotNil(clearedMessageType.content)
    }

    func testThatItConsidersExternalMessageTypeAsKnownMessage() {
        let sha256 = Data(base64Encoded: "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")!
        let otrKey = Data(base64Encoded: "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w=")!
        let externalMessageType = GenericMessage(content: External(withOTRKey: otrKey, sha256: sha256))

        XCTAssertNotNil(externalMessageType.content)
    }

    func testThatItConsidersResetSessionMessageTypeAsKnownMessage() {
        let resetSessionMessageType = GenericMessage(clientAction: .resetSession)
        XCTAssertNotNil(resetSessionMessageType.content)
    }

    func testThatItConsidersCallingMessageTypeAsKnownMessage() {
        let callingMessageType = GenericMessage(content: Calling(content: "Calling", conversationId: .random()))
        XCTAssertNotNil(callingMessageType.content)
    }

    func testThatItConsidersAssetMessageTypeAsKnownMessage() {
        let assetMessageType = GenericMessage(content: GenericMessageProtocol.Asset(
            name: "picture.jpg",
            mimeType: "image/jpeg",
            imageSize: .zero,
            size: 0
        ))
        XCTAssertNotNil(assetMessageType.content)
    }

    func testThatItConsidersHidingMessageTypeAsKnownMessage() {
        let hideMessageType = GenericMessage(content: MessageHide(
            conversationId: UUID.create(),
            messageId: UUID.create()
        ))
        XCTAssertNotNil(hideMessageType.content)
    }

    func testThatItConsidersLocationMessageTypeAsKnownMessage() {
        let locationMessageType = GenericMessage(content: Location(latitude: 1, longitude: 2))
        XCTAssertNotNil(locationMessageType.content)
    }

    func testThatItConsidersDeletionMessageTypeAsKnownMessage() {
        let deletionMessageType = GenericMessage(content: MessageDelete(messageId: UUID.create()))
        XCTAssertNotNil(deletionMessageType.content)
    }

    func testThatItConsidersCreatingReactionMessageTypeAsKnownMessage() {
        let creatingReactionMessageType = GenericMessage(content: GenericMessageProtocol.Reaction.createReaction(
            emojis: ["❤️"],
            messageID: UUID.create()
        ))
        XCTAssertNotNil(creatingReactionMessageType.content)
    }

    func testThatItConsidersAvailabilityMessageTypeAsKnownMessage() {
        let awayAvailabilityMessageType = GenericMessage(content: GenericMessageProtocol.Availability(.away))
        XCTAssertNotNil(awayAvailabilityMessageType.content)
    }
}
