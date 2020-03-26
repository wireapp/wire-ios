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

class MentionTests: ZMBaseManagedObjectTest {
    
    func createMention(start: Int = 0, length: Int = 1, userId: String = UUID().transportString()) -> WireProtos.Mention {
        // Make user mentioned user exists
        if let remoteIdentifier = UUID(uuidString: userId) {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = remoteIdentifier
        }
        
        return WireProtos.Mention.with {
            $0.start = Int32(start)
            $0.length = Int32(length)
            $0.userID = userId
        }
    }
    
    func testConstructionOfValidMention() {
        // given
        let buffer = createMention()
        
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
