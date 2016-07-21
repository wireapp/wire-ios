// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import CocoaLumberjackSwift

public enum PlayingState: UInt, CustomStringConvertible {
    case Idle, Playing
    
    public var description: String {
        switch self {
        case .Idle: return "idle"
        case .Playing: return "playing"
        }
    }
}

public typealias RecordingLevel = Float

public enum AudioRecorderFormat {
    case M4A, WAV
    func fileExtension() -> String {
        switch self {
        case .M4A:
            return "m4a"
        case .WAV:
            return "wav"
        }
    }
    
    func audioFormat() -> AudioFormatID {
        switch self {
        case .M4A:
            return kAudioFormatMPEG4AAC
        case .WAV:
            return kAudioFormatLinearPCM
        }
    }
}

public enum AudioRecorderState {
    case Recording, Playback
}

public protocol AudioRecorderType: class {
    var format: AudioRecorderFormat { get }
    var state: AudioRecorderState { get set }
    var fileURL: NSURL? { get }
    var maxRecordingDuration: NSTimeInterval? { get set }
    var currentDuration: NSTimeInterval { get }
    var recordTimerCallback: (NSTimeInterval -> Void)? { get set }
    var recordLevelCallBack: (RecordingLevel -> Void)? { get set }
    var playingStateCallback: (PlayingState -> Void)? { get set }
    var recordStartedCallback: (Void -> Void)? { get set }
    var recordEndedCallback: (Bool -> Void)? { get set } // recordedToMaxDuration: Bool
    
    func startRecording()
    func stopRecording() -> Bool
    func deleteRecording()
    func playRecording()
    func stopPlaying()
    func levelForCurrentState() -> RecordingLevel
    func durationForCurrentState() -> NSTimeInterval?
}

public final class AudioRecorder: NSObject, AudioRecorderType {
    
    public let format: AudioRecorderFormat
    public var state: AudioRecorderState = .Recording
    
    lazy var audioRecorder : AVAudioRecorder? = { [weak self] in
        guard let `self` = self else { return nil }
        let fileName = NSString.filenameForSelfUser().stringByAppendingPathExtension(self.format.fileExtension())!
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
        let audioRecorder = try? AVAudioRecorder(URL: fileURL, settings: [AVFormatIDKey : NSNumber(unsignedInt: self.format.audioFormat())])
        audioRecorder?.meteringEnabled = true
        audioRecorder?.delegate = self
        return audioRecorder
    }()
    
    var displayLink: CADisplayLink?
    var audioPlayer : AVAudioPlayer?
    var audioPlayerDelegate: AudioPlayerDelegate?
    public var maxRecordingDuration: NSTimeInterval? = .None
    let fm = NSFileManager.defaultManager()
    public var currentDuration: NSTimeInterval = 0
    public var recordTimerCallback: (NSTimeInterval -> Void)?
    public var recordLevelCallBack: (RecordingLevel -> Void)?
    public var playingStateCallback: (PlayingState -> Void)?
    public var recordStartedCallback: (Void -> Void)?
    public var recordEndedCallback: (Bool -> Void)? // recordedToMaxDuration: Bool
    public var fileURL: NSURL?
    
    override init() {
        fatalError("init() is not implemented for AudioRecorder")
    }
    
    init?(format: AudioRecorderFormat = .M4A, maxRecordingDuration: NSTimeInterval?) {
        self.maxRecordingDuration = maxRecordingDuration
        self.format = format
        super.init()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        removeDisplayLink()
    }
    
    // MARK: Recording
    
    public func startRecording() {
        guard let audioRecorder = self.audioRecorder else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error {
            DDLogError("Failed change audio category for recording: \(error)")
        }
        
        state = .Recording
        recordTimerCallback?(0)
        fileURL = nil
        setupDisplayLink()
        if let maxDuration = self.maxRecordingDuration {
            if !audioRecorder.recordForDuration(maxDuration) {
                DDLogError("Failed to start audio recording")
            }
            else {
                self.recordStartedCallback?()
            }
        }
        else {
            if !audioRecorder.record() { // 25 minutes max recording
                DDLogError("Failed to start audio recording")
            }
        }
    }
    
