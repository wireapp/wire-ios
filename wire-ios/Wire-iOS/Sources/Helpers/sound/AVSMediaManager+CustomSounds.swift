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

enum MediaManagerSound: String {
    case outgoingKnockSound = "ping_from_me"
    case incomingKnockSound = "ping_from_them"
    case messageReceivedSound = "new_message"
    case firstMessageReceivedSound = "first_message"
    case someoneJoinsVoiceChannelSound = "talk"
    case transferVoiceToHereSound = "pull_voice"
    case ringingFromThemSound = "ringing_from_them"
    case ringingFromThemInCallSound = "ringing_from_them_incall"
    case callDropped = "call_drop"
    case alert
    case camera
    case someoneLeavesVoiceChannelSound = "talk_later"
}

private let zmLog = ZMSLog(tag: "AVSMediaManager CustomSounds")

extension AVSMediaManager {
    private static var MediaManagerSoundConfig: [AnyHashable: Any]?

    func play(sound: MediaManagerSound) {
        playSound(sound.rawValue)
    }

    func stop(sound: MediaManagerSound) {
        stopSound(sound.rawValue)
    }

    func playKnockSound() {
        play(sound: .outgoingKnockSound)
    }

    func mediaManagerPlayAlert() {
        playSound(MediaManagerSound.alert.rawValue)
    }

    func configureDefaultSounds() {
        guard let mediaManager = AVSMediaManager.sharedInstance() else { return }

        let audioDir = "audio-notifications"

        if AVSMediaManager.MediaManagerSoundConfig == nil,
           let path = Bundle.main.path(forResource: "MediaManagerConfig", ofType: "plist", inDirectory: audioDir) {
            let soundConfig = NSDictionary(contentsOfFile: path) as? [AnyHashable: Any]

            if soundConfig == nil {
                zmLog.error("Couldn't load sound config file: \(path)")
                return
            }

            AVSMediaManager.MediaManagerSoundConfig = soundConfig
        }

        // Unregister all previous custom sounds
        let sounds: [MediaManagerSound] = [
            .firstMessageReceivedSound,
            .messageReceivedSound,
            .ringingFromThemInCallSound,
            .ringingFromThemSound,
            .outgoingKnockSound,
            .incomingKnockSound,
        ]
        for sound in sounds {
            mediaManager.unregisterMedia(byName: sound.rawValue)
        }

        mediaManager.registerMedia(fromConfiguration: AVSMediaManager.MediaManagerSoundConfig, inDirectory: audioDir)
    }

    func unregisterCallRingingSounds() {
        guard let mediaManager = AVSMediaManager.sharedInstance() else { return }
        let sounds: [MediaManagerSound] = [.ringingFromThemInCallSound, .ringingFromThemSound]
        for sound in sounds {
            mediaManager.unregisterMedia(byName: sound.rawValue)
        }
    }

    func configureSounds() {
        configureDefaultSounds()
        configureCustomSounds()
    }

    func observeSoundConfigurationChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AVSMediaManager.didUpdateSound(_:)),
            name: NSNotification.Name(rawValue: SettingsPropertyName.messageSoundName.changeNotificationName),
            object: .none
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AVSMediaManager.didUpdateSound(_:)),
            name: NSNotification.Name(rawValue: SettingsPropertyName.callSoundName.changeNotificationName),
            object: .none
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AVSMediaManager.didUpdateSound(_:)),
            name: NSNotification.Name(rawValue: SettingsPropertyName.pingSoundName.changeNotificationName),
            object: .none
        )
    }

    private func configureCustomSounds() {
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: nil, selfUser: nil)

        let messageSoundProperty = settingsPropertyFactory.property(.messageSoundName)
        updateCustomSoundForProperty(messageSoundProperty)

        let callSoundProperty = settingsPropertyFactory.property(.callSoundName)
        updateCustomSoundForProperty(callSoundProperty)

        let pingSoundProperty = settingsPropertyFactory.property(.pingSoundName)
        updateCustomSoundForProperty(pingSoundProperty)
    }

    func updateCustomSoundForProperty(_ property: SettingsProperty) {
        let name = property.propertyName.rawValue
        let value = property.rawValue()
        if let stringValue = value as? String {
            updateCustomSoundForName(name, propertyValue: stringValue)
        }
    }

    func updateCustomSoundForName(_ propertyName: String, propertyValue: String?) {
        let value = propertyValue

        let soundValue = value == .none ? .none : ZMSound(rawValue: value!)

        switch propertyName {
        case SettingsPropertyName.messageSoundName.rawValue:
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.firstMessageReceivedSound.rawValue)
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.messageReceivedSound.rawValue)

        case SettingsPropertyName.callSoundName.rawValue:
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.ringingFromThemInCallSound.rawValue)
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.ringingFromThemSound.rawValue)

        case SettingsPropertyName.pingSoundName.rawValue:
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.outgoingKnockSound.rawValue)
            register(soundValue?.fileURL(), forMedia: MediaManagerSound.incomingKnockSound.rawValue)

        default:
            fatalError("\(propertyName) is not a sound property")
        }
    }

    // MARK: - Notifications

    @objc
    func didUpdateSound(_ notification: NSNotification?) {
        configureSounds()

        if notification?.name.rawValue == SettingsPropertyName.callSoundName.changeNotificationName {
            SessionManager.shared?.updateCallKitConfiguration()
        }
    }
}
