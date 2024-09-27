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
import WireDesign
import WireSystem

private let zmLog = ZMSLog(tag: "UI")

extension String {
    @discardableResult
    func deleteFileAtPath() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: self)
        } catch {
            zmLog.error("Cannot delete file: \(self): \(error)")
            return false
        }
        return true
    }
}

// MARK: - AVSAudioEffectType + CustomStringConvertible

extension AVSAudioEffectType: CustomStringConvertible {
    var icon: StyleKitIcon {
        switch self {
        case .none:
            .person
        case .pitchupInsane:
            .effectBalloon
        case .pitchdownInsane:
            .effectJellyfish
        case .paceupMed:
            .effectRabbit
        case .reverbMax:
            .effectChurch
        case .chorusMax:
            .alien
        case .vocoderMed:
            .robot
        case .pitchUpDownMax:
            .effectRollercoaster
        default:
            .exclamationMark
        }
    }

    public var description: String {
        switch self {
        case .chorusMin:
            "ChorusMin"
        case .chorusMax:
            "Alien"
        case .reverbMin:
            "ReverbMin"
        case .reverbMed:
            "ReverbMed"
        case .reverbMax:
            "Cathedral"
        case .pitchupMin:
            "PitchupMin"
        case .pitchupMed:
            "PitchupMed"
        case .pitchupMax:
            "PitchupMax"
        case .pitchupInsane:
            "Helium"
        case .pitchdownMin:
            "PitchdownMin"
        case .pitchdownMed:
            "PitchdownMed"
        case .pitchdownMax:
            "PitchdownMax"
        case .pitchdownInsane:
            "Jellyfish"
        case .paceupMin:
            "PaceupMin"
        case .paceupMed:
            "Hare"
        case .paceupMax:
            "PaceupMax"
        case .pacedownMin:
            "PacedownMin"
        case .pacedownMed:
            "PacedownMed"
        case .pacedownMax:
            "Turtle"
        case .reverse:
            "UpsideDown"
        case .vocoderMed:
            "VocoderMed"
        case .pitchUpDownMax:
            "Roller coaster"
        case .none:
            "None"
        default:
            "Unknown"
        }
    }

    var accessibilityLabel: String {
        typealias AudioRecord = L10n.Accessibility.AudioRecord

        switch self {
        case .none:
            return AudioRecord.NormalEffectButton.description
        case .pitchupInsane:
            return AudioRecord.HeliumEffectButton.description
        case .pitchdownInsane:
            return AudioRecord.DeepVoiceEffectButton.description
        case .paceupMed:
            return AudioRecord.QuickEffectButton.description
        case .reverbMax:
            return AudioRecord.HallEffectButton.description
        case .chorusMax:
            return AudioRecord.AlienEffectButton.description
        case .vocoderMed:
            return AudioRecord.RoboticEffectButton.description
        case .pitchUpDownMax:
            return AudioRecord.HighToDeepEffectButton.description
        default:
            return description
        }
    }

    static let displayedEffects: [AVSAudioEffectType] = [
        .none,
        .pitchupInsane,
        .pitchdownInsane,
        .paceupMed,
        .reverbMax,
        .chorusMax,
        .vocoderMed,
        .pitchUpDownMax,
    ]

    static let wr_convertQueue = DispatchQueue(label: "audioEffectQueue")

    func apply(_ inPath: String, outPath: String, completion: (() -> Void)? = .none) {
        guard !ProcessInfo.processInfo.isRunningTests else {
            return
        }

        type(of: self).wr_convertQueue.async {
            let result = AVSAudioEffect().applyWav(nil, inFile: inPath, outFile: outPath, effect: self, nr_flag: true)
            zmLog.info("applyEffect \(self) from \(inPath) to \(outPath): \(result)")
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}
