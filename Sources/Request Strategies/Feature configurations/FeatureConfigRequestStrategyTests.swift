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
            let teamId = self.setUpTeam(in: context)

            guard let feature = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            feature.needsToBeUpdatedFromBackend = true

            // When
            self.boostrapChangeTrackers(with: feature)
            guard let request = self.sut.nextRequestIfAllowed() else { return XCTFail() }

            // Then
            XCTAssertEqual(request.path, "/teams/\(teamId.transportString())/features/appLock")
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
    
    func test_ItDoesNotGenerateARequest_ToFetchASingleConfig_WithoutATeam() {
        syncMOC.performGroupedAndWait { context -> Void in
            // Given
            XCTAssertNil(ZMUser.selfUser(in: context).team)

            guard let feature = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            feature.needsToBeUpdatedFromBackend = true

            // When
            self.boostrapChangeTrackers(with: feature)
            let request = self.sut.nextRequestIfAllowed()

            // Then
            XCTAssertNil(request)
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
