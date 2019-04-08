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

final class ClientMessageTests_Cleared: DatabaseBaseTest {
    
    
    func testThatItCreatesPayloadForZMClearedMessages() {
        let contextDirectory: ManagedObjectContextDirectory = self.createStorageStackAndWaitForCompletion()
        
        contextDirectory.syncContext.performGroupedBlockAndWait {
            let _ = self.createSelfUser(in: contextDirectory.syncContext)
            
            let syncSelfClient1 = self.createSelfClient(on: contextDirectory.syncContext)
            contextDirectory.syncContext.setPersistentStoreMetadata(syncSelfClient1.remoteIdentifier!, key: "PersistedClientId")
            
            let syncConversation = ZMConversation.insertGroupConversation(into: contextDirectory.syncContext, withParticipants: [])!
            syncConversation.remoteIdentifier = UUID.create()
            
            // given
            syncConversation.clearedTimeStamp = Date()
            syncConversation.remoteIdentifier = UUID()
            guard let message = ZMConversation.appendSelfConversation(withClearedOf: syncConversation) else { return XCTFail() }
            
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else { return XCTFail() }
            
            // then
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testThatLastClearedUpdatesInSelfConversationDontExpire() {
        let contextDirectory: ManagedObjectContextDirectory = self.createStorageStackAndWaitForCompletion()
        
        contextDirectory.syncContext.performGroupedBlockAndWait {
            let _ = self.createSelfUser(in: contextDirectory.syncContext)
            
            let syncSelfClient1 = self.createSelfClient(on: contextDirectory.syncContext)
            contextDirectory.syncContext.setPersistentStoreMetadata(syncSelfClient1.remoteIdentifier!, key: "PersistedClientId")
            
            // given
            let conversation = ZMConversation.insertNewObject(in: contextDirectory.syncContext)
            conversation.remoteIdentifier = UUID()
            conversation.clearedTimeStamp = Date()
            
            // when
            guard let message = ZMConversation.appendSelfConversation(withClearedOf: conversation) else {
                XCTFail()
                return
            }
            
            // then
            XCTAssertNil(message.expirationDate)
        }
    }
    
    func testThatClearingMessageHistoryDeletesAllMessages() {
        let contextDirectory: ManagedObjectContextDirectory = self.createStorageStackAndWaitForCompletion()
        
        contextDirectory.syncContext.performGroupedBlockAndWait {
            
            let _ = self.createSelfUser(in: contextDirectory.syncContext)
            
            let syncSelfClient1 = self.createSelfClient(on: contextDirectory.syncContext)
            contextDirectory.syncContext.setPersistentStoreMetadata(syncSelfClient1.remoteIdentifier!, key: "PersistedClientId")
            
            let syncConversation = ZMConversation.insertGroupConversation(into: contextDirectory.syncContext, withParticipants: [])!
            syncConversation.remoteIdentifier = UUID.create()
            
            let message1 = syncConversation.append(text: "B") as! ZMMessage
            message1.expire()
            
            syncConversation.append(text: "A")
            
            let message3 = syncConversation.append(text: "B") as! ZMMessage
            message3.expire()
    
            syncConversation.lastServerTimeStamp = message3.serverTimestamp
    
            // when
            syncConversation.clearedTimeStamp = syncConversation.lastServerTimeStamp
            contextDirectory.syncContext.processPendingChanges()
            // then
            for message in syncConversation.allMessages {
                XCTAssertTrue(message.isDeleted)
            }
        }
    }
}
