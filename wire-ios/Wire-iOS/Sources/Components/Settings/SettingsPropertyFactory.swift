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

// MARK: - TrackingInterface

protocol TrackingInterface {
    var disableAnalyticsSharing: Bool { get set }
}

// MARK: - AVSMediaManagerInterface

protocol AVSMediaManagerInterface {
    var intensityLevel: AVSIntensityLevel { get set }
    var isMicrophoneMuted: Bool { get set }
}

// MARK: - AVSMediaManager + AVSMediaManagerInterface

extension AVSMediaManager: AVSMediaManagerInterface {}

typealias SettingsSelfUser = EditableUserType & UserType

// MARK: - SettingsPropertyError

enum SettingsPropertyError: Error {
    case WrongValue(String)
}

// MARK: - SettingsPropertyFactoryDelegate

protocol SettingsPropertyFactoryDelegate: AnyObject {
    func asyncMethodDidStart(_ settingsPropertyFactory: SettingsPropertyFactory)
    func asyncMethodDidComplete(_ settingsPropertyFactory: SettingsPropertyFactory)

    func appLockOptionDidChange(
        _ settingsPropertyFactory: SettingsPropertyFactory,
        newValue: Bool,
        callback: @escaping  ResultHandler
    )
}

// MARK: - SettingsPropertyFactory

final class SettingsPropertyFactory {
    // MARK: Lifecycle

    convenience init(userSession: UserSession?, selfUser: SettingsSelfUser?) {
        self.init(
            userDefaults: UserDefaults.standard,
            tracking: TrackingManager.shared,
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
        self.userPropertyValidator = UserPropertyValidator()

        userSession?.fetchMarketingConsent { [weak self] result in
            switch result {
            case .failure:
                self?.marketingConsent = .none
            case let .success(result):
                self?.marketingConsent = SettingsPropertyValue.bool(value: result)
            }
        }
    }

    // MARK: Internal

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
        SettingsPropertyName.callingConstantBitRate: .callingConstantBitRate,
    ]

    let userDefaults: UserDefaults
    var tracking: TrackingInterface?
    var mediaManager: AVSMediaManagerInterface?
    weak var userSession: UserSession?
    var selfUser: SettingsSelfUser?
    var marketingConsent: SettingsPropertyValue = .none
    let userPropertyValidator: UserPropertyValidating
    weak var delegate: SettingsPropertyFactoryDelegate?

