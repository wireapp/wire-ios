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

import UIKit
import WireCommonComponents
import WireDesign

final class AudioButtonOverlay: UIView {
    // MARK: Lifecycle

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        configureViews()
        createConstraints()
        updateWithRecordingState(recordingState)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - AudioButtonOverlayButtonType

    enum AudioButtonOverlayButtonType {
        case play, send, stop
    }

    // MARK: - Properties

    typealias ButtonPressHandler = (AudioButtonOverlayButtonType) -> Void
    typealias ViewColors = SemanticColors.View

    let darkColor = SemanticColors.Icon.foregroundAudio
    let brightColor = ViewColors.backgroundAudioViewOverlay
    let greenColor = SemanticColors.Button.backgroundAudioMessageOverlay
    let grayColor = ViewColors.backgroundAudioViewOverlayActive
    let superviewColor = ViewColors.backgroundAudioViewOverlay

    let audioButton = IconButton()
    let playButton = IconButton()
    let sendButton = IconButton()
    let backgroundView = UIView()
    var buttonHandler: ButtonPressHandler?

    var recordingState: AudioRecordState = .recording {
        didSet { updateWithRecordingState(recordingState) }
    }

    var playingState: PlayingState = .idle {
        didSet { updateWithPlayingState(playingState) }
    }

    // MARK: - Override Methods

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = bounds.width / 2
    }

    // MARK: - Setup UI and Constraints

    func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        audioButton.isUserInteractionEnabled = false
        audioButton.setIcon(.microphone, size: .tiny, for: [])
        audioButton.accessibilityIdentifier = "audioRecorderRecord"

        playButton.setIcon(.play, size: .tiny, for: [])
        playButton.accessibilityIdentifier = "audioRecorderPlay"
        playButton.accessibilityValue = PlayingState.idle.description

        sendButton.setIcon(.checkmark, size: .tiny, for: [])
        sendButton.accessibilityIdentifier = "audioRecorderSend"

        [backgroundView, audioButton, sendButton, playButton].forEach(addSubview)

        playButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    // MARK: - Methods

    func setOverlayState(_ state: AudioButtonOverlayState) {
        defer { layoutIfNeeded() }
        heightConstraint.constant = state.height
        widthConstraint.constant = state.width
        alpha = state.alpha

        let blendedGray = grayColor.removeAlphaByBlending(with: superviewColor)
        sendButton.setIconColor(state.colorWithColors(greenColor, highlightedColor: brightColor), for: [])
        backgroundView.backgroundColor = state.colorWithColors(blendedGray, highlightedColor: greenColor)
        audioButton.setIconColor(state.colorWithColors(darkColor, highlightedColor: brightColor), for: [])
        playButton.setIconColor(darkColor, for: [])
    }

    func updateWithRecordingState(_ state: AudioRecordState) {
        audioButton.isHidden = state == .finishedRecording
        playButton.isHidden = state == .recording
        sendButton.isHidden = false
        backgroundView.isHidden = false
    }

    func updateWithPlayingState(_ state: PlayingState) {
        let icon: StyleKitIcon = state == .idle ? .play : .stopRecording
        playButton.setIcon(icon, size: .tiny, for: [])
        playButton.accessibilityValue = state.description
    }

    // MARK: - Actions

    @objc
    func buttonPressed(_ sender: IconButton) {
        let type: AudioButtonOverlayButtonType = if sender == sendButton {
            .send
        } else {
            playingState == .idle ? .play : .stop
        }

        buttonHandler?(type)
    }

    // MARK: Fileprivate

    fileprivate lazy var heightConstraint: NSLayoutConstraint = heightAnchor.constraint(equalToConstant: 96)
    fileprivate lazy var widthConstraint: NSLayoutConstraint = widthAnchor.constraint(equalToConstant: initialViewWidth)

    // MARK: Private

    private let initialViewWidth: CGFloat = 40

    private func createConstraints() {
        for item in [audioButton, playButton, sendButton, backgroundView] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            audioButton.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -initialViewWidth / 2),
            audioButton.centerXAnchor.constraint(equalTo: centerXAnchor),

            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -initialViewWidth / 2),

            sendButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            sendButton.centerYAnchor.constraint(equalTo: topAnchor, constant: initialViewWidth / 2),

            widthConstraint,
            heightConstraint,
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leftAnchor.constraint(equalTo: leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}
