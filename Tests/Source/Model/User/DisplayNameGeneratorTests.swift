//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@testable import ZMCDataModel


class DisplayNameGeneratorTests : ZMBaseManagedObjectTest {
    
    
    func testThatItReturnsFirstNameForUserWithDifferentFirstnames() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob A";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Henry B";
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        user3.name = "Arthur";
        let user4 = ZMUser.insertNewObject(in: uiMOC)
        user4.name = "Kevin ()";
        uiMOC.saveOrRollback()
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "Rob")
        XCTAssertEqual(generator.givenName(for: user2), "Henry")
        XCTAssertEqual(generator.givenName(for: user3), "Arthur")
        XCTAssertEqual(generator.givenName(for: user4), "Kevin")
    }
    
    func testThatItReturnsFirstNameForSameFirstnamesWithDifferentlyComposedCharacters()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "\u{00C5}ron Meister"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "A\u{030A}ron Hans"
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron")
        XCTAssertEqual(generator.givenName(for: user2), "\u{00C5}ron")
    }
    
    
    
    func testThatItReturnsUpdatedDisplayNamesWhenInitializedWithCopy()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "\u{00C5}ron Meister";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "A\u{030A}ron Hans";
        
        let name2b = "A\u{030A}rif Hans";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron");
        XCTAssertEqual(generator.givenName(for: user2), "\u{00C5}ron");
        
        // when
        user2.name = name2b
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron")
        XCTAssertEqual(generator.givenName(for: user2), "A\u{030A}rif".precomposedStringWithCanonicalMapping)
    }

 
    func testThatItReturnsUpdatedDisplayNamesWhenTheInitialMapWasEmpty()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        let emptyString = ""
        XCTAssertEqual(generator.givenName(for: user1), emptyString);
        XCTAssertEqual(generator.givenName(for: user2), emptyString);
        XCTAssertEqual(generator.givenName(for: user3), emptyString);
        
        // when
        user1.name = "\u{00C5}ron Meister";
        user2.name = "A\u{030A}ron Hans";
        user3.name = "A\u{030A}ron WhatTheFuck";
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron");
        XCTAssertEqual(generator.givenName(for: user2), "\u{00C5}ron");
        XCTAssertEqual(generator.givenName(for: user3), "\u{00C5}ron");
    }
    
    func testThatItReturnsUpdatedFullNames()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Meister";
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // when
        user1.name = "Hans Master"

        // then
        XCTAssertEqual(generator.givenName(for: user1), "Hans");
    }
    

 
    func testThatItReturnsBothFullNamesWhenBothNamesAreEmptyAfterTrimming()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "******";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "******";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), user1.name);
        XCTAssertEqual(generator.givenName(for: user2), user2.name);
    }
 
    func testThatItReturnsInitialsForUser()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        let user4 = ZMUser.insertNewObject(in: uiMOC)

        user1.name = "Rob A";
        user2.name = "Henry B";
        user3.name = "Arthur The Extreme Superman";
        user4.name = "Kevin ()";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)

        // then
        XCTAssertEqual(generator.initials(for: user1), "RA");
        XCTAssertEqual(generator.initials(for: user2), "HB");
        XCTAssertEqual(generator.initials(for: user3), "AS");
        XCTAssertEqual(generator.initials(for: user4), "K");
    }
    
    func testThatItFetchesAllUsersWhenNotFetchedYet()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob A";

        // when
        let givenName = user1.displayName
        
        // then
        XCTAssertNotNil(givenName)
        XCTAssertEqual(givenName, "Rob")
    }
    
}


// MARK: Conversation based names

extension DisplayNameGeneratorTests {
    
    func testThatItCalculatesTheDisplayNamesOnConversationBasis_Group(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        
        user1.name = "Hans Schmidt"
        user2.name = "Hans Meier"
        user3.name = "Mutti Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableOtherActiveParticipants.addObjects(from: [user1, user2, user3])

        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = user2.displayName(in: conversation)
        let displayName3 = user3.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, user1.name)
        XCTAssertEqual(displayName2, user2.name)
        XCTAssertEqual(displayName3, "Mutti")
    }
    
    func testThatItCalculatesTheDisplayNamesOnConversationBasis_OneOnOne(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.connection?.to = user1
        
        // when
        let displayName1 = user1.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, "Hans")
    }
    
    func testThatTheSelfUserHasGivenNameAsDisplayName(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.connection?.to = user1
        
        // when
        let displayName = selfUser.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName, "Uschi")
    }
    
    func testThatAUserWithTheSameNameAsTheSelfUserShowsFullName_Group(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Uschi Schmidt"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableOtherActiveParticipants.addObjects(from: [user1])
        
        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = selfUser.displayName(in: conversation)

        // then
        XCTAssertEqual(displayName1, "Uschi Schmidt")
        XCTAssertEqual(displayName2, "Uschi")
    }
    
    func testThatAUserWithTheSameNameAsTheSelfUserShowsFirstName_OneOnOne(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Uschi Schmidt"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.connection?.to = user1
        
        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = selfUser.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, "Uschi")
        XCTAssertEqual(displayName2, "Uschi")
    }

}
