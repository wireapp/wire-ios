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
    var selfUser: ZMUser!
    var sut: AppLockController!
    
    override func setUp() {
        super.setUp()
        
        selfUser = ZMUser.selfUser(in: uiMOC)
        sut = createAppLockController()
    }
    
    override func tearDown() {
        selfUser = nil
        sut = nil
        
        super.tearDown()
    }

    func testThatForcedAppLockDoesntAffectSettings() {
        
        //given
        sut = createAppLockController(forceAppLock: true)
        XCTAssertTrue(sut.config.forceAppLock)
        
        //when
        XCTAssertTrue(sut.isActive)
        sut.isActive = false
        
        //then
        XCTAssertTrue(sut.isActive)
    }
    
    func testThatAppLockAffectsSettings() {

        //given
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
        XCTAssertTrue(sut.biometricsState.biometricsChanged(in: context))
        UserDefaults.standard.set(nil, forKey: "DomainStateKey")
    }
    
    func testThatBiometricsChangedIsFalseIfDomainStatesDontDiffer() {
        //given
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        UserDefaults.standard.set(context.evaluatedPolicyDomainState, forKey: "DomainStateKey")
        
        //when/then
        XCTAssertFalse(sut.biometricsState.biometricsChanged(in: context))
        UserDefaults.standard.set(nil, forKey: "DomainStateKey")
    }
    
    func testThatBiometricsStatePersistsState() {
        //given
        let evaluatedPolicyDomainStateData = "test".data(using: .utf8)
        UserDefaults.standard.set(evaluatedPolicyDomainStateData, forKey: "DomainStateKey")
        
        let context = LAContext()
        XCTAssertTrue(sut.biometricsState.biometricsChanged(in: context))
        
        //when
        sut.biometricsState.persistState()
        
        //then
        XCTAssertEqual(context.evaluatedPolicyDomainState, UserDefaults.standard.object(forKey: "DomainStateKey") as? Data)
        UserDefaults.standard.set(nil, forKey: "DomainStateKey")
    }

    func testThatItHonorsTheTeamConfiguration_WhenSelfUserIsATeamUser() {
        
        //given
        XCTAssertFalse(sut.config.forceAppLock)
        XCTAssertTrue(sut.config.isAvailable)
        XCTAssertEqual(sut.config.appLockTimeout, 900)
        
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
        sut = createAppLockController(forceAppLock: true)
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
        XCTAssertFalse(sut.config.forceAppLock)
        XCTAssertTrue(sut.config.isAvailable)
        XCTAssertEqual(sut.config.appLockTimeout, 900)
        
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

// MARK : Evaluate Authentication

extension AppLockControllerTest {
    
    func testEvaluateScenario() {
        assert(
            input: (scenario: .screenLock(requireBiometrics: true), canEvaluate: true,  biometricsChanged: true),
            output: .needCustomPasscode
        )

        assert(
            input: (scenario: .screenLock(requireBiometrics: true), canEvaluate: false,  biometricsChanged: true),
            output: .needCustomPasscode
        )
        
        assert(
            input: (scenario: .screenLock(requireBiometrics: true), canEvaluate: false,  biometricsChanged: false),
            output: .needCustomPasscode
        )

        assert(
            input: (scenario: .screenLock(requireBiometrics: false), canEvaluate: true,  biometricsChanged: false),
            output: .granted
        )
        
        performIgnoringZMLogError {
            self.assert(
                input: (scenario: .screenLock(requireBiometrics: false), canEvaluate: false,  biometricsChanged: false),
                output: .needCustomPasscode
            )
        }
        
        performIgnoringZMLogError {
            self.assert(
                input: (scenario: .databaseLock, canEvaluate: false,  biometricsChanged: false),
                output: .unavailable
            )
        }
        
    }
}

// MARK: - Helper

extension AppLockControllerTest {
    typealias Input = (scenario: AppLockController.AuthenticationScenario, canEvaluate: Bool, biometricsChanged: Bool)
    
    private func assert(input: Input, output: AppLockController.AuthenticationResult, file: StaticString = #file, line: UInt = #line) {
        
        let context = MockLAContext(canEvaluate: input.canEvaluate)
        sut.biometricsState = MockBiometricsState(didChange: input.biometricsChanged)
        
        sut.evaluateAuthentication(scenario: input.scenario,
                                   description: "evaluate authentication",
                                   context: context) { (result, context) in
            
            XCTAssertEqual(result, output, file: file, line: line)
        }
    }
    
    private func createAppLockController(useBiometricsOrCustomPasscode: Bool = false, forceAppLock: Bool = false, timeOut: UInt = 900) -> AppLockController {
        let config = AppLockController.Config(useBiometricsOrCustomPasscode: useBiometricsOrCustomPasscode,
                                              forceAppLock: forceAppLock,
                                              timeOut: timeOut)
        return AppLockController(config: config, selfUser: selfUser)
    }
}

// MARK: - LAContextProtocol

extension AppLockControllerTest {
    
    private struct MockLAContext: LAContextProtocol {
        var evaluatedPolicyDomainState: Data?
        let canEvaluate: Bool
        
        func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
            return canEvaluate
        }
        
        func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
            reply(true, nil)
        }
    }
    
}

// MARK: - BiometricsStateProtocol

extension AppLockControllerTest {
    
    private struct MockBiometricsState: BiometricsStateProtocol {
        let didChange: Bool
    
        func biometricsChanged(in context: LAContextProtocol) -> Bool {
            return didChange
        }
        
        func persistState() {}
    }
}
