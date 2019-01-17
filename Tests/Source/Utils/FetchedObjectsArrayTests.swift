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

public class FetchedObjectsArrayTests: ZMBaseManagedObjectTest {
    func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }
    
    func testThatItFetchesInitialObjects() throws {
        // GIVEN
        // Existing messages
        let conversation = createConversation()
        
        (0...20).forEach { i in
            conversation.append(text: "\(i)")
        }
        
        // Fetch request
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        fetchRequest.fetchLimit = 10
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(ZMMessage.visibleInConversation), conversation)
        // WHEN
        let array = try FetchedObjectsArray<ZMMessage>(on: self.uiMOC, fetchRequest: fetchRequest)
        
        // THEN
        XCTAssertEqual(array.count, 10)
        XCTAssertNotNil(array[0].textMessageData)
        XCTAssertEqual(array[0].textMessageData!.messageText, "20")
    }
    
    func testThatItUpdatesAfterNewObjectInserted() throws {
        // GIVEN
        // Existing messages
        let conversation = createConversation()
        
        (0...10).forEach { i in
            conversation.append(text: "\(i)")
        }
        
        // Fetch request
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        fetchRequest.fetchLimit = 5
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(ZMMessage.visibleInConversation), conversation)
        // WHEN
        let array = try FetchedObjectsArray<ZMMessage>(on: self.uiMOC, fetchRequest: fetchRequest)
        
        // THEN
        XCTAssertEqual(array.count, 5)
        XCTAssertEqual(array[0].textMessageData!.messageText, "10")
        
        // and when
        
        (11...20).forEach { i in
            conversation.append(text: "\(i)")
        }
        try uiMOC.save()
        // THEN
        
        XCTAssertEqual(array.count, 15)
        XCTAssertEqual(array[0].textMessageData!.messageText, "20")
    }
    
    func testThatItUpdatesWhenObjectDeleted() throws {
        // GIVEN
        // Existing messages
        let conversation = createConversation()
        
        let messages: [NSManagedObject] = (0...10).map { i in
            return conversation.append(text: "\(i)") as! NSManagedObject
        }
        
        // Fetch request
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        fetchRequest.fetchLimit = 5
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(ZMMessage.visibleInConversation), conversation)
        // WHEN
        let array = try FetchedObjectsArray<ZMMessage>(on: self.uiMOC, fetchRequest: fetchRequest)
        
        // THEN
        XCTAssertEqual(array.count, 5)
        XCTAssertEqual(array[0].textMessageData!.messageText, "10")
        
        // and when
        
        messages.forEach(uiMOC.delete)
        try uiMOC.save()
        // THEN
        
        XCTAssertEqual(array.count, 0)
    }
}
