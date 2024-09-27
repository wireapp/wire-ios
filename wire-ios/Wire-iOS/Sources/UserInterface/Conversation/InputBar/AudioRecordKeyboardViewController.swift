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
import WireSystem

private let zmLog = ZMSLog(tag: "UI")

final class AudioRecordKeyboardViewController: UIViewController, AudioRecordBaseViewController {
    enum State {
        case ready, recording, effects
    }

    // MARK: - Properties

    private(set) var state: State = .ready {
        didSet { if oldValue != state { updateRecordingState(state) }}
    }

    var isRecording: Bool {
        switch recorder.state {
        case .recording:
            true
        default:
            false
        }
    }

    let recorder: AudioRecorderType
    weak var delegate: AudioRecordViewControllerDelegate?

    let recordButton = IconButton()
    let stopRecordButton = IconButton()
    let confirmButton = IconButton()
    let redoButton = IconButton()
    let cancelButton = IconButton()

    private let topContainer = UIView()
    private let topSeparator = UIView()
    private let bottomToolbar = UIView()

    private let tipLabel = UILabel()
    private let timeLabel = UILabel()
    private let audioPreviewView = WaveFormView()
    private var recordTapGestureRecognizer: UITapGestureRecognizer!

    private var accentColorChangeHandler: AccentColorChangeHandler?
    private var effectPickerViewController: AudioEffectsPickerViewController?

    private var currentEffect: AVSAudioEffectType = .none
    private var currentEffectFilePath: String?

    private let userSession: UserSession

    private var isAppLockActive: Bool {
        userSession.isAppLockActive
    }

    // MARK: - Life Cycle

    convenience init(userSession: UserSession) {
        self.init(
            audioRecorder: AudioRecorder(
                format: .wav,
                maxRecordingDuration: userSession.maxAudioMessageLength,
                maxFileSize: userSession.maxUploadFileSize
            ),
            userSession: userSession
        )
    }

    init(audioRecorder: AudioRecorderType, userSession: UserSession) {
        self.recorder = audioRecorder
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
        configureViews(userSession: userSession)
        configureAudioRecorder()
        createConstraints()

        if Bundle.developerModeEnabled, Settings.shared.maxRecordingDurationDebug != 0 {
            recorder.maxRecordingDuration = Settings.shared.maxRecordingDurationDebug
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        UIAccessibility.post(notification: .layoutChanged, argument: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recorder.stopRecording()
        if isAppLockActive { AppDelegate.shared.mainWindow?.endEditing(true) }
    }

    // MARK: - View Configuration

    func configureViews(userSession: UserSession) {
        let backgroundColor = SemanticColors.View.backgroundDefault
        let textColor = SemanticColors.Label.textDefault
        let separatorColor = SemanticColors.View.backgroundSeparatorCell

        view.backgroundColor = backgroundColor

        recordTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordButtonPressed))
        view.addGestureRecognizer(recordTapGestureRecognizer)

        audioPreviewView.gradientWidth = 20
        audioPreviewView.gradientColor = backgroundColor

        accentColorChangeHandler = AccentColorChangeHandler
            .addObserver(self, userSession: userSession) { [unowned self] color, _ in
                if let color {
                    audioPreviewView.color = color
                }
            }

        timeLabel.font = FontSpec(.small, .light).font!
        timeLabel.textColor = textColor
        timeLabel.accessibilityLabel = "recordingTime"

        createTipLabel()

        [audioPreviewView, timeLabel, tipLabel].forEach(topContainer.addSubview)

        createButtons()

        [
            recordButton,
            stopRecordButton,
            confirmButton,
            redoButton,
            cancelButton,
        ].forEach(bottomToolbar.addSubview)

        topSeparator.backgroundColor = separatorColor

        [bottomToolbar, topContainer, topSeparator].forEach(view.addSubview)
        updateRecordingState(state)
    }

    private func createTipLabel() {
        let color = SemanticColors.Label.textDefault

        let recordingHintText = L10n.Localizable.Conversation.InputBar.AudioMessage.Keyboard.recordTip("%@")

        let effects = AVSAudioEffectType.displayedEffects.filter { $0 != .none }
        let randomIndex = Int.random(in: 0 ..< effects.count)
        let effect = effects[randomIndex]
        let image = effect.icon.makeImage(size: 14, color: color)

        let attachment = NSTextAttachment()
        attachment.image = image

        let imageAttrString = NSAttributedString(attachment: attachment)

        let attrText = NSMutableAttributedString(string: recordingHintText)
        let atRange = (recordingHintText as NSString).range(of: "%@")
        if atRange.location != NSNotFound {
            attrText.replaceCharacters(in: atRange, with: imageAttrString)
        }

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8

        attrText.addAttribute(
            .paragraphStyle,
            value: style,
            range: NSRange(location: 0, length: attrText.length)
        )

        tipLabel.attributedText = attrText
        tipLabel.numberOfLines = 2
        tipLabel.font = FontSpec(.small, .light).font!
        tipLabel.textColor = color
        tipLabel.textAlignment = .center
        tipLabel.isAccessibilityElement = false
    }

