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

import AudioToolbox
import Foundation

public enum ZMSound: String, CustomStringConvertible {
    case None       = "silence"
    case WireCall   = "ringing_from_them"
    case WirePing   = "ping_from_them"
    case WireText   = "new_message"

    // MARK: Public

    public static let soundEffects = [ZMSound]()

    public static let ringtones = [ZMSound]()

    public var description: String {
        rawValue.capitalized
    }

    public var descriptionLocalizationKey: String {
        switch self {
        case .None:
            "self.settings.sound_menu.sounds.none"
        case .WireCall:
            "self.settings.sound_menu.sounds.wire_call"
        case .WireText:
            "self.settings.sound_menu.sounds.wire_message"
        case .WirePing:
            "self.settings.sound_menu.sounds.wire_ping"
        }
    }

    public static func playPreviewForURL(_ mediaURL: URL) {
        stopPlayingPreview()

        playingPreviewURL = mediaURL
        var soundId: SystemSoundID = 0

        if AudioServicesCreateSystemSoundID(mediaURL as CFURL, &soundId) == kAudioServicesNoError {
            playingPreviewID = soundId
        }

        AudioServicesPlaySystemSound(soundId)

        DispatchQueue.main
            .asyncAfter(deadline: DispatchTime.now() + Double(Int64(4 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                if playingPreviewID == soundId {
                    stopPlayingPreview()
                }
            }
    }

    public func isRingtone() -> Bool {
        type(of: self).ringtones.contains(self)
    }

    public func fileURL() -> URL? {
        switch self {
        case .None:
            return nil
        case .WireCall, .WirePing, .WireText:
            guard let path = Bundle.main.path(
                forResource: rawValue,
                ofType: type(of: self).fileExtension,
                inDirectory: "audio-notifications"
            ) else {
                return nil
            }
            return URL(fileURLWithPath: path)
        }
    }

    public func filename() -> String {
        (rawValue as NSString).appendingPathExtension(type(of: self).fileExtension)!
    }

    public func playPreview() {
        if let soundFileURL = fileURL() {
            type(of: self).playPreviewForURL(soundFileURL)
        } else {
            type(of: self).stopPlayingPreview()
        }
    }

    // MARK: Fileprivate

    fileprivate static var playingPreviewID: SystemSoundID?
    fileprivate static var playingPreviewURL: URL?

    fileprivate static let fileExtension = "m4a"

    fileprivate static func stopPlayingPreview() {
        if playingPreviewURL != nil,
           let soundId = playingPreviewID {
            AudioServicesDisposeSystemSoundID(soundId)
            playingPreviewID = .none
            playingPreviewURL = .none
        }
    }
}
