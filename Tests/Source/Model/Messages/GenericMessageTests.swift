//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireDataModel

class GenericMessageTests: XCTestCase {
    func testThatItChecksTheCommonMessageTypesAsKnownMessage() {
        let generators: [()->(GenericMessage)] = [
            { return GenericMessage(content: Text(content: "hello")) },
            { return GenericMessage(content: Knock()) },
            { return GenericMessage(content: LastRead(conversationID: UUID.create(), lastReadTimestamp: Date())) },
            { return GenericMessage(content: Cleared(timestamp: Date(), conversationID: UUID.create())) },
            {
                let sha256 = Data(base64Encoded: "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")!
                let otrKey = Data(base64Encoded: "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w=")!
                return GenericMessage(content: External(withOTRKey: otrKey, sha256: sha256))
            },
            { return GenericMessage(clientAction: .resetSession) },
            { return GenericMessage(content: Calling(content: "Calling")) },
            { return GenericMessage(content: WireProtos.Asset(imageSize: .zero, mimeType: "image/jpeg", size: 0)) },
            { return GenericMessage(content: MessageHide(conversationId: UUID.create(), messageId: UUID.create())) },
            { return GenericMessage(content: Location(latitude: 1, longitude: 2)) },
            { return GenericMessage(content: MessageDelete(messageId: UUID.create())) },
            { return GenericMessage(content: WireProtos.Reaction.createReaction(emoji: "test", messageID: UUID.create())) },
            { return GenericMessage(content: WireProtos.Availability(.away)) }
        ]
        
        generators.forEach { generator in
            let message = generator()
            XCTAssertTrue(message.knownMessage)
        }
    }
}
