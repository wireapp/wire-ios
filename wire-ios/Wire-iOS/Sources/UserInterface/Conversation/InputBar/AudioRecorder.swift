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
import MediaPlayer
import WireSyncEngine

// MARK: - PlayingState

enum PlayingState: UInt, CustomStringConvertible {
    case idle, playing

    // MARK: Internal

    var description: String {
        switch self {
        case .idle: "idle"
        case .playing: "playing"
        }
    }
}

typealias RecordingLevel = Float

// MARK: - AudioRecorderFormat

enum AudioRecorderFormat {
    case m4A, wav

    // MARK: Internal

    func fileExtension() -> String {
        switch self {
        case .m4A:
            "m4a"
        case .wav:
            "wav"
        }
    }

    func audioFormat() -> AudioFormatID {
        switch self {
        case .m4A:
            kAudioFormatMPEG4AAC
        case .wav:
            kAudioFormatLinearPCM
        }
    }
}

// MARK: - AudioRecorderState

enum AudioRecorderState: Equatable {
    case initializing, recording(start: TimeInterval), stopped
}

// MARK: - RecordingError

enum RecordingError: Error {
    case toMaxDuration, toMaxSize
}

// MARK: - AudioRecorderType

protocol AudioRecorderType: AnyObject {
    var format: AudioRecorderFormat { get }
    var state: AudioRecorderState { get set }
    var fileURL: URL? { get }
    var maxRecordingDuration: TimeInterval? { get set }
    var maxFileSize: UInt64? { get set }
    var currentDuration: TimeInterval { get }
    var recordTimerCallback: ((TimeInterval) -> Void)? { get set }
    var recordLevelCallBack: ((RecordingLevel) -> Void)? { get set }
    var playingStateCallback: ((PlayingState) -> Void)? { get set }
    var recordEndedCallback: ((Result<Void, Error>) -> Void)? { get set }

    func startRecording(_ completion: @escaping (_ success: Bool) -> Void)
    @discardableResult
    func stopRecording() -> Bool
    func deleteRecording()
    func playRecording()
    func stopPlaying()
    func levelForCurrentState() -> RecordingLevel
    func durationForCurrentState() -> TimeInterval?
    func alertForRecording(error: RecordingError) -> UIAlertController?
}

// MARK: - AudioRecorder

final class AudioRecorder: NSObject, AudioRecorderType {
    // MARK: Lifecycle

    override init() {
        fatalError("init() is not implemented for AudioRecorder")
    }

    init(format: AudioRecorderFormat = .m4A, maxRecordingDuration: TimeInterval?, maxFileSize: UInt64?) {
        self.format = format
        self.maxRecordingDuration = maxRecordingDuration
        self.maxFileSize = maxFileSize
        super.init()
        setupDidEnterBackgroundObserver()
    }

    deinit {
        token.map(NotificationCenter.default.removeObserver)
        removeDisplayLink()
        audioRecorder?.delegate = nil
    }

    // MARK: Internal

    let format: AudioRecorderFormat
    var state: AudioRecorderState = .initializing

    var audioRecorder: AVAudioRecorder?

    var displayLink: CADisplayLink?
    var audioPlayer: AVAudioPlayer?
    var audioPlayerDelegate: AudioPlayerDelegate?
    var pauseButtonCallback: Any?
    var maxRecordingDuration: TimeInterval? = .none
    let fm = FileManager.default
    var currentDuration: TimeInterval = 0
    var recordTimerCallback: ((TimeInterval) -> Void)?
    var recordLevelCallBack: ((RecordingLevel) -> Void)?
    var playingStateCallback: ((PlayingState) -> Void)?
    var recordEndedCallback: ((Result<Void, Error>) -> Void)?
    var fileURL: URL?
    var maxFileSize: UInt64?