    private func createButtons() {
        recordButton.setIcon(.recordDot, size: .tiny, for: [])
        recordButton.setIconColor(.white, for: [])
        recordButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
        recordButton.setBackgroundImageColor(SemanticColors.Icon.foregroundDefaultRed, for: .normal)
        recordButton.layer.masksToBounds = true

        stopRecordButton.setIcon(.stopRecording, size: .tiny, for: [])
        stopRecordButton.setIconColor(.white, for: [])
        stopRecordButton.addTarget(self, action: #selector(stopRecordButtonPressed), for: .touchUpInside)
        stopRecordButton.setBackgroundImageColor(SemanticColors.Icon.foregroundDefaultRed, for: .normal)
        stopRecordButton.layer.masksToBounds = true

        confirmButton.setIcon(.checkmark, size: .tiny, for: [])
        confirmButton.setIconColor(.white, for: [])
        confirmButton.addTarget(self, action: #selector(confirmButtonPressed), for: .touchUpInside)
        confirmButton.setBackgroundImageColor(
            SemanticColors.Button.backgroundconfirmSendingAudioMessage,
            for: .normal
        )
        confirmButton.layer.masksToBounds = true

        redoButton.setIcon(.undo, size: .tiny, for: [])
        redoButton.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: [])
        redoButton.addTarget(self, action: #selector(redoButtonPressed), for: .touchUpInside)

        cancelButton.setIcon(.cross, size: .tiny, for: [])
        cancelButton.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: [])
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)

        setupAccessibility()
    }

    private func setupAccessibility() {
        typealias AudioRecord = L10n.Accessibility.AudioRecord

        recordButton.accessibilityLabel = AudioRecord.StartButton.description
        stopRecordButton.accessibilityLabel = AudioRecord.StopButton.description
        confirmButton.accessibilityLabel = AudioRecord.SendButton.description
        redoButton.accessibilityLabel = AudioRecord.RedoButton.description
        cancelButton.accessibilityLabel = AudioRecord.CancelButton.description
    }

    private func createConstraints() {
        [
            audioPreviewView,
            timeLabel,
            tipLabel,
            recordButton,
            stopRecordButton,
            confirmButton,
            redoButton,
            cancelButton,
            bottomToolbar,
            topContainer,
            topSeparator,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            topContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            topContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            topContainer.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            topContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            topContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bottomToolbar.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomToolbar.leftAnchor.constraint(equalTo: topContainer.leftAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            bottomToolbar.rightAnchor.constraint(equalTo: topContainer.rightAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 72),
            bottomToolbar.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),

            topSeparator.heightAnchor.constraint(equalToConstant: .hairline),
            topSeparator.topAnchor.constraint(equalTo: view.topAnchor),
            topSeparator.leftAnchor.constraint(equalTo: view.leftAnchor),
            topSeparator.rightAnchor.constraint(equalTo: view.rightAnchor),

            audioPreviewView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: 20),
            audioPreviewView.leftAnchor.constraint(equalTo: topContainer.leftAnchor, constant: 8),
            audioPreviewView.rightAnchor.constraint(equalTo: topContainer.rightAnchor, constant: -8),
            audioPreviewView.heightAnchor.constraint(equalToConstant: 100),

            timeLabel.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: stopRecordButton.topAnchor, constant: -16),