    public func stopRecording() -> Bool {
        audioRecorder?.stop()
        recordLevelCallBack?(0)
        removeDisplayLink()
        guard let filePath = audioRecorder?.url.path where fm.fileExistsAtPath(filePath) else { return false }
        fileURL = audioRecorder?.url
        return true
    }
    
    public func deleteRecording() {
        currentDuration = 0
        if let filePath = audioRecorder?.url.path where NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            audioRecorder?.deleteRecording()
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    private func removeDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkDidFire() {
        recordLevelCallBack?(levelForCurrentState())
        guard let duration = durationForCurrentState() where currentDuration != duration else { return }
        currentDuration = duration
        recordTimerCallback?(currentDuration)
    }
    
    // MARK: Playing
    
    public func playRecording() {
        guard let audioRecorder = self.audioRecorder else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch let error {
            DDLogError("Failed change audio category for playback: \(error)")
        }
        
        state = .Playback
        setupDisplayLink()
        audioPlayer = try? AVAudioPlayer(contentsOfURL: audioRecorder.url)
        audioPlayer?.meteringEnabled = true
        
        audioPlayerDelegate = AudioPlayerDelegate { [weak self] _ in
            guard let `self` = self else { return }
            self.removeDisplayLink()
            self.playingStateCallback?(.Idle)
            self.recordLevelCallBack?(0)
            guard let duration = self.audioPlayer?.duration else { return }
            self.recordTimerCallback?(duration)
        }
        
        audioPlayer?.delegate = audioPlayerDelegate
        audioPlayer?.play()
        playingStateCallback?(.Playing)
    }
    
    public func stopPlaying() {
        recordLevelCallBack?(0)
        removeDisplayLink()
        audioPlayer?.pause()
        playingStateCallback?(.Idle)
    }
    
    // MARK: Leveling & Duration
    
    public func levelForCurrentState() -> RecordingLevel {
        let powerProvider: PowerProvider? = state == .Recording ? audioRecorder : audioPlayer
        powerProvider?.updateMeters()
        let level = powerProvider?.averagePowerForFirstActiveChannel() ?? minimumPower
        // This value is in dB (logarithmic, [-160, 0]) and varies between -160 and 0 so we need to normalize it, see
        // https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioRecorder_ClassReference/#//apple_ref/occ/instm/AVAudioRecorder/peakPowerForChannel:
        return level.normalizedDecibelValue()
    }
    
    public func durationForCurrentState() -> NSTimeInterval? {
        if case .Recording = state {
            return audioRecorder?.currentTime
        } else {
            return audioPlayer?.currentTime ?? audioRecorder?.currentTime
        }
    }
    
}


extension AudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        let recordedToMaxDuration: Bool
        if let maxRecordingDuration = self.maxRecordingDuration {
            recordedToMaxDuration = currentDuration >= maxRecordingDuration
        }
        else {
            recordedToMaxDuration = false
        }
        
        self.recordEndedCallback?(recordedToMaxDuration)
    }
    
    public func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        DDLogError("Cannot finish recording: \(error)")
    }
}

// MARK: AVAvdioPlayerDelegate

final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    
    let playerDidFinishClosure: Bool -> Void
    
    init(playerDidFinishClosure: Bool -> Void) {
        self.playerDidFinishClosure = playerDidFinishClosure
        super.init()
    }
    
    @objc func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        playerDidFinishClosure(flag)
    }
}



// MARK: Power Provider

protocol PowerProvider {
    func updateMeters() /* call to refresh meter values */
    func averagePowerForChannel(channelNumber: Int) -> Float
}

let minimumPower: Float = -160

extension PowerProvider {
    
    func averagePowerForFirstActiveChannel() -> Float {
        for power in (0..<3).map(averagePowerForChannel) where power != minimumPower {
            return power
        }
        
        return minimumPower
    }
}

extension AVAudioPlayer: PowerProvider {}
extension AVAudioRecorder: PowerProvider {}