    func createAudioRecorderIfNeeded() {
        guard self.audioRecorder == nil else {
            return
        }
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let fileName = String.filename(for: selfUser).appendingPathExtension(format.fileExtension())!
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        self.fileURL = fileURL

        let audioRecorder = makeAudioRecorder(
            audioFormatID: format.audioFormat(),
            fileURL: fileURL!
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        self.audioRecorder = audioRecorder
    }

    // MARK: Audio Session Interruption handling

    @objc
    func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            stopRecording()
        }
    }

    // MARK: Recording

    func startRecording(_ completion: @escaping (_ success: Bool) -> Void) {
        createAudioRecorderIfNeeded()

        guard let audioRecorder else {
            return
        }

        AVSMediaManager.sharedInstance().startRecording {
            guard self.state == .initializing else {
                return AVSMediaManager.sharedInstance().stopRecording()
            }

            UIApplication.shared.isIdleTimerDisabled = true

            self.recordTimerCallback?(0)
            self.setupDisplayLink()

            var successfullyStarted = false

            if let maxDuration = self.maxRecordingDuration {
                successfullyStarted = audioRecorder.record(forDuration: maxDuration)
            } else {
                successfullyStarted = audioRecorder.record()
            }

            if successfullyStarted {
                self.state = .recording(start: audioRecorder.deviceCurrentTime)
            } else {
                WireLogger.ui.error("Failed to start audio recording")
            }

            completion(successfullyStarted)
        }
    }

    @discardableResult
    func stopRecording() -> Bool {
        UIApplication.shared.isIdleTimerDisabled = false
        audioRecorder?.stop()
        state = .stopped
        return postRecordingProcessing()
    }

    func deleteRecording() {
        currentDuration = 0

        if let filePath = audioRecorder?.url.path, FileManager.default.fileExists(atPath: filePath) {
            audioRecorder?.deleteRecording()
        }

        state = .initializing
    }

    // MARK: Playing

    func playRecording() {
        guard
            let audioRecorder,
            ZMUserSession.shared()?.isCallOngoing == false
        else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            WireLogger.ui.error("Failed change audio category for playback: \(error)")
        }

        setupDisplayLink()
        audioPlayer = try? AVAudioPlayer(contentsOf: audioRecorder.url)
        audioPlayer?.isMeteringEnabled = true

        audioPlayerDelegate = AudioPlayerDelegate { [weak self] _ in
            guard let self else {
                return
            }
            removeDisplayLink()
            playingStateCallback?(.idle)
            recordLevelCallBack?(0)
            guard let duration = audioPlayer?.duration else {
                return
            }
            recordTimerCallback?(duration)
        }

        audioPlayer?.delegate = audioPlayerDelegate
        audioPlayer?.play()
        playingStateCallback?(.playing)
    }

    func stopPlaying() {
        recordLevelCallBack?(0)
        removeDisplayLink()
        audioPlayer?.pause()
        playingStateCallback?(.idle)
    }

    // MARK: Leveling & Duration

    func levelForCurrentState() -> RecordingLevel {
        let powerProvider: PowerProvider? = state == .stopped ? audioPlayer : audioRecorder
        powerProvider?.updateMeters()
        let level = powerProvider?.averagePowerForFirstActiveChannel() ?? minimumPower
        // This value is in dB (logarithmic, [-160, 0]) and varies between -160 and 0 so we need to normalize it, see
        // https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioRecorder_ClassReference/#//apple_ref/occ/instm/AVAudioRecorder/peakPowerForChannel:
        return level.normalizedDecibelValue()
    }

    func durationForCurrentState() -> TimeInterval? {
        switch state {
        case .initializing:
            return nil

        case let .recording(startTime):
            guard let recorder = audioRecorder else {
                return nil
            }
            return recorder.deviceCurrentTime - startTime

        case .stopped:
            return audioPlayer?.currentTime
        }
    }

    func alertForRecording(error: RecordingError) -> UIAlertController? {
        var alertMessage: String?

        if error == .toMaxDuration {
            let duration = Int(ceil(maxRecordingDuration ?? 0))
            let (seconds, minutes) = (duration % 60, duration / 60)
            let durationLimit = String(format: "%d:%02d", minutes, seconds)

            alertMessage = L10n.Localizable.Conversation.InputBar.AudioMessage.TooLong.message(durationLimit)
        }

        if error == .toMaxSize, let maxSize = maxFileSize {
            let size = ByteCountFormatter.string(fromByteCount: Int64(maxSize), countStyle: .binary)

            alertMessage = L10n.Localizable.Conversation.InputBar.AudioMessage.TooLongSize.message(size)
        }

        guard alertMessage != nil else {
            return nil
        }

        let alertController = UIAlertController(
            title: L10n.Localizable.Conversation.InputBar.AudioMessage.TooLong.title,
            message: alertMessage!,
            preferredStyle: .alert
        )

        let actionOk = UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default,
            handler: nil
        )
        alertController.addAction(actionOk)

        return alertController
    }

    // MARK: Fileprivate

    fileprivate var audioSizeIsCritical: Bool {
        guard let fileURL,
              let attribs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attribs[.size] as? UInt32,
              size > maxAllowedSize else {
            return false
        }
        WireLogger.ui
            .debug(
                "Audio message size is over the maximum amount allowed. File size is \(size), threshold is \(maxAllowedSize)"
            )
        return true
    }

    fileprivate func postRecordingProcessing() -> Bool {
        recordLevelCallBack?(0)
        removeDisplayLink()
        guard let filePath = audioRecorder?.url.path, fm.fileExists(atPath: filePath) else {
            return false
        }
        fileURL = audioRecorder?.url
        return true
    }

    fileprivate func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .current, forMode: .common)
    }

    fileprivate func removeDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc
    fileprivate func displayLinkDidFire() {
        recordLevelCallBack?(levelForCurrentState())
        guard let duration = durationForCurrentState(), currentDuration != duration else {
            return
        }
        currentDuration = duration
        recordTimerCallback?(currentDuration)

        if audioSizeIsCritical {
            stopRecording()
        }
    }

    // MARK: Private

    private var token: Any?

    private var maxAllowedSize: UInt32 {
        guard let maxSize = maxFileSize else {
            return 0
        }
        return UInt32(Double(maxSize) * (1.00 - 0.01)) // 1% of tolerance
    }

    private func makeAudioRecorder(
        audioFormatID: AudioFormatID,
        fileURL: URL
    ) -> AVAudioRecorder? {
        let settings = [
            AVFormatIDKey: audioFormatID,
            AVSampleRateKey: 32000,
            AVNumberOfChannelsKey: 1,
        ]

        do {
            let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder.isMeteringEnabled = true
            audioRecorder.delegate = self
            return audioRecorder
        } catch {
            WireLogger.ui.error("Failed to initialize `AVAudioRecorder`!")
            return nil
        }
    }

    private func setupDidEnterBackgroundObserver() {
        token = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main,
            using: { _ in
                self.stopRecording()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        )
    }
}

