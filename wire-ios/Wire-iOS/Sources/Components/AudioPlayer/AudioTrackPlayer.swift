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

import Foundation
import MediaPlayer
import WireSyncEngine

// MARK: - MediaPlayerState

/// These enums represent the state of the current media in the player.

enum MediaPlayerState: Int {
    case ready = 0
    case playing
    case paused
    case completed
    case error
}

// MARK: - MediaPlayer

protocol MediaPlayer: AnyObject {
    var title: String? { get }
    var sourceMessage: ZMConversationMessage? { get }
    var state: MediaPlayerState? { get }
    func play()
    func pause()
    func stop()
}

typealias AudioTrackCompletionHandler = (_ loaded: Bool, _ error: Error?) -> Void

// MARK: - AudioTrackPlayerDelegate

protocol AudioTrackPlayerDelegate: AnyObject {
    func stateDidChange(_ audioTrackPlayer: AudioTrackPlayer, state: MediaPlayerState?)
    func progressDidChange(_ audioTrackPlayer: AudioTrackPlayer, progress: Double)
}

// MARK: - AudioTrackPlayer

final class AudioTrackPlayer: NSObject, MediaPlayer {
    // MARK: Lifecycle

    init(userSession: UserSession) {
        self.userSession = userSession
        super.init()
    }

    deinit {
        setIsRemoteCommandCenterEnabled(false)
    }

    // MARK: Internal

    private(set) var playing = false

    weak var audioTrackPlayerDelegate: AudioTrackPlayerDelegate?
    weak var mediaPlayerDelegate: MediaPlayerDelegate?

    var sourceMessage: ZMConversationMessage?
    private(set) var audioTrack: AudioTrack?

    var state: MediaPlayerState? {
        didSet {
            audioTrackPlayerDelegate?.stateDidChange(self, state: state)
            if let state {
                mediaPlayerDelegate?.mediaPlayer(self, didChangeTo: state)
            }
        }
    }

    private(set) var progress: Double = 0 {
        didSet {
            audioTrackPlayerDelegate?.progressDidChange(self, progress: progress)
        }
    }

    var duration: Double {
        if let duration = avPlayer?.currentItem?.asset.duration {
            return CMTimeGetSeconds(duration)
        }
        return 0
    }

    var elapsedTime: TimeInterval {
        guard let time = avPlayer?.currentTime() else { return 0 }

        if CMTIME_IS_VALID(time) {
            return TimeInterval(time.value) / TimeInterval(time.timescale)
        }

        return 0
    }

    var isPlaying: Bool {
        if let avPlayer, avPlayer.rate > 0, avPlayer.error == nil {
            return true
        }

        return false
    }

    var title: String? {
        audioTrack?.title
    }

    /// Start the currently loaded/paused track.
    func play() {
        if state == .completed {
            avPlayer?.seek(to: CMTimeMake(value: 0, timescale: 1))
        }

        avPlayer?.play()
    }

    /// Pause the currently playing track.
    func pause() {
        avPlayer?.pause()
    }

    func load(
        _ track: AudioTrack,
        sourceMessage: ZMConversationMessage,
        completionHandler: AudioTrackCompletionHandler? = nil
    ) {
        progress = 0
        audioTrack = track
        self.sourceMessage = sourceMessage
        loadAudioTrackCompletionHandler = completionHandler

        if let streamURL = track.streamURL {
            if let avPlayer {
                avPlayer.replaceCurrentItem(with: AVPlayerItem(url: streamURL))

                if avPlayer.status == .readyToPlay {
                    loadAudioTrackCompletionHandler?(true, nil)
                }
            } else {
                avPlayer = AVPlayer(url: streamURL)

                playerStatusObserver = avPlayer?.observe(\AVPlayer.status, options: [.new]) { [weak self] _, _ in
                    self?.playStatusChanged()
                }

                playerRateObserver = avPlayer?.observe(\AVPlayer.rate, options: [.new]) { [weak self] _, _ in
                    self?.playRateChanged()
                }

                playerCurrentItemObserver = avPlayer?.observe(\AVPlayer.currentItem, options: [
                    .new,
                    .initial,
                    .old,
                ]) { [weak self] _, _ in
                    self?.playCurrentItemChanged()
                }
            }
        } else {
            // For testing only! streamURL is nil in tests.
            avPlayer = AVPlayer()
        }

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidPlay(toEndTime:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer?.currentItem
        )

        if let timeObserverToken {
            avPlayer?.removeTimeObserver(timeObserverToken)
        }

        timeObserverToken = avPlayer?.addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1, timescale: 60),
            queue: DispatchQueue.main,
            using: { [weak self] time in
                guard let self, let duration = avPlayer?.currentItem?.asset.duration else { return }

                let itemRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: duration)

