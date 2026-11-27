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

class MentionTests: ZMBaseManagedObjectTest {

    func testEveryoneMentionRoundTripsAndMentionsSelf() throws {
        let original = Mention(range: NSRange(location: 2, length: 4), isEveryone: true)
        let proto = try XCTUnwrap(original.convertToProtosMention())
        XCTAssertTrue(proto.everyone)
        XCTAssertTrue(proto.userID.isEmpty)
        XCTAssertNotNil(proto.validatingFields())
        let decoded = try XCTUnwrap(Mention(proto, context: uiMOC))
        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.isForSelf)
        XCTAssertTrue(Text.with { $0.mentions = [proto] }.isMentioningSelf(ZMUser.selfUser(in: uiMOC)))
    }

    func testEveryoneMentionRejectsInvalidRange() {
        let proto = GenericMessageProtocol.Mention.with {
            $0.everyone = true
            $0.start = -1
            $0.length = 4
        }
        XCTAssertNil(Mention(proto, context: uiMOC))
    }

    func testNewProtocolContentRemainsUnsupported() {
        let message = GenericMessage.with { $0.poll = Poll() }
        XCTAssertTrue(message.hasUnsupportedContent)
    }

    func createMention(
        start: Int = 0,
        length: Int = 1,
        userId: String = UUID().transportString(),
        domain: String? = nil
    ) -> GenericMessageProtocol.Mention {
        // Make user mentioned user exists
        if let remoteIdentifier = UUID(uuidString: userId) {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = remoteIdentifier
            user.domain = domain
        }

        return GenericMessageProtocol.Mention.with {
            $0.start = Int32(start)
            $0.length = Int32(length)
            $0.userID = userId

            if let domain {
                $0.qualifiedUserID = GenericMessageProtocol.QualifiedUserId.with {
                    $0.id = userId
                    $0.domain = domain
                }
            }
        }
    }

    func testConstructionOfValidMention_WhenTheUserIsNotFederated() {
        // given
        let buffer = createMention()

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNotNil(mention)
    }

    func testConstructionOfValidMention_WhenTheUserIsFederated() {
        // given
        let buffer = createMention(domain: UUID().uuidString)

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNotNil(mention)
    }

    func testConstructionOfInvalidMentionRangeCase1() {
        // given
        let buffer = createMention(start: 5, length: 0)

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNil(mention)
    }

    func testConstructionOfInvalidMentionRangeCase2() {
        // given
        let buffer = createMention(start: 1, length: 0)

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNil(mention)
    }

    func testConstructionOfInvalidMentionRangeCase3() {
        // given
        let buffer = createMention(start: -1, length: 1)

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNil(mention)
    }

    func testConstructionOfInvalidMentionRangeCase4() {
        // given
        let buffer = createMention(start: 1, length: -1)

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNil(mention)
    }

    func testConstructionOfInvalidMentionUserId() {
        // given
        let buffer = createMention(userId: "not-a-valid-uuid")

        // when
        let mention = Mention(buffer, context: uiMOC)

        // then
        XCTAssertNil(mention)
    }

}
