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
@testable import WireDataModel

final class FeatureTests: ZMBaseManagedObjectTest {

    var team: Team!
    
    override func setUp() {
        super.setUp()
        team = createTeam(in: uiMOC)
    }

    override func tearDown() {
        team = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testThatItCreatesFeature() {
        // when
        let feature = Feature.createOrUpdate(name: .appLock,
                                             status: .enabled,
                                             config: configData(enforced: false),
                                             team: team,
                                             context: uiMOC)
        
        // then
        let fetchedFeature = Feature.fetch(name: .appLock, context: uiMOC)
        XCTAssertEqual(feature, fetchedFeature)
        XCTAssertEqual(feature.team?.remoteIdentifier, team.remoteIdentifier!)
    }
    
    func testThatItUpdatesFeature() {
        // given
        let feature = Feature.insert(name: .appLock,
                                     status: .enabled,
                                     config: configData(enforced: false),
                                     team: team, 
                                     context: uiMOC)
        XCTAssertEqual(feature.status, .enabled)
        
        // when
        let _ = Feature.createOrUpdate(name: .appLock,
                                       status: .disabled,
                                       config: configData(enforced: false),
                                       team: team,
                                       context: uiMOC)
        
        // then
        XCTAssertEqual(feature.status, .disabled)
    }
    
    func testThatItFetchesFeature() {
        // given
        let _ = Feature.createOrUpdate(name: .appLock,
                                       status: .enabled,
                                       config: configData(enforced: false),
                                       team: team,
                                       context: uiMOC)
        
        
        // when
        let fetchedFeature = Feature.fetch(name: .appLock, context: uiMOC)
        
        // then
        XCTAssertNotNil(fetchedFeature)
    }
    
    func testThatItUpdatesNeedsToNotifyUserFlag_IfAppLockBecameForced() {
        // given
        let oldConfigData = configData(enforced: false)
        let decoder = JSONDecoder()
        let feature = Feature.insert(name: .appLock,
                                     status: .enabled,
                                     config: oldConfigData,
                                     team: team,
                                     context: uiMOC)

        let oldConfig = try? decoder.decode(Feature.AppLock.Config.self, from: oldConfigData)
        XCTAssertFalse(oldConfig!.enforceAppLock)
        
        XCTAssertFalse(feature.needsToNotifyUser)
        
        // when
        let newConfigData = configData(enforced: true)
        let _ = Feature.createOrUpdate(name: .appLock,
                                       status: .enabled,
                                       config: newConfigData,
                                       team: team,
                                       context: uiMOC)
        
        let newConfig = try? decoder.decode(Feature.AppLock.Config.self, from: newConfigData)
        XCTAssertTrue(newConfig!.enforceAppLock)
        
        let fetchedFeature = Feature.fetch(name: .appLock, context: uiMOC)
        
        // then
        XCTAssertTrue(fetchedFeature!.needsToNotifyUser)
    }
    
    func testThatItUpdatesNeedsToNotifyUserFlag_IfAppLockBecameNonForced() {
        // given
        let oldConfigData = configData(enforced: true)
        let decoder = JSONDecoder()
        let feature = Feature.insert(name: .appLock,
                                     status: .enabled,
                                     config: oldConfigData,
                                     team: team,
                                     context: uiMOC)

        let oldConfig = try? decoder.decode(Feature.AppLock.Config.self, from: oldConfigData)
        XCTAssertTrue(oldConfig!.enforceAppLock)
        
        XCTAssertFalse(feature.needsToNotifyUser)
        
        // when
        let newConfigData = configData(enforced: false)
        let _ = Feature.createOrUpdate(name: .appLock,
                                       status: .enabled,
                                       config: newConfigData,
                                       team: team,
                                       context: uiMOC)
        
        let newConfig = try? decoder.decode(Feature.AppLock.Config.self, from: newConfigData)
        XCTAssertFalse(newConfig!.enforceAppLock)
        
        let fetchedFeature = Feature.fetch(name: .appLock, context: uiMOC)
        
        // then
        XCTAssertTrue(fetchedFeature!.needsToNotifyUser)
    }
}

// MARK: - Helpers
extension FeatureTests {
    func configData(enforced: Bool) -> Data {
        return {
          let json = """
          {
            "enforceAppLock": \(enforced),
            "inactivityTimeoutSecs": 30
          }
          """

          return json.data(using: .utf8)!
        }()
    }
}
