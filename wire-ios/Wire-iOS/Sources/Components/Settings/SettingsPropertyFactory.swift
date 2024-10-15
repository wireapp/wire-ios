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

import avs
import WireCommonComponents
import WireSyncEngine
import WireUtilities

protocol TrackingInterface {

    var isAnalyticsDisabled: Bool { get }
    func requestAnalyticsConsent() async throws -> Bool
    func disableAnalytics() throws
    func enableAnalytics() async throws

}

protocol AVSMediaManagerInterface {
    var intensityLevel: AVSIntensityLevel { get set }
    var isMicrophoneMuted: Bool { get set }
}

extension AVSMediaManager: AVSMediaManagerInterface {
}

typealias SettingsSelfUser = EditableUserType & UserType

enum SettingsPropertyError: Error {
    case WrongValue(String)
}

protocol SettingsPropertyFactoryDelegate: AnyObject {
    func asyncMethodDidStart(_ settingsPropertyFactory: SettingsPropertyFactory)
    func asyncMethodDidComplete(_ settingsPropertyFactory: SettingsPropertyFactory)

    func appLockOptionDidChange(_ settingsPropertyFactory: SettingsPropertyFactory, newValue: Bool, callback: @escaping  ResultHandler)
}

final class SettingsPropertyFactory {
    let userDefaults: UserDefaults
    var tracking: TrackingInterface?
    var mediaManager: AVSMediaManagerInterface?
    weak var userSession: UserSession?
    var selfUser: SettingsSelfUser?
    var marketingConsent: SettingsPropertyValue = .none
    let userPropertyValidator: UserPropertyValidating
    weak var delegate: SettingsPropertyFactoryDelegate?

    static let userDefaultsPropertiesToKeys: [SettingsPropertyName: SettingKey] = [
        SettingsPropertyName.disableMarkdown: .disableMarkdown,
        SettingsPropertyName.chatHeadsDisabled: .chatHeadsDisabled,
        SettingsPropertyName.messageSoundName: .messageSoundName,
        SettingsPropertyName.callSoundName: .callSoundName,
        SettingsPropertyName.pingSoundName: .pingSoundName,
        SettingsPropertyName.disableSendButton: .sendButtonDisabled,
        SettingsPropertyName.mapsOpeningOption: .mapsOpeningRawValue,
        SettingsPropertyName.browserOpeningOption: .browserOpeningRawValue,
        SettingsPropertyName.tweetOpeningOption: .twitterOpeningRawValue,
        SettingsPropertyName.callingProtocolStrategy: .callingProtocolStrategy,
        SettingsPropertyName.enableBatchCollections: .enableBatchCollections,
        SettingsPropertyName.callingConstantBitRate: .callingConstantBitRate
    ]

    convenience init(
        userSession: UserSession?,
        trackingManager: TrackingManager?,
        selfUser: SettingsSelfUser?
    ) {
        self.init(
            userDefaults: UserDefaults.standard,
            tracking: trackingManager,
            mediaManager: AVSMediaManager.sharedInstance(),
            userSession: userSession,
            selfUser: selfUser
        )
    }

    init(
        userDefaults: UserDefaults,
        tracking: TrackingInterface?,
        mediaManager: AVSMediaManagerInterface?,
        userSession: UserSession?,
        selfUser: SettingsSelfUser?
    ) {
        self.userDefaults = userDefaults
        self.tracking = tracking
        self.mediaManager = mediaManager
        self.userSession = userSession
        self.selfUser = selfUser
        userPropertyValidator = UserPropertyValidator()

        userSession?.fetchMarketingConsent { [weak self] result in
            switch result {
            case .failure:
                self?.marketingConsent = .none
            case .success(let result):
                self?.marketingConsent = SettingsPropertyValue.bool(value: result)
            }
        }
    }

    private func getOnlyProperty(propertyName: SettingsPropertyName, value: String?) -> SettingsBlockProperty {
        let getAction: GetAction = { _ in
            SettingsPropertyValue.string(value: value ?? "")
        }
        let setAction: SetAction = { _, _, _  in }
        return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
    }

    func property(_ propertyName: SettingsPropertyName) -> SettingsProperty {

        switch propertyName {
        // Profile
        case .profileName:
            let getAction: GetAction = { [unowned self] _ in
                return SettingsPropertyValue.string(value: self.selfUser?.name ?? "")
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .string(let stringValue):
                    guard let selfUser = self.selfUser else { requireInternal(false, "Attempt to modify a user property without a self user"); break }

                    var inOutString: String? = stringValue as String
                    _ = try userPropertyValidator.validate(name: &inOutString)
                    self.userSession?.enqueue {
                        selfUser.name = stringValue
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .email:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.emailAddress)

        case .handle:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.handleDisplayString(withDomain: BackendInfo.isFederationEnabled))

        case .team:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.teamName)

        case .domain:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.domain)

