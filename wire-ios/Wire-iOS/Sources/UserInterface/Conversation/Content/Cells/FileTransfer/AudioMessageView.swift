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
import UIKit
import WireCommonComponents
import WireDesign
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

// MARK: - AudioMessageView

final class AudioMessageView: UIView, TransferView {
    // MARK: Lifecycle

    init(mediaPlaybackManager: MediaPlaybackManager? = nil) {
        self.isPausedForIncomingCall = false
        self.mediaPlaybackManager = mediaPlaybackManager

        super.init(frame: .zero)
        backgroundColor = SemanticColors.View.backgroundCollectionCell

        playButton.addTarget(self, action: #selector(AudioMessageView.onActionButtonPressed(_:)), for: .touchUpInside)
        playButton.accessibilityIdentifier = "AudioActionButton"
        playButton.layer.masksToBounds = true

        downloadProgressView.isUserInteractionEnabled = false
        downloadProgressView.accessibilityIdentifier = "AudioProgressView"

        playerProgressView.setDeterministic(true, animated: false)
        playerProgressView.accessibilityIdentifier = "PlayerProgressView"

        loadingView.isHidden = true

        self.allViews = [
            playButton,
            timeLabel,
            downloadProgressView,
            playerProgressView,
            waveformProgressView,
            loadingView,
        ]
        allViews.forEach(addSubview)

        createConstraints()

        setNeedsLayout()
        layoutIfNeeded()

        if let session = ZMUserSession.shared() {
            self.callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: session)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias AudioMessage = L10n.Accessibility.AudioMessage

    var fileMessage: ZMConversationMessage?
    weak var delegate: TransferViewDelegate?
    let playButton: IconButton = {
        let button = IconButton()
        button.setIconColor(SemanticColors.Icon.foregroundDefaultWhite, for: .normal)
        return button
    }()

    var audioTrackPlayer: AudioTrackPlayer? {
        let mediaManager = mediaPlaybackManager ?? AppDelegate.shared.mediaPlaybackManager
        let audioTrackPlayer = mediaManager?.audioTrackPlayer
        audioTrackPlayer?.audioTrackPlayerDelegate = self
        return audioTrackPlayer
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    override var tintColor: UIColor! {
        didSet {
            downloadProgressView.tintColor = tintColor
        }
    }

    func configure(for message: ZMConversationMessage, isInitial: Bool) {
        fileMessage = message

        guard let fileMessageData = message.fileMessageData else {
            return
        }

        if isInitial {
            expectingDownload = false
        } else {
            if fileMessageData.downloadState == .downloaded, expectingDownload {
                playTrack()
                expectingDownload = false
            }
        }

        configureVisibleViews(forFileMessageData: fileMessageData, isInitial: isInitial)
        updateTimeLabel()

        if isOwnTrackPlayingInAudioPlayer() {
            updateActivePlayerProgressAnimated(false)
            updateActivePlayButton()
        } else {
            playerProgressView.setProgress(0, animated: false)
            waveformProgressView.setProgress(0, animated: false)
        }
        timeLabel.isAccessibilityElement = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playButton.layer.cornerRadius = playButton.bounds.size.width / 2.0
    }

    func proximityStateDidChange(_ raisedToEar: Bool) {
        setAudioOutput(earpiece: raisedToEar)
    }

    // MARK: Private

    private weak var mediaPlaybackManager: MediaPlaybackManager?

    private let downloadProgressView = CircularProgressView()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = (UIFont.smallSemiboldFont).monospaced()
        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 1
        label.textAlignment = .center
        label.accessibilityIdentifier = "AudioTimeLabel"

        return label
    }()

    private let playerProgressView = {
        let progressView = ZMProgressView()
        progressView.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        progressView.tintColor = .accent()
        return progressView
    }()

    private let waveformProgressView: WaveformProgressView = {
        let waveformProgressView = WaveformProgressView()
        waveformProgressView.backgroundColor = SemanticColors.View.backgroundCollectionCell

        return waveformProgressView
    }()

    private let loadingView = ThreeDotsLoadingView()

    private var allViews: [UIView] = []

    private var expectingDownload = false

    private var callStateObserverToken: Any?
    /// flag for resume audio player after incoming call
    private var isPausedForIncomingCall: Bool

    private var proximityMonitorManager: ProximityMonitorManager? {
        ZClientViewController.shared?.proximityMonitorManager
    }

    private func createConstraints() {
        [
            self,
            playButton,
            timeLabel,
            downloadProgressView,
            playerProgressView,
            waveformProgressView,
            loadingView,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),

            playButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 32),
            playButton.heightAnchor.constraint(equalTo: playButton.widthAnchor),

            timeLabel.leftAnchor.constraint(equalTo: playButton.rightAnchor, constant: 12),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),

            downloadProgressView.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            downloadProgressView.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            downloadProgressView.widthAnchor.constraint(equalTo: playButton.widthAnchor, constant: -2),
            downloadProgressView.heightAnchor.constraint(equalTo: playButton.heightAnchor, constant: -2),

            playerProgressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            playerProgressView.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 12),
            playerProgressView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
            playerProgressView.heightAnchor.constraint(equalToConstant: 1),

            waveformProgressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            waveformProgressView.leftAnchor.constraint(equalTo: playerProgressView.leftAnchor),
            waveformProgressView.rightAnchor.constraint(equalTo: playerProgressView.rightAnchor),
            waveformProgressView.heightAnchor.constraint(equalToConstant: 32),

            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func configureVisibleViews(forFileMessageData fileMessageData: ZMFileMessageData, isInitial: Bool) {
        guard let fileMessage,
              let state = FileMessageViewState.fromConversationMessage(fileMessage) else { return }

        var visibleViews = [playButton, timeLabel]

        if fileMessageData.normalizedLoudness?.isEmpty == false {
            waveformProgressView.samples = fileMessageData.normalizedLoudness ?? []
            if let accentColor = fileMessage.senderUser?.accentColor {
                waveformProgressView.barColor = accentColor
                waveformProgressView.highlightedBarColor = UIColor.gray
            }
            visibleViews.append(waveformProgressView)
        } else {
            visibleViews.append(playerProgressView)
        }

        switch state {
        case .obfuscated: visibleViews = []

        case .unavailable: visibleViews = [loadingView]

        case .downloading, .uploading:
            visibleViews.append(downloadProgressView)
            downloadProgressView.setProgress(fileMessageData.progress, animated: !isInitial)

        default:
            break
        }

        if let viewsState = state.viewsStateForAudio() {
            playButton.setIcon(viewsState.playButtonIcon, size: .tiny, for: .normal)
            playButton.setBackgroundImageColor(viewsState.playButtonBackgroundColor, for: .normal)
            playButton.accessibilityValue = viewsState.playButtonIcon == .play ? AudioMessage.Play.value : AudioMessage
                .Pause.value
        }

        updateVisibleViews(allViews, visibleViews: visibleViews, animated: !loadingView.isHidden)
    }

    private func updateTimeLabel() {
        var duration: Int? = .none

        if isOwnTrackPlayingInAudioPlayer() {
            if let audioTrackPlayer {
                duration = Int(audioTrackPlayer.elapsedTime)
            }
        } else {
            guard let message = fileMessage,
                  let fileMessageData = message.fileMessageData else {
                return
            }
            if fileMessageData.durationMilliseconds != 0 {
                duration = Int(roundf(Float(fileMessageData.durationMilliseconds) / 1000.0))
            }
        }

        if let durationUnboxed = duration {
            let (seconds, minutes) = (durationUnboxed % 60, durationUnboxed / 60)
            let time = String(format: "%d:%02d", minutes, seconds)
            timeLabel.text = time
        } else {
            timeLabel.text = ""
        }
        timeLabel.accessibilityValue = timeLabel.text
    }

    private func updateActivePlayButton() {
        guard let audioTrackPlayer else { return }

        playButton.backgroundColor = SemanticColors.Icon.backgroundDefault

        if audioTrackPlayer.isPlaying {
            playButton.setIcon(.pause, size: .tiny, for: [])
            playButton.accessibilityValue = AudioMessage.Pause.value
        } else {
            playButton.setIcon(.play, size: .tiny, for: [])
            playButton.accessibilityValue = AudioMessage.Play.value
        }
    }

    private func updateInactivePlayer() {
        playButton.setIcon(.play, size: .tiny, for: [])
        playButton.accessibilityValue = AudioMessage.Play.value

        playerProgressView.setProgress(0, animated: false)
        waveformProgressView.setProgress(0, animated: false)
    }

    private func updateActivePlayerProgressAnimated(_ animated: Bool) {
        guard let audioTrackPlayer else { return }

        let progress: Float
        var animated = animated

        if abs(1 - audioTrackPlayer.progress) < 0.01 {
            progress = 0
            animated = false
        } else {
            progress = Float(audioTrackPlayer.progress)
        }

        playerProgressView.setProgress(progress, animated: animated)
        waveformProgressView.setProgress(progress, animated: animated)
    }

    private func playTrack() {
        let userSession = ZMUserSession.shared()
        guard let fileMessage,
              let fileMessageData = fileMessage.fileMessageData,
              let audioTrackPlayer,
              userSession == nil || userSession!.isCallOngoing == false else {
            return
        }

        proximityMonitorManager?.stateChanged = proximityStateDidChange

        let audioTrackPlayingSame = audioTrackPlayer.sourceMessage?.isEqual(fileMessage) ?? false

        // first play
        if let track = fileMessage.audioTrack, !audioTrackPlayingSame {
            audioTrackPlayer.load(track, sourceMessage: fileMessage) { [weak self] success, error in
                if success {
                    self?.setAudioOutput(earpiece: false)
                    audioTrackPlayer.play()

                    let duration = TimeInterval(Float(fileMessageData.durationMilliseconds) / 1000.0)
                    let earliestEndDate = Date(timeIntervalSinceNow: duration)
                    self?.extendEphemeralTimerIfNeeded(to: earliestEndDate)
                } else {
                    zmLog.warn("Cannot load track \(track): \(String(describing: error))")
                }
            }
        } else {
            // pausing and restarting
            if audioTrackPlayer.isPlaying {
                audioTrackPlayer.pause()
            } else {
                audioTrackPlayer.play()
            }
        }
    }

