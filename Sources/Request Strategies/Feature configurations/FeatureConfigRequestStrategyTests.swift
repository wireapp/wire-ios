//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import WireRequestStrategy

class FeatureConfigRequestStrategyTests: MessagingTestBase {

    var mockApplicationStatus: MockApplicationStatus!
    var sut: FeatureConfigRequestStrategy!
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        sut = FeatureConfigRequestStrategy(withManagedObjectContext: syncMOC,
                                           applicationStatus: mockApplicationStatus)
    }
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    private func setUpTeam(in context: NSManagedObjectContext) -> UUID {
        let team = self.createTeam(for: .selfUser(in: context))
        return team.remoteIdentifier!
    }
    
    // MARK: Single configuration

    func test_ItGeneratesARequest_ToFetchASingleConfig() {
        syncMOC.performGroupedAndWait { context -> Void in
            // Given
            guard let feature = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            feature.needsToBeUpdatedFromBackend = true

            // When
            self.boostrapChangeTrackers(with: feature)
            guard let request = self.sut.nextRequestIfAllowed() else { return XCTFail() }

            // Then
            XCTAssertEqual(request.path, "/feature-configs/appLock")
        }
    }

    func test_ItDoesNotGenerateARequest_ToFetchASingleConfig_WhenNotNeeded() {
        syncMOC.performGroupedAndWait { context -> Void in
            // Given
            let _ = self.setUpTeam(in: context)

            guard let feature = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            feature.needsToBeUpdatedFromBackend = false

            // When
            self.boostrapChangeTrackers(with: feature)
            let request = self.sut.nextRequestIfAllowed()

            // Then
            XCTAssertNil(request)
        }
    }

    func testThatItParsesAResponse() {
        var feature: Feature?
        syncMOC.performGroupedBlockAndWait {
            // given
            feature = Feature.fetch(name: .fileSharing, context: self.syncMOC)
            guard let feature = feature else { return XCTFail() }
            feature.needsToBeUpdatedFromBackend = true

            self.boostrapChangeTrackers(with: feature)
            guard let request = self.sut.nextRequestIfAllowed() else { return XCTFail() }
            XCTAssertNotNil(request)

            // when
            let payload = [
                "status": "disabled"
            ]

            let response = ZMTransportResponse(payload: payload as NSDictionary as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil)
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(feature!.status, .disabled)
        }
    }

    // MARK: - All configurations

    func test_ItGeneratesARequest_ToFetchAllConfigs() {
        syncMOC.performGroupedAndWait { context -> Void in
            // Given
            let teamId = self.setUpTeam(in: context)

            // When
            Feature.triggerBackendRefreshForAllConfigs()
            guard let request = self.sut.nextRequestIfAllowed() else { return XCTFail() }

            // Then
            XCTAssertEqual(request.path, "/teams/\(teamId.transportString())/features")
        }
    }

    func test_ItDoesNotGenerateARequest_ToFetchAllConfigs_WithoutATeam() {
        syncMOC.performGroupedAndWait { context -> Void in
            // Given
            XCTAssertNil(ZMUser.selfUser(in: context).team)

            // When
            Feature.triggerBackendRefreshForAllConfigs()
            let request = self.sut.nextRequestIfAllowed()

            // Then
            XCTAssertNil(request)
        }
    }

}

// MARK: - Processing events

extension FeatureConfigRequestStrategyTests {

    func testThatItUpdatesApplockFeature_FromUpdateEvent() {
        syncMOC.performGroupedAndWait { moc in
            // given
            FeatureService(context: moc).storeFileSharing(.init())
            let dict: NSDictionary = [
                "status": "disabled",
                "config": [
                    "enforceAppLock": false,
                    "inactivityTimeoutSecs": 50
                  ]
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "appLock"
            ]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // when
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait { moc in
            let existingFeature = Feature.fetch(name: .appLock, context: moc)
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature?.status, .disabled)
            let config = try? JSONDecoder().decode(Feature.AppLock.Config.self, from: (existingFeature?.config)!)
            XCTAssertEqual(config?.inactivityTimeoutSecs, 50)
            XCTAssertEqual(config?.enforceAppLock, false)
        }
    }

    func testThatItUpdatesFileSharingFeature_FromUpdateEvent() {
        syncMOC.performGroupedAndWait { moc in
            // given
            FeatureService(context: moc).storeFileSharing(.init())
            let dict: NSDictionary = [
                "status": "disabled"
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "fileSharing"
            ]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // when
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait { moc in
            let existingFeature = Feature.fetch(name: .fileSharing, context: moc)
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature?.status, .disabled)
        }
    }

    func testThatItUpdatesConferenceCallingFeature_FromUpdateEvent() {
        syncMOC.performGroupedAndWait { moc in
            // given
            FeatureService(context: moc).storeConferenceCalling(.init())
            let dict: NSDictionary = [
                "status": "enabled"
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "conferenceCalling"
            ]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // when
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait { moc in
            let existingFeature = Feature.fetch(name: .conferenceCalling, context: moc)
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature?.status, .enabled)
        }
    }

}

// MARK: - Helpers

private extension FeatureConfigRequestStrategyTests {

    @discardableResult
    func createTeam(for user: ZMUser) -> Team {
        let context = user.managedObjectContext!

        let team = Team.insertNewObject(in: context)
        team.name = "Wire Amazing Team"
        team.remoteIdentifier = .create()

        let membership = Member.insertNewObject(in: context)
        membership.team = team
        membership.user = user

        return team
    }

    private func createFeature(_ name: Feature.Name, in context: NSManagedObjectContext) -> Feature {
        let feature = Feature.insertNewObject(in: context)
        feature.name = name
        feature.status = .enabled
        feature.config = nil
        return feature
    }

    func boostrapChangeTrackers(with objects: ZMManagedObject...) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange(Set(objects))
        }

    }

}
