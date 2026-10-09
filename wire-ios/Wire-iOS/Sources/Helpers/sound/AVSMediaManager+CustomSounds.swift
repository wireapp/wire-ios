//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLogging

enum MediaManagerSound: String {
    case outgoingKnockSound = "ping_from_me"
    case incomingKnockSound = "ping_from_them"
    case messageReceivedSound = "new_message"
    case someoneJoinsVoiceChannelSound = "talk"
    case transferVoiceToHereSound = "pull_voice"
    case ringingFromThemSound = "ringing_from_them"
    case ringingFromThemInCallSound = "ringing_from_them_incall"
    case callDropped = "call_drop"
    case alert
    case camera
    case someoneLeavesVoiceChannelSound = "talk_later"
}

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
                WireLogger.avs.error("CustomSounds: Couldn't load sound config file: \(path)")
                return
            }

            AVSMediaManager.MediaManagerSoundConfig = soundConfig
        }

        // Unregister all previous custom sounds
        let sounds: [MediaManagerSound] = [
            .messageReceivedSound,
            .ringingFromThemInCallSound,
            .ringingFromThemSound,
            .outgoingKnockSound,
            .incomingKnockSound
        ]
        sounds.forEach {
            mediaManager.unregisterMedia(byName: $0.rawValue)
        }

        mediaManager.registerMedia(fromConfiguration: AVSMediaManager.MediaManagerSoundConfig, inDirectory: audioDir)
    }

    func unregisterCallRingingSounds() {
        guard let mediaManager = AVSMediaManager.sharedInstance() else { return }
        let sounds: [MediaManagerSound] = [.ringingFromThemInCallSound, .ringingFromThemSound]
        sounds.forEach {
            mediaManager.unregisterMedia(byName: $0.rawValue)
        }
    }

    func configureSounds() {
        configureDefaultSounds()
        configureMessageNotificationSound()
    }

    private func configureMessageNotificationSound() {
        let resourceName = switch ExtensionSettings.shared.messageNotificationSound {
        case .wire:
            "new_message"
        case .wireOld:
            "new_message_legacy"
        }

        let soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf")
        register(soundURL, forMedia: MediaManagerSound.messageReceivedSound.rawValue)
    }

    func observeSoundConfigurationChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AVSMediaManager.didUpdateSound(_:)),
            name: NSNotification.Name(rawValue: SettingsPropertyName.notificationSound.changeNotificationName),
            object: .none
        )
    }

    // MARK: - Notifications

    @objc
    func didUpdateSound(_: NSNotification?) {
        configureSounds()
    }
}
