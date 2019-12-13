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

@testable import WireDataModel


class DisplayNameGeneratorTests : ZMBaseManagedObjectTest {
    
    
    func testThatItReturnsFirstNameForUserWithDifferentFirstnames() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob A"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Henry B"
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        user3.name = "Arthur"
        let user4 = ZMUser.insertNewObject(in: uiMOC)
        user4.name = "Kevin ()"
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
        user1.name = "\u{00C5}ron Meister"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "A\u{030A}ron Hans"
        
        let name2b = "A\u{030A}rif Hans"
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron")
        XCTAssertEqual(generator.givenName(for: user2), "\u{00C5}ron")
        
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
        XCTAssertEqual(generator.givenName(for: user1), emptyString)
        XCTAssertEqual(generator.givenName(for: user2), emptyString)
        XCTAssertEqual(generator.givenName(for: user3), emptyString)
        
        // when
        user1.name = "\u{00C5}ron Meister"
        user2.name = "A\u{030A}ron Hans"
        user3.name = "A\u{030A}ron Müller"
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), "\u{00C5}ron")
        XCTAssertEqual(generator.givenName(for: user2), "\u{00C5}ron")
        XCTAssertEqual(generator.givenName(for: user3), "\u{00C5}ron")
    }
    
    func testThatItReturnsUpdatedFullNames()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Meister"
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // when
        user1.name = "Hans Master"

        // then
        XCTAssertEqual(generator.givenName(for: user1), "Hans")
    }
    

 
    func testThatItReturnsBothFullNamesWhenBothNamesAreEmptyAfterTrimming()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "******"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "******"
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)
        
        // then
        XCTAssertEqual(generator.givenName(for: user1), user1.name)
        XCTAssertEqual(generator.givenName(for: user2), user2.name)
    }
 
    func testThatItReturnsInitialsForUser()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        let user4 = ZMUser.insertNewObject(in: uiMOC)
        let user5 = ZMUser.insertNewObject(in: uiMOC)

        user1.name = "Rob A"
        user2.name = "Henry B"
        user3.name = "Arthur The Extreme Superman"
        user4.name = "Kevin ()"
        user5.name = "Echo"
        user5.serviceIdentifier = UUID.create().transportString()
        user5.providerIdentifier = UUID.create().transportString()
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC)

        // then
        XCTAssertEqual(generator.initials(for: user1), "RA")
        XCTAssertEqual(generator.initials(for: user2), "HB")
        XCTAssertEqual(generator.initials(for: user3), "AS")
        XCTAssertEqual(generator.initials(for: user4), "K")
        XCTAssertEqual(generator.initials(for: user5), "E")
        XCTAssert(user5.isServiceUser)
    }
    
    func testThatItFetchesAllUsersWhenNotFetchedYet()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob A"

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
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3]), role: nil)

        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = user2.displayName(in: conversation)
        let displayName3 = user3.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, user1.name)
        XCTAssertEqual(displayName2, user2.name)
        XCTAssertEqual(displayName3, "Mutti")
    }
    
    func testThatItRecalculatesTheDisplayNamesInAConversationBasisWhenANameBecomesAvailable() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        
        user1.name = "Karl Heinz"
        user2.name = ""
        user2.serviceIdentifier = UUID.create().transportString()
        user2.providerIdentifier = UUID.create().transportString()
        XCTAssert(user2.isServiceUser)
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        
        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = user2.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, "Karl")
        XCTAssertEqual(displayName2, "")
        
        // when
        user2.name = "Echo"
        let newDisplayName2 = user2.displayName(in: conversation)
        
        // then
        XCTAssertEqual(newDisplayName2, "Echo")
    }
    
    func testThatItCalculatesTheDisplayNamesOnConversationBasis_OneOnOne(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.connection?.to = user1
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)

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
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

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
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, selfUser]), role: nil)
        
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
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        
        // when
        let displayName1 = user1.displayName(in: conversation)
        let displayName2 = selfUser.displayName(in: conversation)
        
        // then
        XCTAssertEqual(displayName1, "Uschi")
        XCTAssertEqual(displayName2, "Uschi")
    }
    
    func testThatItUpdatesTheMapWhenAUsersNameChanges_UserWithSameName(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        
        XCTAssertEqual(user1.displayName(in: conversation), "Hans")
        XCTAssertEqual(user2.displayName(in: conversation), "Uschi")

        // when
        user1.name = "Uschi Schmidt"

        // then
        XCTAssertEqual(user1.displayName(in: conversation), "Uschi Schmidt")
        XCTAssertEqual(user2.displayName(in: conversation), "Uschi Meier")
    }
    
    func testThatItUpdatesTheMapWhenAUsersNameChanges(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.connection?.to = user1
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        
        XCTAssertEqual(user1.displayName(in: conversation), "Hans")
        
        // when
        user1.name = "Harald Schmidt"
        
        // then
        XCTAssertEqual(user1.displayName(in: conversation), "Harald")
    }

    func testThatItDoesNotCrashWhenTheConversationIsNil(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Schmidt"
        
        // then
        XCTAssertEqual(user1.displayName(in: nil), "Hans")
    }
    
    func testThatItDoesNotCrashWhenTheUserIsNotInTheConversationAndItsNameIsNil(){
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Uschi Meier"
        
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: user2, role: nil)
        
        // then
        performIgnoringZMLogError{
            XCTAssertEqual(user1.displayName(in: conversation), "")
        }
    }
    
    func testThatItGeneratesAMeaningfulConversationDisplayName() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Biff Tannen"
        
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Emmett Brown"
        user2.name = "Marty McFly"
        
        let groupConversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2])!
        groupConversation.userDefinedName = "Future Stuff"
       
        let groupConversationNoName = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2])!
        
        let oneOnOneConversation = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOneConversation.conversationType = .oneOnOne
        oneOnOneConversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        oneOnOneConversation.connection?.to = user1
        
        let connectionConversation = ZMConversation.insertNewObject(in: uiMOC)
        connectionConversation.conversationType = .connection
        connectionConversation.connection = ZMConnection.insertNewObject(in: uiMOC)
        connectionConversation.connection?.to = user2
        
        let selfConversation = ZMConversation.insertNewObject(in: uiMOC)
        selfConversation.conversationType = .self
        
        // then
        XCTAssertEqual(groupConversation.meaningfulDisplayName, "Future Stuff")
        XCTAssertEqual(groupConversationNoName.meaningfulDisplayName, "Emmett, Marty")
        XCTAssertEqual(oneOnOneConversation.meaningfulDisplayName, "Emmett Brown")
        XCTAssertEqual(connectionConversation.meaningfulDisplayName, "Marty McFly")
        XCTAssertEqual(selfConversation.meaningfulDisplayName, "Biff Tannen")
    }
    
    func testThatItReturnsNilIfNoMeaningfulConversationDisplayNameAvailable() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        
        let groupConversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2])!
        
        let oneOnOneConversation = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOneConversation.conversationType = .oneOnOne
        
        let connectionConversation = ZMConversation.insertNewObject(in: uiMOC)
        connectionConversation.conversationType = .connection
        
        let selfConversation = ZMConversation.insertNewObject(in: uiMOC)
        selfConversation.conversationType = .self
        
        let invalidConversation = ZMConversation.insertNewObject(in: uiMOC)
        invalidConversation.conversationType = .invalid
        
        // then
        XCTAssertNil(groupConversation.meaningfulDisplayName)
        XCTAssertNil(oneOnOneConversation.meaningfulDisplayName)
        XCTAssertNil(connectionConversation.meaningfulDisplayName)
        XCTAssertNil(selfConversation.meaningfulDisplayName)
        XCTAssertNil(invalidConversation.meaningfulDisplayName)
    }
}
