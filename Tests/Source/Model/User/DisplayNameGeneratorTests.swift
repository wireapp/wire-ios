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
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2, user3, user4]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), "Rob")
        XCTAssertEqual(generator.displayName(for: user2), "Henry")
        XCTAssertEqual(generator.displayName(for: user3), "Arthur")
        XCTAssertEqual(generator.displayName(for: user4), "Kevin")
    }
    
    
    func testThatItReturnsTheFullNameForUserWithSameFirstnamesDifferentLastnameFirstLetter()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob Arthur";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Rob Benjamin";
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        user3.name = "Rob (Christopher)";
        let user4 = ZMUser.insertNewObject(in: uiMOC)
        user4.name = "Rob Benjamin Henry";
        let user5 = ZMUser.insertNewObject(in: uiMOC)
        user5.name = "Rob Christopher Benjamin";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2, user3, user4, user5]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), user1.name);
        XCTAssertEqual(generator.displayName(for: user2), user2.name);
        XCTAssertEqual(generator.displayName(for: user3), user3.name);
        XCTAssertEqual(generator.displayName(for: user4), user4.name);
        XCTAssertEqual(generator.displayName(for: user5), user5.name);
    }
    
    
    func testThatItReturnsFullNameForUserWithSameFirstnamesAndSameLastnameFirstLetter()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Rob Arthur";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Rob Anthony";
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        user3.name = "Rob Benjamin";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2, user3]))
        
        // then
        
        XCTAssertEqual(generator.displayName(for: user1), user1.name);
        XCTAssertEqual(generator.displayName(for: user2), user2.name);
        XCTAssertEqual(generator.displayName(for: user3), user3.name);
    }
    
    func testThatItReturnsFullNameForUsersWithDifferentlyComposedSpecialCharacters()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Henry \u{00cb}lse"; // LATIN CAPITAL LETTER E WITH DIAERESIS
        
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "Henry E\u{0308}mil"; // LATIN CAPITAL LETTER E + COMBINING DIAERESIS
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), "Henry \u{00cb}lse");
        XCTAssertEqual(generator.displayName(for: user2), "Henry \u{00cb}mil");
    }
    
    
    func testThatItReturnsAbbreviatedNameForSameFirstnamesWithDifferentlyComposedCharacters()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "\u{00C5}ron Meister"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "A\u{030A}ron Hans"
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), user1.name)
        XCTAssertEqual(generator.displayName(for: user2), user2.name.precomposedStringWithCanonicalMapping)
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
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), user1.name);
        XCTAssertEqual(generator.displayName(for: user2), user2.name.precomposedStringWithCanonicalMapping);
        
        // when
        user2.name = name2b
        let (newGenerator, updated) = generator.createCopy(with: Set([user1, user2]))
        let expectedUpdatedSet = Set([user1.objectID, user2.objectID])
        
        // then
        XCTAssertEqual(newGenerator.displayName(for: user1), "\u{00C5}ron")
        XCTAssertEqual(newGenerator.displayName(for: user2), "A\u{030A}rif".precomposedStringWithCanonicalMapping)

        XCTAssertEqual(updated, expectedUpdatedSet);
    }

 
    func testThatItReturnsUpdatedDisplayNamesWhenInitializedWithCopyAddingOneName() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "\u{00C5}ron Meister";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "A\u{030A}ron Hans";
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        user3.name = "A\u{030A}ron Hans";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2]))

        // then
        XCTAssertEqual(generator.displayName(for: user1), user1.name);
        XCTAssertEqual(generator.displayName(for: user2), user2.name.precomposedStringWithCanonicalMapping)
        
        // when
        let (newGenerator, updated) = generator.createCopy(with: Set([user1, user2, user3]))
        
        // then
        XCTAssertEqual(newGenerator.displayName(for: user1), user1.name);
        XCTAssertEqual(newGenerator.displayName(for: user2), user2.name.precomposedStringWithCanonicalMapping);
        XCTAssertEqual(newGenerator.displayName(for: user3), user3.name.precomposedStringWithCanonicalMapping);
        
        XCTAssertEqual(updated, Set([user3.objectID]));
    }
 

 
    func testThatItReturnsUpdatedDisplayNamesWhenTheInitialMapWasEmpty()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        let allUsers = Set([user1, user2, user3])
        
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: allUsers)
        let emptyString = ""
        XCTAssertEqual(generator.displayName(for: user1), emptyString);
        XCTAssertEqual(generator.displayName(for: user2), emptyString);
        XCTAssertEqual(generator.displayName(for: user3), emptyString);
        
        // when
        user1.name = "\u{00C5}ron Meister";
        user2.name = "A\u{030A}ron Hans";
        user3.name = "A\u{030A}ron WhatTheFuck";
        let (newGenerator, updated) = generator.createCopy(with: allUsers)
        
        // then
        XCTAssertEqual(newGenerator.displayName(for: user1), user1.name.precomposedStringWithCanonicalMapping)
        XCTAssertEqual(newGenerator.displayName(for: user2), user2.name.precomposedStringWithCanonicalMapping)
        XCTAssertEqual(newGenerator.displayName(for: user3), user3.name.precomposedStringWithCanonicalMapping)
        
        XCTAssertEqual(updated, Set(allUsers.map{$0.objectID}));
    }
    

 
    func testThatItReturnsUpdatedFullNames()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "Hans Meister";
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1]))
        
        // when
        user1.name = "Hans Master"
        let (newGenerator, updated) = generator.createCopy(with: Set([user1]))

        // then
        XCTAssertEqual(newGenerator.displayName(for: user1), "Hans");
        XCTAssertEqual(updated, Set([user1.objectID]));
    }
    

 
    func testThatItReturnsBothFullNamesWhenBothNamesAreEmptyAfterTrimming()
    {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "******";
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "******";
        
        // when
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2]))
        
        // then
        XCTAssertEqual(generator.displayName(for: user1), user1.name);
        XCTAssertEqual(generator.displayName(for: user2), user2.name);
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
        let generator = DisplayNameGenerator(managedObjectContext: uiMOC, allUsers: Set([user1, user2, user3, user4]))

        // then
        XCTAssertEqual(generator.initials(for: user1), "RA");
        XCTAssertEqual(generator.initials(for: user2), "HB");
        XCTAssertEqual(generator.initials(for: user3), "AS");
        XCTAssertEqual(generator.initials(for: user4), "K");
    }
    
}