// MARK: AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        var recordedToMaxDuration = false
        let recordedToMaxSize = audioSizeIsCritical

        if let maxRecordingDuration {
            let duration = AVURLAsset(url: recorder.url).duration.seconds
            recordedToMaxDuration = duration >= maxRecordingDuration
        }

        // in the case that the recording finished due to the maxRecordingDuration
        // reached, we should still clean up afterwards
        if recordedToMaxDuration {
            _ = postRecordingProcessing()
        }

        if recordedToMaxSize {
            recordEndedCallback?(.failure(RecordingError.toMaxSize))
        } else if recordedToMaxDuration {
            recordEndedCallback?(.failure(RecordingError.toMaxDuration))
        } else {
            recordEndedCallback?(.success(()))
        }

        AVSMediaManager.sharedInstance().stopRecording()
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        WireLogger.ui.error("Cannot finish recording: \(String(describing: error))")
    }
}

// MARK: - AudioPlayerDelegate

final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    // MARK: Lifecycle

    init(playerDidFinishClosure: @escaping (Bool) -> Void) {
        self.playerDidFinishClosure = playerDidFinishClosure
        super.init()
    }

    // MARK: Internal

    let playerDidFinishClosure: (Bool) -> Void

    @objc
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerDidFinishClosure(flag)
    }
}

// MARK: - PowerProvider

protocol PowerProvider {
    func updateMeters() // call to refresh meter values
    func averagePower(forChannel channelNumber: Int) -> Float
}

let minimumPower: Float = -160

extension PowerProvider {
    func averagePowerForFirstActiveChannel() -> Float {
        for power in (0 ..< 3).map(averagePower) where power != minimumPower {
            return power
        }

        return minimumPower
    }
}

// MARK: - AVAudioPlayer + PowerProvider

extension AVAudioPlayer: PowerProvider {}

// MARK: - AVAudioRecorder + PowerProvider

extension AVAudioRecorder: PowerProvider {}
