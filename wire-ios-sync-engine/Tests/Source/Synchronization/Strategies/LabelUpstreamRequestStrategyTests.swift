//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import WireSyncEngine
import XCTest

class LabelUpstreamRequestStrategyTests: MessagingTest {

    var sut: LabelUpstreamRequestStrategy!
    var mockSyncStatus: MockSyncStatus!
    var mockSyncStateDelegate: MockSyncStateDelegate!
    var mockApplicationStatus: MockApplicationStatus!

    var conversation1: ZMConversation!
    var conversation2: ZMConversation!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = LabelUpstreamRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)

        syncMOC.performGroupedAndWait {
            self.conversation1 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation1.remoteIdentifier = UUID()

            self.conversation2 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation2.remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        sut = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil
        mockSyncStateDelegate = nil
        conversation1 = nil
        conversation2 = nil
        super.tearDown()
    }

    func testThatItGeneratesRequestForUpdatingLabels() throws {
        let conversation1Id = try XCTUnwrap(syncMOC.performAndWait { conversation1.remoteIdentifier })

        let labelUpdate = WireSyncEngine.LabelUpdate(id: Label.fetchFavoriteLabel(in: uiMOC).remoteIdentifier!, type: 1, name: nil, conversations: [conversation1Id])
        let expectedPayload = WireSyncEngine.LabelPayload(labels: [labelUpdate])

        syncMOC.performGroupedAndWait {
            // given
            let label = Label.fetchFavoriteLabel(in: self.syncMOC)
            label.conversations = Set([self.conversation1])
            label.modifiedKeys = Set(["conversations"])
            self.sut.objectsDidChange(Set([label]))

            // when
            guard let request = self.sut.nextRequestIfAllowed(for: .v0) else { return XCTFail() }

            // then
            let payload = try! JSONSerialization.data(withJSONObject: request.payload as Any, options: [])
            let decodedPayload = try! JSONDecoder().decode(WireSyncEngine.LabelPayload.self, from: payload)
            XCTAssertEqual(request.path, "/properties/labels")
            XCTAssertEqual(decodedPayload, expectedPayload)
        }
    }

    func testThatItDoesntUploadLabelsMarkedForDeletion() {
        let labelUpdate = WireSyncEngine.LabelUpdate(id: Label.fetchFavoriteLabel(in: uiMOC).remoteIdentifier!, type: 1, name: nil, conversations: [])
        let expectedPayload = WireSyncEngine.LabelPayload(labels: [labelUpdate])

        syncMOC.performGroupedAndWait {
            // given
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: self.syncMOC, created: &created)!
            label.conversations = Set([self.conversation1])
            label.markForDeletion()
            label.modifiedKeys = Set(["conversations", "markedForDeletion"])
            self.sut.objectsDidChange(Set([label]))

            // when
            guard let request = self.sut.nextRequestIfAllowed(for: .v0) else { return XCTFail() }

            // then
            let payload = try! JSONSerialization.data(withJSONObject: request.payload as Any, options: [])
            let decodedPayload = try! JSONDecoder().decode(WireSyncEngine.LabelPayload.self, from: payload)
            XCTAssertEqual(request.path, "/properties/labels")
            XCTAssertEqual(decodedPayload, expectedPayload)
        }
    }

    func testThatItUploadLabels_WhenModifyingConversations() {
        // given
        syncMOC.performGroupedAndWait {
            let label = Label.insertNewObject(in: self.syncMOC)
            label.modifiedKeys = Set(["conversations"])
            self.sut.objectsDidChange(Set([label]))
        }

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertNotNil(self.sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItUploadLabels_WhenModifyingName() {
        // given
        syncMOC.performGroupedAndWait {
            let label = Label.insertNewObject(in: self.syncMOC)
            label.modifiedKeys = Set(["name"])
            self.sut.objectsDidChange(Set([label]))
        }

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertNotNil(self.sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItUploadsLabels_WhenModifiedWhileUploadingLabels() {
        var label1: Label!
        var label2: Label!

        // given
        syncMOC.performGroupedAndWait {
            label1 = Label.insertNewObject(in: self.syncMOC)
            label2 = Label.insertNewObject(in: self.syncMOC)
            label1.modifiedKeys = Set(["name"])
            self.syncMOC.saveOrRollback()
            self.sut.objectsDidChange(Set([label1]))
        }

        // when
        syncMOC.performGroupedAndWait {
            guard let request = self.sut.nextRequestIfAllowed(for: .v0) else { return XCTFail() }
            label2.modifiedKeys = Set(["name"])
            self.syncMOC.saveOrRollback()
            self.sut.objectsDidChange(Set([label2]))
            request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertNotNil(self.sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItResetsLocallyModifiedKeys_AfterSuccessfullyUploadingLabels() {
        var label: Label!

        // given
        syncMOC.performGroupedAndWait {
            label = Label.insertNewObject(in: self.syncMOC)
            label.modifiedKeys = Set(["name"])
            self.sut.objectsDidChange(Set([label]))
        }

        // when
        syncMOC.performGroupedAndWait {
            guard let request = self.sut.nextRequestIfAllowed(for: .v0) else { return XCTFail() }
            request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertNil(label.modifiedKeys)
        }
    }

    func testThatItDeletesLabelMarkedForDeletion_AfterSuccessfullyUploadingLabels() {
        var label: Label!

        // given
        syncMOC.performGroupedAndWait {
            label = Label.insertNewObject(in: self.syncMOC)
            label.markForDeletion()
            label.modifiedKeys = Set(["markedForDeletion"])
            self.sut.objectsDidChange(Set([label]))
        }

        // when
        syncMOC.performGroupedAndWait {
            guard let request = self.sut.nextRequestIfAllowed(for: .v0) else { return XCTFail() }
            request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(label.isZombieObject)
        }
    }
}
