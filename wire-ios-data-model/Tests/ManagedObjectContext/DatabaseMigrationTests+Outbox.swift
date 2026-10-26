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

import CoreData
import GenericMessageProtocol
import XCTest

@testable import WireDataModel

final class DatabaseMigrationTests_Outbox: XCTestCase {

    func testMigrationPreservesLegacyMessagesWithoutEnrollingThem() throws {
        try assertMigrationPreservesLegacyMessages(from: "2.144.0")
    }

    private func assertMigrationPreservesLegacyMessages(from version: String) throws {
        let helper = DatabaseMigrationHelper()
        let source = try helper.createObjectModel(version: version)
        let destination = try helper.createObjectModel(version: "2.145.0")
        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: destination)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let nonce = UUID()
        let content = try GenericMessage(content: Text(content: "preserve me"), nonce: nonce).serializedData()
        // Include unsent text/assets, delivered, expired and edited rows. None should become new
        // outbox work merely because migration adds the lifecycle fields.
        let entities = ["ClientMessage", "AssetClientMessage", "ClientMessage", "ClientMessage", "ClientMessage"]

        try helper.migrateStore(
            sourceVersion: version,
            destinationVersion: "2.145.0",
            mappingModel: mapping,
            storeDirectory: directory,
            preMigrationAction: { context in
                // Use the source model's raw entities: current subclasses reference fields that
                // deliberately do not exist in the pre-outbox schema.
                let conversation = NSManagedObject(
                    entity: try XCTUnwrap(context.persistentStoreCoordinator?.managedObjectModel
                        .entitiesByName["Conversation"]),
                    insertInto: context
                )
                for (index, entityName) in entities.enumerated() {
                    let message = NSManagedObject(
                        entity: try XCTUnwrap(context.persistentStoreCoordinator?.managedObjectModel
                            .entitiesByName[entityName]),
                        insertInto: context
                    )
                    message.setValue(Data(repeating: UInt8(index), count: 16), forKey: "nonce_data")
                    message.setValue(timestamp, forKey: "serverTimestamp")
                    message.setValue(timestamp, forKey: "expirationDate")
                    message.setValue(index == 2, forKey: "delivered")
                    message.setValue(index == 3, forKey: "isExpired")
                    let modifiedKey = entityName == "AssetClientMessage" ? "transferState" : "dataSet"
                    message.setValue(NSSet(array: [modifiedKey]), forKey: "modifiedKeys")
                    message.setValue(conversation, forKey: "visibleInConversation")
                    if index == 4 {
                        message.setValue(timestamp, forKey: "updatedTimestamp")
                    }
                    let data = NSManagedObject(
                        entity: try XCTUnwrap(context.persistentStoreCoordinator?.managedObjectModel
                            .entitiesByName["GenericMessageData"]),
                        insertInto: context
                    )
                    data.setValue(content, forKey: "data")
                    data.setValue(message, forKey: entityName == "AssetClientMessage" ? "asset" : "message")
                }
                try context.save()
            },
            postMigrationAction: { context in
                let messages = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Message"))
                XCTAssertEqual(messages.count, entities.count)
                for message in messages {
                    let nonceData = try XCTUnwrap(message.value(forKey: "nonce_data") as? Data)
                    let index = Int(try XCTUnwrap(nonceData.first))
                    XCTAssertEqual(message.entity.name, entities[index])
                    XCTAssertEqual(message.value(forKey: "delivered") as? Bool, index == 2)
                    XCTAssertEqual(message.value(forKey: "isExpired") as? Bool, index == 3)
                    XCTAssertEqual(message.value(forKey: "serverTimestamp") as? Date, timestamp)
                    XCTAssertEqual(message.value(forKey: "expirationDate") as? Date, timestamp)
                    let modifiedKey = entities[index] == "AssetClientMessage" ? "transferState" : "dataSet"
                    XCTAssertEqual(message.value(forKey: "modifiedKeys") as? NSSet, NSSet(array: [modifiedKey]))
                    XCTAssertNotNil(message.value(forKey: "visibleInConversation"))
                    if index == 4 {
                        XCTAssertEqual(message.value(forKey: "updatedTimestamp") as? Date, timestamp)
                    }
                    let data = try XCTUnwrap((message.value(forKey: "dataSet") as? NSOrderedSet)?.firstObject
                        as? NSManagedObject)
                    XCTAssertEqual(data.value(forKey: "data") as? Data, content)

                    XCTAssertEqual(message.value(forKey: "outboxStateRaw") as? Int16, 0)
                    XCTAssertEqual(message.value(forKey: "outboxOperationRaw") as? Int16, 0)
                    XCTAssertEqual(message.value(forKey: "outboxAttemptCount") as? Int32, 0)
                    for key in [
                        "outboxEnqueuedAt", "outboxAttemptIdentifier", "outboxPayload", "outboxNextAttemptAt",
                        "outboxSnapshot"
                    ] {
                        XCTAssertNil(message.value(forKey: key))
                    }
                }
            }
        )
    }
}
