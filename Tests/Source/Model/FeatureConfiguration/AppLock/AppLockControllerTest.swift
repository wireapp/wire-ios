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
import LocalAuthentication
@testable import WireDataModel

final class AppLockControllerTest: ZMBaseManagedObjectTest {
    
    let decoder = JSONDecoder()

    func testThatForcedAppLockDoesntAffectSettings() {
        
        //given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let config = AppLockController.Config(useBiometricsOrCustomPasscode: false,
                                              forceAppLock: true,
                                              timeOut: 900)
        let sut = AppLockController(config: config, selfUser: selfUser)
        XCTAssertTrue(sut.config.forceAppLock)
        
        //when
        XCTAssertTrue(sut.isActive)
        sut.isActive = false
        
        //then
        XCTAssertTrue(sut.isActive)
    }
    
    func testThatAppLockAffectsSettings() {

        //given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let config = AppLockController.Config(useBiometricsOrCustomPasscode: false,
                                              forceAppLock: false,
                                              timeOut: 10)
        let sut = AppLockController(config: config, selfUser: selfUser)
        XCTAssertFalse(sut.config.forceAppLock)
        sut.isActive = true

        //when
        XCTAssertTrue(sut.isActive)
        sut.isActive = false

        //then
        XCTAssertFalse(sut.isActive)
    }
    
    
    func testThatBiometricsChangedIsTrueIfDomainStatesDiffer() {
        //given
        UserDefaults.standard.set(Data(), forKey: "DomainStateKey")
        
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        
        //when/then
        XCTAssertTrue(BiometricsState.biometricsChanged(in: context))
    }
    
    func testThatBiometricsChangedIsFalseIfDomainStatesDontDiffer() {
        //given
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        UserDefaults.standard.set(context.evaluatedPolicyDomainState, forKey: "DomainStateKey")
        
        //when/then
        XCTAssertFalse(BiometricsState.biometricsChanged(in: context))
    }
    
    func testThatBiometricsStatePersistsState() {
        //given
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        _ = BiometricsState.biometricsChanged(in: context)
        
        //when
        BiometricsState.persist()
        
        //then
        XCTAssertEqual(context.evaluatedPolicyDomainState, UserDefaults.standard.object(forKey: "DomainStateKey") as? Data)
    }

    func testThatItHonorsTheTeamConfiguration_WhenSelfUserIsATeamUser() {
        
        //given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let configFromBundle = AppLockController.Config(useBiometricsOrCustomPasscode: false,
                                                        forceAppLock: false,
                                                        timeOut: 10)
        let sut = AppLockController(config: configFromBundle, selfUser: selfUser)
        XCTAssertFalse(sut.config.forceAppLock)
        XCTAssertTrue(sut.config.isAvailable)
        XCTAssertEqual(sut.config.appLockTimeout, 10)
        
        //when
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        
        let config = Feature.AppLock.Config.init(enforceAppLock: true, inactivityTimeoutSecs: 30)
        let configData = try? JSONEncoder().encode(config)
        _ = Feature.createOrUpdate(
            name: .appLock,
            status: .disabled,
            config: configData,
            team: team,
            context: uiMOC
        )
        
        //then
        XCTAssertTrue(sut.config.forceAppLock)
        XCTAssertFalse(sut.config.isAvailable)
        XCTAssertEqual(sut.config.appLockTimeout, 30)
    }
    
    func testThatItHonorsForcedAppLockFromTheBaseConfiguration() {
        
        //given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let configFromBundle = AppLockController.Config(useBiometricsOrCustomPasscode: false,
                                                        forceAppLock: true,
                                                        timeOut: 10)
        let sut = AppLockController(config: configFromBundle, selfUser: selfUser)
        XCTAssertTrue(sut.config.forceAppLock)
        
        //when
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        
        let config = Feature.AppLock.Config.init(enforceAppLock: false, inactivityTimeoutSecs: 30)
        let configData = try? JSONEncoder().encode(config)
        _ = Feature.createOrUpdate(
            name: .appLock,
            status: .disabled,
            config: configData,
            team: team,
            context: uiMOC
        )
        
        //then
        XCTAssertTrue(sut.config.forceAppLock)
    }
    
    func testThatItDoesNotHonorTheTeamConfiguration_WhenSelfUserIsNotATeamUser() {
        
        //given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let configFromBundle = AppLockController.Config(useBiometricsOrCustomPasscode: false,
                                                        forceAppLock: false,
                                                        timeOut: 10)
        let sut = AppLockController(config: configFromBundle, selfUser: selfUser)
        XCTAssertFalse(sut.config.forceAppLock)
        XCTAssertTrue(sut.config.isAvailable)
        XCTAssertEqual(sut.config.appLockTimeout, 10)
        
        //when
        let team = createTeam(in: uiMOC)
        XCTAssertNil(selfUser.team)
        
        let config = Feature.AppLock.Config.init(enforceAppLock: true, inactivityTimeoutSecs: 30)
        let configData = try? JSONEncoder().encode(config)
        _ = Feature.createOrUpdate(
            name: .appLock,
            status: .disabled,
            config: configData,
            team: team,
            context: uiMOC
        )
        
        //then
        XCTAssertFalse(sut.config.forceAppLock)
        XCTAssertTrue(sut.config.isAvailable)
        XCTAssertNotEqual(sut.config.appLockTimeout, 30)
    }
}