                let normalizedRange = CMTimeRangeMake(
                    start: CMTimeMake(value: 0, timescale: 1),
                    duration: CMTimeMake(value: 1, timescale: 1)
                )

                let normalizedTime = CMTimeMapTimeFromRangeToRange(time, fromRange: itemRange, toRange: normalizedRange)

                progress = CMTimeGetSeconds(normalizedTime)
            }
        )

        messageObserverToken = userSession.addMessageObserver(
            self,
            for: sourceMessage
        )
    }

    func setIsRemoteCommandCenterEnabled(_ enabled: Bool) {
        let commandCenter = MPRemoteCommandCenter.shared()

        if !enabled {
            commandCenter.playCommand.removeTarget(playHandler)
            commandCenter.pauseCommand.removeTarget(pauseHandler)
            commandCenter.nextTrackCommand.removeTarget(nextTrackHandler)
            commandCenter.previousTrackCommand.removeTarget(previousTrackHandler)
            return
        }

        pauseHandler = commandCenter.pauseCommand.addTarget(handler: { [weak self] _ in
            if let avPlayer = self?.avPlayer, avPlayer.rate > 0 {
                self?.pause()
                return .success
            } else {
                return .commandFailed
            }
        })

        playHandler = commandCenter.playCommand.addTarget(handler: { [weak self] _ in
            if self?.audioTrack == nil {
                return .noSuchContent
            }

            if self?.avPlayer?.rate == 0 {
                self?.play()
                return .success
            } else {
                return .commandFailed
            }
        })
    }

    func stop() {
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        audioTrack = nil
        messageObserverToken = nil
        sourceMessage = nil
    }

    // MARK: - MPNowPlayingInfoCenter

    func populateNowPlayingState() {
        let playbackDuration: NSNumber = if let duration: CMTime = avPlayer?.currentItem?.asset.duration {
            NSNumber(value: CMTimeGetSeconds(duration))
        } else {
            0
        }

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: audioTrack?.title ?? "",
            MPMediaItemPropertyArtist: audioTrack?.author ?? "",
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: avPlayer?.rate ?? 0),
            MPMediaItemPropertyPlaybackDuration: playbackDuration,
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: Private

    private let userSession: UserSession

    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var messageObserverToken: NSObjectProtocol?
    private var loadAudioTrackCompletionHandler: AudioTrackCompletionHandler?

    private var nowPlayingInfo: [String: Any]?
    private var playHandler: Any?
    private var pauseHandler: Any?
    private var nextTrackHandler: Any?
    private var previousTrackHandler: Any?

    private var playerStatusObserver: NSKeyValueObservation?
    private var playerRateObserver: NSKeyValueObservation?
    private var playerCurrentItemObserver: NSKeyValueObservation?

    private func playRateChanged() {
        if let avPlayer, avPlayer.rate > 0 {
            state = .playing
        } else {
            state = .paused
        }

        updateNowPlayingState()
    }

    private func playCurrentItemChanged() {
        if avPlayer?.currentItem == nil {
            setIsRemoteCommandCenterEnabled(false)
            clearNowPlayingState()
            state = .completed
        } else {
            setIsRemoteCommandCenterEnabled(true)
            populateNowPlayingState()
        }
    }

    private func playStatusChanged() {
        if avPlayer?.currentItem?.status == .failed {
            audioTrack?.failedToLoad = true
            state = .error
        }

        guard let status = avPlayer?.status else { return }

        switch status {
        case .readyToPlay:
            loadAudioTrackCompletionHandler?(true, nil)
        case .failed:
            loadAudioTrackCompletionHandler?(false, avPlayer?.error)
        default:
            break
        }
    }

    // MARK: - MPNowPlayingInfoCenter

    private func clearNowPlayingState() {
        let info = MPNowPlayingInfoCenter.default()
        info.nowPlayingInfo = nil
        nowPlayingInfo = nil
    }

    private func updateNowPlayingState() {
        var newInfo = nowPlayingInfo
        newInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: elapsedTime)
        if let rate = avPlayer?.rate {
            newInfo?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
        }

        let info = MPNowPlayingInfoCenter.default()
        info.nowPlayingInfo = newInfo
        nowPlayingInfo = newInfo
    }

    // MARK: AVPlayer notifications

    @objc
    private func itemDidPlay(toEndTime notification: Notification?) {
        // AUDIO-557 workaround for AVSMediaManager trying to pause already paused tracks.
        delay(0.1) { [weak self] in
            guard let self else { return }

            clearNowPlayingState()
            state = .completed
        }
    }
}

// MARK: ZMMessageObserver

extension AudioTrackPlayer: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        if changeInfo.message.hasBeenDeleted {
            stop()
        }
    }
}
