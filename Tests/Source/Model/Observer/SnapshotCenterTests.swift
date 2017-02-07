//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import ZMCDataModel

class SnapshotCenterTests : BaseZMMessageTests {

    var sut: SnapshotCenter!
    
    override func setUp() {
        super.setUp()
        sut = SnapshotCenter(managedObjectContext: uiMOC)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItCreatesSnapshotsOfObjects(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        
        // when
        sut.willMergeChanges(changes: Set([conv.objectID]))
        
        // then
        XCTAssertNotNil(sut.snapshots[conv.objectID])
    }
    
    func testThatItSnapshotsNilValues(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        sut.willMergeChanges(changes: Set([conv.objectID]))
        
        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}
        
        // then
        let expectedAttributes : [String : NSObject?] = ["userDefinedName": nil,
                                                           "internalEstimatedUnreadCount": 0 as Optional<NSObject>,
                                                           "hasUnreadUnsentMessage": 0 as Optional<NSObject>,
                                                           "archivedChangedTimestamp": nil,
                                                           "isSelfAnActiveMember": 1 as Optional<NSObject>,
                                                           "callStateNeedsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                           "draftMessageText": nil,
                                                           "modifiedKeys": nil,
                                                           "securityLevel": 0 as Optional<NSObject>,
                                                           "isSilenced": 0 as Optional<NSObject>,
                                                           "lastServerTimeStamp": nil,
                                                           "messageDestructionTimeout": 0 as Optional<NSObject>,
                                                           "clearedTimeStamp": nil,
                                                           "needsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                           "lastUnreadKnockDate": nil,
                                                           "conversationType": 0 as Optional<NSObject>,
                                                           "internalIsArchived": 0 as Optional<NSObject>,
                                                           "lastModifiedDate": nil,
                                                           "silencedChangedTimestamp": nil,
                                                           "lastUnreadMissedCallDate": nil,
                                                           "voiceChannel": nil,
                                                           "remoteIdentifier_data": nil,
                                                           "lastReadServerTimeStamp": nil,
                                                           "normalizedUserDefinedName": nil,
                                                           "remoteIdentifier": nil]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "lastServerSyncedActiveParticipants": 0,
                                           "messages": 0,
                                           "otherActiveParticipants": 0,
                                           "callParticipants": 0]
        
        expectedAttributes.forEach{
            XCTAssertEqual(snapshot.attributes[$0] ?? nil, $1)
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
    }
    
    func testThatItSnapshotsSetValues(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        conv.conversationType = .group
        conv.userDefinedName = "foo"
        performPretendingUiMocIsSyncMoc {
            conv.lastModifiedDate = Date()
            conv.lastServerTimeStamp = Date()
            conv.lastUnreadKnockDate = Date()
            conv.lastUnreadMissedCallDate = Date()
        }
        conv.isSilenced = true
        conv.isSelfAnActiveMember = false
        conv.appendMessage(withText: "foo")
        conv.resetLocallyModifiedKeys(conv.keysThatHaveLocalModifications)
        sut.willMergeChanges(changes: Set([conv.objectID]))
        
        // when
        guard let snapshot = sut.snapshots[conv.objectID] else { return XCTFail("did not create snapshot")}
        
        // then
        let expectedAttributes : [String : NSObject?] = ["userDefinedName": conv.userDefinedName as Optional<NSObject>,
                                                         "internalEstimatedUnreadCount": 0 as Optional<NSObject>,
                                                         "hasUnreadUnsentMessage": 0 as Optional<NSObject>,
                                                         "archivedChangedTimestamp": nil,
                                                         "isSelfAnActiveMember": 0 as Optional<NSObject>,
                                                         "callStateNeedsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                         "draftMessageText": nil,
                                                         "modifiedKeys": nil,
                                                         "securityLevel": 0 as Optional<NSObject>,
                                                         "isSilenced": 1 as Optional<NSObject>,
                                                         "lastServerTimeStamp": conv.lastServerTimeStamp as Optional<NSObject>,
                                                         "messageDestructionTimeout": 0 as Optional<NSObject>,
                                                         "clearedTimeStamp": nil,
                                                         "needsToBeUpdatedFromBackend": 0 as Optional<NSObject>,
                                                         "lastUnreadKnockDate": conv.lastUnreadKnockDate as Optional<NSObject>,
                                                         "conversationType": conv.conversationType.rawValue as Optional<NSObject>,
                                                         "internalIsArchived": 0 as Optional<NSObject>,
                                                         "lastModifiedDate": conv.lastModifiedDate as Optional<NSObject>,
                                                         "silencedChangedTimestamp": conv.silencedChangedTimestamp as Optional<NSObject>,
                                                         "lastUnreadMissedCallDate": conv.lastUnreadMissedCallDate as Optional<NSObject>,
                                                         "voiceChannel": nil,
                                                         "remoteIdentifier_data": nil,
                                                         "lastReadServerTimeStamp": nil,
                                                         "normalizedUserDefinedName": conv.normalizedUserDefinedName as Optional<NSObject>,
                                                         "remoteIdentifier": nil]
        let expectedToManyRelationships = ["hiddenMessages": 0,
                                           "lastServerSyncedActiveParticipants": 0,
                                           "messages": 1,
                                           "otherActiveParticipants": 0,
                                           "callParticipants": 0]
        
        expectedAttributes.forEach{
            XCTAssertEqual((snapshot.attributes[$0] ?? nil), $1, "values for \($0) don't match")
        }
        XCTAssertEqual(snapshot.toManyRelationships, expectedToManyRelationships)
    
    }
    
    func testThatItRemovesTheSnapshotAfterAccessingIt(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        sut.willMergeChanges(changes: Set([conv.objectID]))
        
        // when
        XCTAssertNotNil(sut.snapshots[conv.objectID])
        _ = sut.extractChangedKeysFromSnapshot(for: conv)
        
        // then
        XCTAssertNil(sut.snapshots[conv.objectID])
    }
    
    func testThatReturnsChangedKeys() {
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        sut.willMergeChanges(changes: Set([conv.objectID]))
        
        // when
        conv.userDefinedName = "foo"
        let changedKeys = sut.extractChangedKeysFromSnapshot(for: conv)

        // then
        XCTAssertEqual(changedKeys.count, 2)
        XCTAssertEqual(changedKeys, Set(["normalizedUserDefinedName", "userDefinedName"]))
    }
}

