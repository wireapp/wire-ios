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
import XCTest
@testable import WireDataModel

final class CoreDataMessagingMigrationVersionTests: XCTestCase {

    func testCurrentVersionIsPartOfEnum() throws {
        let currentModelVersion = CoreDataStack.messagingModel.version
        let migrationVersion = CoreDataMessagingMigrationVersion.allCases.first { version in
            version.dataModelVersion == currentModelVersion
        }
        XCTAssertNotNil(
            migrationVersion,
            "if you added a new model, you MUST add the case in the enum. and update the nextVersion method"
        )
    }

    func testMigrationFrom144To145PreservesMeetingAndDefaultsInvitedEmails() throws {
        let helper = DatabaseMigrationHelper()
        let sourceModel = try helper.createObjectModel(version: "2.144.0")
        let destinationModel = try helper.createObjectModel(version: "2.145.0")
        let mapping = try NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
        let storeDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: storeDirectory) }
        let meetingID = UUID()

        try helper.migrateStore(
            sourceVersion: "2.144.0",
            destinationVersion: "2.145.0",
            mappingModel: mapping,
            storeDirectory: storeDirectory,
            preMigrationAction: { context in
                try context.performAndWait {
                    let entity = try XCTUnwrap(NSEntityDescription.entity(forEntityName: "Meeting", in: context))
                    let meeting = NSManagedObject(entity: entity, insertInto: context)
                    meeting.setValue(meetingID, forKey: "remoteIdentifier")
                    meeting.setValue("Existing meeting", forKey: "title")
                    try context.save()
                }
            },
            postMigrationAction: { context in
                try context.performAndWait {
                    let meetings = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Meeting"))
                    XCTAssertEqual(meetings.count, 1)
                    let meeting = try XCTUnwrap(meetings.first)
                    XCTAssertEqual(meeting.value(forKey: "remoteIdentifier") as? UUID, meetingID)
                    XCTAssertEqual(meeting.value(forKey: "title") as? String, "Existing meeting")
                    XCTAssertNil(meeting.value(forKey: "invitedEmails"))
                }
            }
        )
    }
}