    func property(_ propertyName: SettingsPropertyName) -> SettingsProperty {
        switch propertyName {
        // Profile
        case .profileName:
            let getAction: GetAction = { [unowned self] _ in
                SettingsPropertyValue.string(value: selfUser?.name ?? "")
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .string(stringValue):
                    guard let selfUser else {
                        requireInternal(
                            false,
                            "Attempt to modify a user property without a self user"
                        ); break
                    }

                    var inOutString: String? = stringValue as String
                    _ = try userPropertyValidator.validate(name: &inOutString)
                    userSession?.enqueue {
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
            return getOnlyProperty(
                propertyName: propertyName,
                value: selfUser?.handleDisplayString(withDomain: BackendInfo.isFederationEnabled)
            )

        case .team:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.teamName)

        case .domain:
            return getOnlyProperty(propertyName: propertyName, value: selfUser?.domain)

        case .accentColor:
            let getAction: GetAction = { [unowned self] _ in
                SettingsPropertyValue(selfUser?.accentColorValue ?? 0)
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .number(number):
                    userSession?.enqueue {
                        self.selfUser?.accentColorValue = number.int16Value
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }

            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .darkMode:
            let getAction: GetAction = { [unowned self] _ in

                let settingsColorScheme = SettingsColorScheme(
                    from: userDefaults
                        .string(forKey: SettingKey.colorScheme.rawValue)
                )

                return SettingsPropertyValue(settingsColorScheme.rawValue)
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .number(number):
                    if let settingsColorScheme = SettingsColorScheme(rawValue: Int(number.int64Value)) {
                        userDefaults.set(
                            settingsColorScheme.keyValueString,
                            forKey: SettingKey.colorScheme.rawValue
                        )
                    } else {
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }

                NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
            }

            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: getAction,
                setAction: setAction
            )

        case .soundAlerts:
            let getAction: GetAction = { [unowned self] _ in
                if let mediaManager {
                    return SettingsPropertyValue(mediaManager.intensityLevel.rawValue)
                } else {
                    return SettingsPropertyValue(0)
                }
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .number(intValue):
                    if let intensivityLevel = AVSIntensityLevel(rawValue: UInt(truncating: intValue)),
                       var mediaManager {
                        mediaManager.intensityLevel = intensivityLevel
                    } else {
                        throw SettingsPropertyError
                            .WrongValue("Cannot use value \(intValue) for AVSIntensivityLevel at \(propertyName)")
                    }

                default:
                    throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .disableAnalyticsSharing:
            let getAction: GetAction = { [unowned self] _ in
                if let tracking {
                    return SettingsPropertyValue(tracking.disableAnalyticsSharing)
                } else {
                    return SettingsPropertyValue(false)
                }
            }

            let setAction: SetAction = { [unowned self] _, value in
                if var tracking {
                    switch value {
                    case let .number(number):
                        tracking.disableAnalyticsSharing = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            }
            return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)

        case .receiveNewsAndOffers:

            let getAction: GetAction = { [unowned self] _ in
                marketingConsent
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .number(number):
                    guard let userSession else {
                        return
                    }

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
                if let value = userSession?.isNotificationContentHidden {
                    return SettingsPropertyValue.number(value: NSNumber(value: value))
                } else {
                    return .none
                }
            }

            let setAction: SetAction = { [unowned self] _, value in
                switch value {
                case let .number(number):
                    userSession?.perform {
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
                    return SettingsPropertyValue(disableSendButton ?? false)
                },
                setAction: { _, value in
                    switch value {
                    case let .number(value: number):
                        Settings.shared[.sendButtonDisabled] = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            )

        case .lockApp:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    SettingsPropertyValue(self.isAppLockActive)
                },
                setAction: { _, value in
                    switch value {
                    case let .number(value: lockApp):
                        self.delegate?.appLockOptionDidChange(
                            self,
                            newValue: lockApp.boolValue,
                            callback: { result in
                                self.userSession?.perform {
                                    self.isAppLockActive = result
                                }
                            }
                        )

                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            )

        case .callingConstantBitRate:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let callingConstantBitRate: Bool = Settings.shared[.callingConstantBitRate] ?? false
                    return SettingsPropertyValue(callingConstantBitRate)
                },
                setAction: { _, value in
                    if case let .number(enabled) = value {
                        Settings.shared[.callingConstantBitRate] = enabled.boolValue
                    }
                }
            )

        case .disableLinkPreviews:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in SettingsPropertyValue(Settings.disableLinkPreviews) },
                setAction: { _, value in
                    switch value {
                    case let .number(value: number):
                        Settings.disableLinkPreviews = number.boolValue
                    default:
                        throw SettingsPropertyError.WrongValue("Incorrect type \(value) for key \(propertyName)")
                    }
                }
            )

        case .disableCallKit:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let disableCallKit: Bool = Settings.shared[.disableCallKit] ?? false
                    return SettingsPropertyValue(disableCallKit)
                },
                setAction: { _, value in
                    if case let .number(disabled) = value {
                        Settings.shared[.disableCallKit] = disabled.boolValue
                    }
                }
            )

        case .muteIncomingCallsWhileInACall:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let muteIncomingCallsWhileInACall: Bool = Settings.shared[.muteIncomingCallsWhileInACall] ?? false
                    return SettingsPropertyValue(muteIncomingCallsWhileInACall)
                },
                setAction: { _, value in
                    if case let .number(shouldMute) = value {
                        Settings.shared[.muteIncomingCallsWhileInACall] = shouldMute.boolValue
                    }
                }
            )

        case .readReceiptsEnabled:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { _ in
                    let value = self.selfUser?.readReceiptsEnabled ?? false
                    return SettingsPropertyValue(value)
                },
                setAction: { _, value in
                    if case let .number(enabled) = value,
                       let userSession = self.userSession {
                        userSession.perform {
                            self.selfUser?.readReceiptsEnabled = enabled.boolValue
                        }
                    }
                }
            )

        case .encryptMessagesAtRest:
            return SettingsBlockProperty(
                propertyName: propertyName,
                getAction: { [weak self] _ in
                    let value = self?.userSession?.encryptMessagesAtRest ?? false
                    return SettingsPropertyValue(value)
                },
                setAction: { [weak self] _, value in
                    guard case let .number(enabled) = value else {
                        return
                    }
                    try? self?.userSession?.setEncryptionAtRest(enabled: enabled.boolValue, skipMigration: false)
                }
            )

        default:
            if let userDefaultsKey = type(of: self).userDefaultsPropertiesToKeys[propertyName] {
                return SettingsUserDefaultsProperty(
                    propertyName: propertyName,
                    userDefaultsKey: userDefaultsKey.rawValue,
                    userDefaults: userDefaults
                )
            }
        }

        fatalError("Cannot create SettingsProperty for \(propertyName)")
    }

    // MARK: Private

    private func getOnlyProperty(propertyName: SettingsPropertyName, value: String?) -> SettingsBlockProperty {
        let getAction: GetAction = { _ in
            SettingsPropertyValue.string(value: value ?? "")
        }
        let setAction: SetAction = { _, _ in }
        return SettingsBlockProperty(propertyName: propertyName, getAction: getAction, setAction: setAction)
    }
}
