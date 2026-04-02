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

import WireDataModelSupport
import XCTest

@testable import WireDataModel

final class WireCellsMessageAttachmentDraftEntityTests: XCTestCase {

    private var coreDataStack: CoreDataStack!

    @MainActor
    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()
    }

    @MainActor
    override func tearDown() async throws {
        coreDataStack = nil

    }

    @MainActor
    func testWireCellsMessageAttachmentDraftEntity_canBeCreated() throws {
        // given
        let context = coreDataStack.viewContext

        let draft = WireCellsMessageAttachmentDraftEntity(context: context)
        draft.uuid = UUID()
        draft.versionID = "versionID"
        draft.mimeType = "mimeType"
        draft.fileName = "fileName"
        draft.fileSize = 100
        draft.dataPath = "dataPath"
        draft.nodePath = "nodePath"
        draft.uploadStatus = .failed
        draft.assetHeight = 200
        draft.assetWidth = 300
        draft.assetDuration = 400

        // when
        try context.save()

        // then
        let request = WireCellsMessageAttachmentDraftEntity.fetchRequest()
        let persisted = try context.fetch(request) as! [WireCellsMessageAttachmentDraftEntity]

        try XCTAssertCount(persisted, count: 1)
        XCTAssertEqual(persisted[0].uuid, draft.uuid)
        XCTAssertEqual(persisted[0].versionID, "versionID")
        XCTAssertEqual(persisted[0].mimeType, "mimeType")
        XCTAssertEqual(persisted[0].fileName, "fileName")
        XCTAssertEqual(persisted[0].fileSize, 100)
        XCTAssertEqual(persisted[0].dataPath, "dataPath")
        XCTAssertEqual(persisted[0].nodePath, "nodePath")
        XCTAssertEqual(persisted[0].uploadStatus, .failed)
        XCTAssertEqual(persisted[0].assetHeight, 200)
        XCTAssertEqual(persisted[0].assetWidth, 300)
        XCTAssertEqual(persisted[0].assetDuration, 400)
    }

}