    /// Extend the ephemeral timer to the given date iff the audio message
    /// is ephemeral and it would exceed its destruction date.
    private func extendEphemeralTimerIfNeeded(to endDate: Date) {
        guard let destructionDate = fileMessage?.destructionDate,
              endDate > destructionDate,
              let assetMsg = fileMessage as? ZMAssetClientMessage
        else { return }

        assetMsg.extendDestructionTimer(to: endDate)
    }

    /// Check if the audioTrackPlayer is playing my track
    ///
    /// - Returns: true if audioTrackPlayer is playing the audio of this view (not other instance of AudioMessgeView or
    /// other audio playing object)
    private func isOwnTrackPlayingInAudioPlayer() -> Bool {
        guard let message = fileMessage,
              let audioTrack = message.audioTrack,
              let audioTrackPlayer
        else {
            return false
        }

        let audioTrackPlayingSame = audioTrackPlayer.sourceMessage?.isEqual(fileMessage) ?? false
        return audioTrackPlayingSame && (audioTrackPlayer.audioTrack?.isEqual(audioTrack) ?? false)
    }

    // MARK: - Actions

    @objc
    private func onActionButtonPressed(_: UIButton) {
        isPausedForIncomingCall = false

        guard
            let fileMessage,
            let fileMessageData = fileMessage.fileMessageData
        else {
            return
        }

        switch fileMessageData.transferState {
        case .uploading:
            guard fileMessageData.hasLocalFileData else { return }
            delegate?.transferView(self, didSelect: .cancel)

        case .uploadingCancelled, .uploadingFailed:
            guard fileMessageData.hasLocalFileData else { return }
            delegate?.transferView(self, didSelect: .resend)

        case .uploaded:
            switch fileMessageData.downloadState {
            case .remote:
                expectingDownload = true
                ZMUserSession.shared()?.enqueue(fileMessageData.requestFileDownload)

            case .downloaded:
                playTrack()

            case .downloading:
                downloadProgressView.setProgress(0, animated: false)
                delegate?.transferView(self, didSelect: .cancel)
            }
        }
    }

    // MARK: - Audio state observer

    private func audioProgressChanged() {
        DispatchQueue.main.async {
            if self.isOwnTrackPlayingInAudioPlayer() {
                self.updateActivePlayerProgressAnimated(false)
                self.updateTimeLabel()
            }
        }
    }

    private func updateUI(state: MediaPlayerState?) {
        if isOwnTrackPlayingInAudioPlayer() {
            updateActivePlayerProgressAnimated(false)
            updateActivePlayButton()
            updateTimeLabel()
            updateProximityObserverState()
        }
        // When state is completed, there is no info about it is own track or not. Update the time label in this case
        // anyway (set to the length of own audio track)
        else if state == .completed {
            updateTimeLabel()
        } else {
            updateInactivePlayer()
        }
    }

    // MARK: - Proximity Listener

    private func updateProximityObserverState() {
        guard let audioTrackPlayer, isOwnTrackPlayingInAudioPlayer() else { return }

        if audioTrackPlayer.isPlaying {
            proximityMonitorManager?.startListening()
        } else {
            proximityMonitorManager?.stopListening()
        }
    }

    private func setAudioOutput(earpiece: Bool) {
        do {
            if earpiece {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                AVSMediaManager.sharedInstance().playbackRoute = .builtIn
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                AVSMediaManager.sharedInstance().playbackRoute = .speaker
            }
        } catch {
            zmLog.error("Cannot set AVAudioSession category: \(error)")
        }
    }
}

// MARK: WireCallCenterCallStateObserver

extension AudioMessageView: WireCallCenterCallStateObserver {
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        guard let player = audioTrackPlayer else { return }
        guard isOwnTrackPlayingInAudioPlayer() else { return }

        // Pause the audio player when call is incoming to prevent the audio player is reset.
        // Resume playing when the call is terminating (and the audio is paused by this method)
        switch (previousCallState, callState) {
        case (_, .incoming):
            if player.isPlaying {
                player.pause()
                isPausedForIncomingCall = true
            }

        case (.incoming?, .terminating):
            if isPausedForIncomingCall, !player.isPlaying {
                player.play()
            }
            isPausedForIncomingCall = false

        default:
            break
        }
    }
}

// MARK: AudioTrackPlayerDelegate

extension AudioMessageView: AudioTrackPlayerDelegate {
    func progressDidChange(_ audioTrackPlayer: AudioTrackPlayer, progress: Double) {
        audioProgressChanged()
    }

    func stateDidChange(_ audioTrackPlayer: AudioTrackPlayer, state: MediaPlayerState?) {
        // Updates the visual progress of the audio, play button icon image, time label and proximity sensor's sate.
        // Notice: when there are more then 1 instance of this class exists, this function will be called in every instance.
        // This function may called from background thread (in case incoming call).
        DispatchQueue.main.async { [weak self] in
            self?.updateUI(state: state)
        }
    }
}
