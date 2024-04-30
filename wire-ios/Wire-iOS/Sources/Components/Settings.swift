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
import Foundation
import WireCommonComponents
import WireSyncEngine
import WireSystem

enum SettingsLastScreen: Int {
    case none = 0
    case list
    case conversation
}

enum SettingsCamera: Int {
    case front
    case back
}

extension Notification.Name {
    static let SettingsColorSchemeChanged = Notification.Name("SettingsColorSchemeChanged")
}

enum SettingKey: String, CaseIterable {
    case disableMarkdown = "UserDefaultDisableMarkdown"
    case chatHeadsDisabled = "ZDevOptionChatHeadsDisabled"
    case lastPushAlertDate = "LastPushAlertDate"
    case voIPNotificationsOnly = "VoIPNotificationsOnly"
    case lastViewedConversation = "LastViewedConversation"
    case colorScheme = "ColorScheme"
    case lastViewedScreen = "LastViewedScreen"
    case preferredCameraFlashMode = "PreferredCameraFlashMode"
    case preferredCamera = "PreferredCamera"
    case avsMediaManagerPersistentIntensity = "AVSMediaManagerPersistentIntensity"
    case lastUserLocation = "LastUserLocation"
    case blackListDownloadInterval = "ZMBlacklistDownloadInterval"
    case messageSoundName = "ZMMessageSoundName"
    case callSoundName = "ZMCallSoundName"
    case pingSoundName = "ZMPingSoundName"
    case sendButtonDisabled = "SendButtonDisabled"

    // MARK: Features disable keys
    case disableCallKit = "UserDefaultDisableCallKit"
    case muteIncomingCallsWhileInACall = "MuteIncomingCallsWhileInACall"
    case enableBatchCollections = "UserDefaultEnableBatchCollections"
    case callingProtocolStrategy = "CallingProtocolStrategy"

    // MARK: Link opening options
    case twitterOpeningRawValue = "TwitterOpeningRawValue"
    case mapsOpeningRawValue = "MapsOpeningRawValue"
    case browserOpeningRawValue = "BrowserOpeningRawValue"
    case callingConstantBitRate = "CallingConstantBitRate"
    case disableLinkPreviews = "DisableLinkPreviews"
}

/// Model object for locally stored (not in SE or AVS) user app settings
class Settings {
    // MARK: - subscript
    subscript<T>(index: SettingKey) -> T? {
        get {
            return defaults.value(forKey: index.rawValue) as? T
        }
        set {
            defaults.set(newValue, forKey: index.rawValue)

            /// side effects of setter

            switch index {
            case .sendButtonDisabled:
                notifyDisableSendButtonChanged()
            case .messageSoundName,
                 .callSoundName,
                 .pingSoundName:
                AVSMediaManager.sharedInstance().configureSounds()
            case .disableCallKit:
                SessionManager.shared?.updateCallNotificationStyleFromSettings()
            case .muteIncomingCallsWhileInACall:
                SessionManager.shared?.updateMuteOtherCallsFromSettings()
            case .callingConstantBitRate where !SecurityFlags.forceConstantBitRateCalls.isEnabled:
                SessionManager.shared?.useConstantBitRateAudio = newValue as? Bool ?? false
            default:
                break
            }
        }
    }

    subscript<E: RawRepresentable>(index: SettingKey) -> E? {
        get {
            if let value: E.RawValue = defaults.value(forKey: index.rawValue) as? E.RawValue {
                return E(rawValue: value)
            }

            return nil
        }
        set {
            defaults.set(newValue?.rawValue, forKey: index.rawValue)
        }
    }

    subscript(index: SettingKey) -> LocationData? {
        get {
            if let value = defaults.value(forKey: index.rawValue) as? [String: Any] {
                return LocationData.locationData(fromDictionary: value)
            }

            return nil
        }
        set {
            defaults.set(newValue?.toDictionary(), forKey: index.rawValue)
        }
    }

    var blacklistDownloadInterval: TimeInterval {
        let HOURS_6 = 6 * 60 * 60
        let settingValue = defaults.integer(forKey: SettingKey.blackListDownloadInterval.rawValue)
        return TimeInterval(settingValue > 0 ? settingValue : HOURS_6)
    }

    var defaults: UserDefaults {
        return .standard
    }

    // These settings are not actually persisted, just kept in memory
    // Max audio recording duration in seconds
    var maxRecordingDurationDebug: TimeInterval = 0.0

    static var shared: Settings = Settings()

    init() {
        ExtensionSettings.shared.disableLinkPreviews = !SecurityFlags.generateLinkPreviews.isEnabled
        restoreLastUsedAVSSettings()

        startLogging()

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    // Persist all the settings
    private func synchronize() {
        storeCurrentIntensityLevelAsLastUsed()

        defaults.synchronize()
    }

    @objc
    private func applicationDidEnterBackground(_ application: UIApplication) {
        synchronize()
    }

    static var disableLinkPreviews: Bool {
        get {
            return !SecurityFlags.generateLinkPreviews.isEnabled
                ? true
                : ExtensionSettings.shared.disableLinkPreviews
        }
        set {
            ExtensionSettings.shared.disableLinkPreviews = newValue
        }
    }
    static var isClipboardEnabled: Bool {
        return SecurityFlags.clipboard.isEnabled
    }

    // MARK: - MediaManager
    func restoreLastUsedAVSSettings() {
        if let savedIntensity = defaults.object(forKey: SettingKey.avsMediaManagerPersistentIntensity.rawValue) as? NSNumber,
            let intensityLevel = AVSIntensityLevel(rawValue: UInt(savedIntensity.intValue)) {
            AVSMediaManager.sharedInstance().intensityLevel = intensityLevel
        } else {
            AVSMediaManager.sharedInstance().intensityLevel = .full
        }
    }

    func storeCurrentIntensityLevelAsLastUsed() {
        let level = AVSMediaManager.sharedInstance().intensityLevel.rawValue
        if level >= AVSIntensityLevel.none.rawValue && level <= AVSIntensityLevel.full.rawValue {
            defaults.setValue(NSNumber(value: level), forKey: SettingKey.avsMediaManagerPersistentIntensity.rawValue)
        }
    }

    // MARK: - Debug

    private func startLogging() {
        #if !targetEnvironment(simulator)
        loadEnabledLogs()
        #endif

        #if !DISABLE_LOGGING
        ZMSLog.startRecording(isInternal: Bundle.developerModeEnabled)
        #endif
    }
}
