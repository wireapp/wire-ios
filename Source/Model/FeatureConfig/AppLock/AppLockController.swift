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

import Foundation
import LocalAuthentication

private let zmLog = ZMSLog(tag: "AppLockController")

public protocol AppLockType {
    var isActive: Bool { get set }
    var lastUnlockedDate: Date { get set }
    var isCustomPasscodeNotSet: Bool { get }
    var needsToNotifyUser: Bool { get set }
    var config: AppLockController.Config { get }

    func evaluateAuthentication(scenario: AppLockController.AuthenticationScenario,
                                description: String,
                                with callback: @escaping (AppLockController.AuthenticationResult, LAContext) -> Void)
    func persistBiometrics()

    func deletePasscode() throws
    func storePasscode(_ passcode: String) throws
    func fetchPasscode() -> Data?

}

public extension AppLockType {

    func updatePasscode(_ passcode: String) throws {
        try deletePasscode()
        try storePasscode(passcode)
    }

}

public final class AppLockController: AppLockType {
    
    private let selfUser: ZMUser
    private let baseConfig: Config
    
    public var config: Config {
        guard let team = selfUser.team else {
            return baseConfig
        }
        
        let feature = team.feature(for: Feature.AppLock.self)
        
        var result = baseConfig
        result.forceAppLock = baseConfig.forceAppLock || feature.config.enforceAppLock
        result.appLockTimeout = feature.config.inactivityTimeoutSecs
        result.isAvailable = (feature.status == .enabled)
        
        return result
    }
    
    // Returns true if user enabled the app lock feature or it has been forced by the team manager.
    public var isActive: Bool {
        get {
            return config.forceAppLock || selfUser.isAppLockActive
        }
        set {
            guard !config.forceAppLock else { return }
            selfUser.isAppLockActive = newValue
        }
    }
    
    // Returns the time since last lock happened.
    public var lastUnlockedDate: Date = Date(timeIntervalSince1970: 0)
    
    public var isCustomPasscodeNotSet: Bool {
        return fetchPasscode() == nil
    }
    
    public var needsToNotifyUser: Bool {
        get {
            guard let team = selfUser.team,
                let feature = team.feature(for: .appLock) else {
                    return false
            }
            return feature.needsToNotifyUser
        }
        set {
            guard let team = selfUser.team,
                let feature = team.feature(for: .appLock) else {
                    return
            }
            feature.needsToNotifyUser =  newValue
        }
    }
    
    /// a weak reference to LAContext, it should be nil when evaluatePolicy is done.
    private weak var weakLAContext: LAContext? = nil 

    lazy var keychainItem: PasscodeKeychainItem = .init(user: selfUser)
    
    // MARK: - Life cycle
    
    public init(config: Config, selfUser: ZMUser) {
        precondition(selfUser.isSelfUser, "AppLockController initialized with non-self user")
        
        self.baseConfig = config
        self.selfUser = selfUser
    }
    
    // MARK: - Methods
    
    // Creates a new LAContext and evaluates the authentication settings of the user.
    public func evaluateAuthentication(scenario: AuthenticationScenario,
                                       description: String,
                                       with callback: @escaping (AuthenticationResult, LAContext) -> Void) {
        
        guard self.weakLAContext == nil else { return }
        
        let context: LAContext = LAContext()
        var error: NSError?
        
        self.weakLAContext = context
        
        let canEvaluatePolicy = context.canEvaluatePolicy(scenario.policy, error: &error)
        
        if scenario.supportsUserFallback && (BiometricsState.biometricsChanged(in: context) || !canEvaluatePolicy) {
            callback(.needCustomPasscode, context)
            return
        }
        
        if canEvaluatePolicy {
            context.evaluatePolicy(scenario.policy, localizedReason: description, reply: { (success, error) -> Void in
                var authResult: AuthenticationResult = success ? .granted : .denied
                
                if scenario.supportsUserFallback, let laError = error as? LAError, laError.code == .userFallback {
                    authResult = .needCustomPasscode
                }
                
                callback(authResult, context)
            })
        } else {
            callback(.unavailable, context)
            zmLog.error("Local authentication error: \(String(describing: error?.localizedDescription))")
        }
    }
    
    public func persistBiometrics() {
        BiometricsState.persist()
    }
    
    
    // MARK: - Types
    
    public struct Config {
        public let useBiometricsOrCustomPasscode: Bool
        public var forceAppLock: Bool
        public var appLockTimeout: UInt
        public var isAvailable: Bool
        
        public init(useBiometricsOrCustomPasscode: Bool,
                    forceAppLock: Bool,
                    timeOut: UInt) {
            self.useBiometricsOrCustomPasscode = useBiometricsOrCustomPasscode
            self.forceAppLock = forceAppLock
            self.appLockTimeout = timeOut
            self.isAvailable = true
        }
    }
    
    public enum AuthenticationResult {
        /// User sucessfully authenticated
        case granted
        /// User failed to authenticate or cancelled the request
        case denied
        /// There's no authenticated method available (no passcode is set)
        case unavailable
        /// Biometrics failed and custom passcode is needed
        case needCustomPasscode
    }
    
    public enum AuthenticationScenario {
        case screenLock(requireBiometrics: Bool)
        case databaseLock
        
        var policy: LAPolicy {
            switch self {
            case .screenLock(requireBiometrics: let requireBiometrics):
                return requireBiometrics ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
            case .databaseLock:
                return .deviceOwnerAuthentication
            }
        }
        
        var supportsUserFallback: Bool {
            switch self {
            case .screenLock:
                return true
            case .databaseLock:
                return false
            }
        }
    }
}

// MARK: - BiometricsState

public class BiometricsState {
    private static let UserDefaultsDomainStateKey = "DomainStateKey"
    
    private static var lastPolicyDomainState: Data? {
        get {
            return UserDefaults.standard.data(forKey: UserDefaultsDomainStateKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsDomainStateKey)
        }
    }
    
    private static var currentPolicyDomainState: Data?
    
    // Tells us if biometrics database has changed (ex: fingerprints added or removed)
    public static func biometricsChanged(in context: LAContext) -> Bool {
        currentPolicyDomainState = context.evaluatedPolicyDomainState
        guard let currentState = currentPolicyDomainState,
            let lastState = lastPolicyDomainState,
            currentState == lastState else {
                return true
        }
        return false
    }
    
    /// Persists the state of the biometric credentials.
    /// Should be called after a successful unlock with account password
    public static func persist() {
        lastPolicyDomainState = currentPolicyDomainState
    }
}
