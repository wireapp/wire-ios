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

@testable import WireDataModel

class ParticipantRoleTests: ZMBaseManagedObjectTest {
    
    var user: ZMUser!
    var conversation: ZMConversation!
    var role: Role!
    
    override func setUp() {
        super.setUp()
        self.user = ZMUser.insertNewObject(in: self.uiMOC)
        self.conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.role = Role.insertNewObject(in: self.uiMOC)
    }
    
    private func createParticipantRole() -> ParticipantRole {
        let pr = ParticipantRole.insertNewObject(in: self.uiMOC)
        pr.user = user
        pr.conversation = conversation
        pr.role = role
        return pr
    }
    
    func testMarkedForNoOperationToSync() {
        
        // GIVEN
        let participant = createParticipantRole()
        
        // WHEN
        participant.operationToSync = .none
        
        // THEN
        XCTAssertFalse(participant.markedForDeletion)
        XCTAssertFalse(participant.markedForInsertion)
    }
    
    func testMarkedForDeletion() {
        
        // GIVEN
        let participant = createParticipantRole()
        
        // WHEN
        participant.operationToSync = .delete
        
        // THEN
        XCTAssertTrue(participant.markedForDeletion)
        XCTAssertFalse(participant.markedForInsertion)
    }
    
    func testMarkedForInsertion() {
        
        // GIVEN
        let participant = createParticipantRole()
        
        // WHEN
        participant.operationToSync = .insert
        
        // THEN
        XCTAssertFalse(participant.markedForDeletion)
        XCTAssertTrue(participant.markedForInsertion)
    }
    
    func testThatItReturnsTrackedKeys() {
        // GIVEN
        let participant = createParticipantRole()
        
        // WHEN
        let trackedKeys = participant.keysTrackedForLocalModifications()
        
        // THEN
        XCTAssertEqual(trackedKeys, Set([
            #keyPath(ParticipantRole.operationToSync),
            #keyPath(ParticipantRole.role)
            ]))
    }
    
    func testThatItSyncClientsThatNeedsToBeInserted() {
        
        // GIVEN
        let participant1 = createParticipantRole()
        let participant2 = createParticipantRole()
        
        // WHEN
        participant1.operationToSync = .insert
        participant2.operationToSync = .none
        
        // THEN
        XCTAssertTrue(ParticipantRole.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: participant1))
        XCTAssertFalse(ParticipantRole.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: participant2))
    }
    
    func testThatItSyncClientsThatNeedsToBeUpdated() {
        
        // GIVEN
        let participant1 = createParticipantRole()
        let participant2 = createParticipantRole()
        self.uiMOC.saveOrRollback()
        
        // WHEN
        participant1.operationToSync = .delete
        participant2.operationToSync = .none
        
        // THEN
        XCTAssertTrue(ParticipantRole.predicateForObjectsThatNeedToBeUpdatedUpstream()!.evaluate(with: participant1))
        XCTAssertFalse(ParticipantRole.predicateForObjectsThatNeedToBeUpdatedUpstream()!.evaluate(with: participant2))
    }
    
}