            tipLabel.centerXAnchor.constraint(equalTo: topContainer.centerXAnchor),
            tipLabel.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),

            recordButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            recordButton.heightAnchor.constraint(equalToConstant: 40),
            recordButton.widthAnchor.constraint(equalTo: recordButton.heightAnchor),

            stopRecordButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            stopRecordButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            stopRecordButton.heightAnchor.constraint(equalToConstant: 40),
            stopRecordButton.widthAnchor.constraint(equalTo: stopRecordButton.heightAnchor),

            confirmButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            confirmButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: 40),
            confirmButton.widthAnchor.constraint(equalTo: confirmButton.heightAnchor),

            redoButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            redoButton.leftAnchor.constraint(equalTo: bottomToolbar.leftAnchor, constant: 8),

            cancelButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            cancelButton.rightAnchor.constraint(equalTo: bottomToolbar.rightAnchor, constant: -8),
        ])
    }

    // MARK: - View Updates

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        confirmButton.layer.cornerRadius = confirmButton.bounds.size.width / 2
        recordButton.layer.cornerRadius = recordButton.bounds.size.width / 2
        stopRecordButton.layer.cornerRadius = stopRecordButton.bounds.size.width / 2
    }

    func updateTimeLabel(_ durationInSeconds: TimeInterval) {
        let duration = Int(floor(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }

    private func visibleViews(forState: State) -> [UIView] {
        var result = [topSeparator, topContainer, bottomToolbar]
        switch state {
        case .ready:
            result.append(contentsOf: [tipLabel, recordButton])
        case .recording:
            result.append(contentsOf: [audioPreviewView, timeLabel, stopRecordButton])
        case .effects:
            result.append(contentsOf: [redoButton, confirmButton, cancelButton])
        }

        return result
    }

    // MARK: - Recording

    func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let self else { return }
            updateTimeLabel(time)
        }

        recorder.recordEndedCallback = { [weak self] result in
            guard let self else { return }

            state = .effects

            if case let .failure(error) = result, let error = error as? RecordingError,
               let alert = recorder.alertForRecording(error: error) {
                present(alert, animated: true, completion: .none)
            }
        }

        recorder.recordLevelCallBack = { [weak self] level in
            guard let self else { return }
            audioPreviewView.updateWithLevel(level)
        }
    }

    private func updateRecordingState(_ state: State) {
        let allViews = Set(view.subviews.flatMap(\.subviews))
        let visibleViews = visibleViews(forState: state)
        let hiddenViews = allViews.subtracting(visibleViews)

        visibleViews.forEach { $0.isHidden = false }
        hiddenViews.forEach { $0.isHidden = true }

        switch state {
        case .ready:
            closeEffectsPicker(animated: false)
            recordTapGestureRecognizer.isEnabled = true
            updateTimeLabel(0)

        case .recording:
            closeEffectsPicker(animated: false)
            recordTapGestureRecognizer.isEnabled = false

        case .effects:
            openEffectsPicker()
            recordTapGestureRecognizer.isEnabled = false
        }
    }

    private func openEffectsPicker() {
        guard let url = recorder.fileURL else { return zmLog.warn("Nil url passed to add effect to audio file") }

        let noizeReducePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("noize-reduce.wav")
        noizeReducePath.deleteFileAtPath()

        // To apply noize reduction filter
        AVSAudioEffectType.none.apply(url.path, outPath: noizeReducePath) {
            self.currentEffectFilePath = noizeReducePath
            url.path.deleteFileAtPath()

            if self.effectPickerViewController != .none {
                self.closeEffectsPicker(animated: false)
            }

            let picker = AudioEffectsPickerViewController(
                recordingPath: noizeReducePath,
                duration: self.recorder.currentDuration
            )
            self.addChild(picker)
            picker.delegate = self
            picker.view.alpha = 0

            let changes: () -> Void = {
                picker.view.translatesAutoresizingMaskIntoConstraints = false
                self.topContainer.addSubview(picker.view)
                picker.view.fitIn(view: self.topContainer)
                picker.view.alpha = 1
            }

            UIView.transition(
                with: self.view,
                duration: 0.35,
                options: [.curveEaseIn],
                animations: changes,
                completion: { _ in picker.didMove(toParent: self) }
            )

            self.effectPickerViewController = picker
        }
    }

    private func closeEffectsPicker(animated: Bool) {
        if let picker = effectPickerViewController {
            picker.willMove(toParent: nil)
            picker.removeFromParent()
            effectPickerViewController = .none
        }
    }

    // MARK: - Button Actions

    @objc
    func recordButtonPressed(_: AnyObject!) {
        recorder.startRecording { _ in
            self.state = .recording
            self.delegate?.audioRecordViewControllerDidStartRecording(self)
            AppDelegate.shared.mediaPlaybackManager?.audioTrackPlayer.stop()
        }
    }

    @objc
    func stopRecordButtonPressed(_: UIButton?) {
        recorder.stopRecording()
    }

    @objc
    func confirmButtonPressed(_ button: UIButton?) {
        guard let audioPath = currentEffectFilePath else {
            zmLog.error("No file to send")
            return
        }
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        button?.isEnabled = false

        let effectName = currentEffect == .none ? "Original" : currentEffect.description

        let filename = String.filename(for: selfUser, suffix: "-" + effectName).appendingPathExtension("m4a")!
        let convertedPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        convertedPath.deleteFileAtPath()

        AVAsset.convertAudioToUploadFormat(audioPath, outPath: convertedPath) { success in
            if success {
                audioPath.deleteFileAtPath()
                self.delegate?.audioRecordViewControllerWantsToSendAudio(
                    self,
                    recordingURL: URL(fileURLWithPath: convertedPath),
                    duration: self.recorder.currentDuration,
                    filter: self.currentEffect
                )
            }
        }
    }

    @objc
    func redoButtonPressed(_: UIButton?) {
        recorder.deleteRecording()
        state = .ready
    }

    @objc
    func cancelButtonPressed(_: UIButton?) {
        delegate?.audioRecordViewControllerDidCancel(self)
    }
}

// MARK: - AudioEffectsPickerDelegate

extension AudioRecordKeyboardViewController: AudioEffectsPickerDelegate {
    func audioEffectsPickerDidPickEffect(
        _ picker: AudioEffectsPickerViewController,
        effect: AVSAudioEffectType,
        resultFilePath: String
    ) {
        currentEffectFilePath = resultFilePath
        currentEffect = effect
    }
}