        case .accentColor:
            let getAction: GetAction = { [unowned self] _ in
                SettingsPropertyValue(self.selfUser?.accentColorValue ?? 0)
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .number(let number):
                    self.userSession?.enqueue({
                        self.selfUser?.accentColorValue = number.int16Value
                    })
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
        case .darkMode:
            let getAction: GetAction = { [unowned self] _ in

                let settingsColorScheme: SettingsColorScheme = SettingsColorScheme(from: self.userDefaults.string(forKey: SettingKey.colorScheme.rawValue))

                return SettingsPropertyValue(settingsColorScheme.rawValue)
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .number(let number):
                    if let settingsColorScheme = SettingsColorScheme(rawValue: Int(number.int64Value)) {
                        self.userDefaults.set(settingsColorScheme.keyValueString,
                                              forKey: SettingKey.colorScheme.rawValue)
                    } else {
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }

                NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
            }

            return SettingsBlockProperty(propertyName: propertyName,
                                         getAction: getAction,
                                         setAction: setAction)
        case .soundAlerts:
            let getAction: GetAction = { [unowned self] _ in
                if let mediaManager = self.mediaManager {
                    return SettingsPropertyValue(mediaManager.intensityLevel.rawValue)
                } else {
                    return SettingsPropertyValue(0)
                }
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .number(let intValue):
                    if let intensivityLevel = AVSIntensityLevel(rawValue: UInt(truncating: intValue)),
                        var mediaManager = self.mediaManager {
                        mediaManager.intensityLevel = intensivityLevel
                    } else {
                        throw SettingsPropertyError.WrongValue("Cannot use value \(intValue) for AVSIntensivityLevel at \(propertyName)")
                    }
                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .disableAnalyticsSharing:
            let getAction: GetAction = { [unowned self] _ in
                if let tracking = self.tracking {
                    return SettingsPropertyValue(tracking.isAnalyticsDisabled)
                } else {
                    return SettingsPropertyValue(false)
                }
            }

            let setAction: SetAction = { [unowned self] _, value, resultHandler in
                guard let tracking else {
                    return
                }
                
                guard case .number(let shouldDisable) = value else {
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }

                Task { @MainActor in
                    do {
                        if shouldDisable.boolValue {
                            try tracking.disableAnalytics()
                        } else {
                            guard try await tracking.requestAnalyticsConsent() else {
                                throw TrackingManagerError.userConsentDenied
                            }

                            try await tracking.enableAnalytics()
                        }
                    } catch {
                        resultHandler(.failure(error))
                    }

                    resultHandler(.success(()))
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .receiveNewsAndOffers:

            let getAction: GetAction = { [unowned self] _ in
                return self.marketingConsent
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .number(let number):
                    guard let userSession = self.userSession else { return }

                    userSession.perform {
                        self.delegate?.asyncMethodDidStart(self)
                        userSession.setMarketingConsent(granted: number.boolValue) { [weak self] _ in
                            if let self {
                                marketingConsent = SettingsPropertyValue.number(value: number)
                                delegate?.asyncMethodDidComplete(self)
                            }
                        }
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .notificationContentVisible:
            let getAction: GetAction = { [unowned self] _ in
                if let value = self.userSession?.isNotificationContentHidden {
                    return SettingsPropertyValue.number(value: NSNumber(value: value))
                } else {
                    return .none
                }
            }

            let setAction: SetAction = { [unowned self] _, value, _  in
                switch value {
                case .number(let number):
                    self.userSession?.perform {
                        self.userSession?.isNotificationContentHidden = number.boolValue
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type: \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .disableSendButton:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let disableSendButton: Bool? = Settings.shared[.sendButtonDisabled]
                    return SettingsPropertyValue(disableSendButton ?? false) },
                setAction: { _, value, _  in
                    switch value {
                    case .number(value: let number):
                        Settings.shared[.sendButtonDisabled] = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .lockApp:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    return SettingsPropertyValue(self.isAppLockActive)
            },
                setAction: { _, value, _  in
                    switch value {
                    case .number(value: let lockApp):
                        self.delegate?.appLockOptionDidChange(self,
                                                              newValue: lockApp.boolValue,
                                                              callback: { result in
                           self.userSession?.perform {
                               self.isAppLockActive = result
                           }
                        })

                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })

        case .callingConstantBitRate:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let callingConstantBitRate: Bool = Settings.shared[.callingConstantBitRate] ?? false
                    return SettingsPropertyValue(callingConstantBitRate) },
                setAction: { _, value, _  in
                    if case .number(let enabled) = value {
                        Settings.shared[.callingConstantBitRate] = enabled.boolValue
                    }
            })

        case .disableLinkPreviews:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in return SettingsPropertyValue(Settings.disableLinkPreviews) },
                setAction: { _, value, _  in
                    switch value {
                    case .number(value: let number):
                        Settings.disableLinkPreviews = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
            })
        case .disableCallKit:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let disableCallKit: Bool = Settings.shared[.disableCallKit] ?? false
                    return SettingsPropertyValue(disableCallKit) },
                setAction: { _, value, _  in
                    if case .number(let disabled) = value {
                        Settings.shared[.disableCallKit] = disabled.boolValue
                    }
            })
        case .muteIncomingCallsWhileInACall:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let muteIncomingCallsWhileInACall: Bool = Settings.shared[.muteIncomingCallsWhileInACall] ?? false
                    return SettingsPropertyValue(muteIncomingCallsWhileInACall) },
                setAction: { _, value, _  in
                    if case .number(let shouldMute) = value {
                        Settings.shared[.muteIncomingCallsWhileInACall] = shouldMute.boolValue
                    }
            })
        case .readReceiptsEnabled:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let value = self.selfUser?.readReceiptsEnabled ?? false
                    return SettingsPropertyValue(value)
            },
                setAction: { _, value, _ in
                    if case .number(let enabled) = value,
                        let userSession = self.userSession {
                            userSession.perform {
                                self.selfUser?.readReceiptsEnabled = enabled.boolValue
                            }
                        }
            })
        case .encryptMessagesAtRest:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { [weak self] _ in
                    let value = self?.userSession?.encryptMessagesAtRest ?? false
                    return SettingsPropertyValue(value)
            },
                setAction: { [weak self] _, value, _  in
                    guard case .number(let enabled) = value else { return }
                    try? self?.userSession?.setEncryptionAtRest(enabled: enabled.boolValue, skipMigration: false)
            })
        default:
            if let userDefaultsKey = type(of: self).userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(propertyName: propertyName, userDefaultsKey: userDefaultsKey.rawValue, userDefaults: userDefaults)
            }
        }

        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }
}
