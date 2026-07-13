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

#if DEBUG

    import AVFoundation
    import UIKit
    import WireLogging

    final class UITestAudioRecorder: AudioRecorderType {

        let format: AudioRecorderFormat = .wav
        var state: AudioRecorderState = .initializing
        var fileURL: URL?
        var maxRecordingDuration: TimeInterval?
        var maxFileSize: UInt64?
        var currentDuration: TimeInterval = 0
        var recordTimerCallback: ((TimeInterval) -> Void)?
        var recordLevelCallBack: ((RecordingLevel) -> Void)?
        var playingStateCallback: ((PlayingState) -> Void)?
        var recordEndedCallback: ((Result<Void, Error>) -> Void)?

        func startRecording(_ completion: @escaping (_ success: Bool) -> Void) {
            currentDuration = 2
            state = .recording(start: 0)
            recordTimerCallback?(0)
            recordLevelCallBack?(0.5)
            recordTimerCallback?(currentDuration)
            completion(true)
        }

        @discardableResult
        func stopRecording() -> Bool {
            do {
                fileURL = try Self.makeAudioFile(duration: currentDuration)
                state = .stopped
                recordLevelCallBack?(0)
                recordEndedCallback?(.success(()))
                return true
            } catch {
                WireLogger.ui.error("Failed to create UI test audio recording: \(error)")
                return false
            }
        }

        func deleteRecording() {
            if let fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            fileURL = nil
            currentDuration = 0
            state = .initializing
        }

        func playRecording() {
            playingStateCallback?(.playing)
            recordTimerCallback?(currentDuration)
        }

        func stopPlaying() {
            playingStateCallback?(.idle)
        }

        func levelForCurrentState() -> RecordingLevel {
            0.5
        }

        func durationForCurrentState() -> TimeInterval? {
            currentDuration
        }

        func alertForRecording(error: RecordingError) -> UIAlertController? {
            nil
        }

        private static func makeAudioFile(duration: TimeInterval) throws -> URL {
            let sampleRate = 44_100.0
            let frames = AVAudioFrameCount(sampleRate * duration)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
            buffer.frameLength = frames

            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("uitest-audio-\(UUID().uuidString).wav")
            let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            try audioFile.write(from: buffer)
            return url
        }
    }

#endif
