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
import WireDataModel
import WireDesign
import WireSyncEngine

// MARK: Audio Button

extension ConversationInputBarViewController {
    func setupCallStateObserver() {
        if !ProcessInfo.processInfo.isRunningTests,
           let userSession = ZMUserSession.shared() {
            callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        }
    }

    @objc
    func audioButtonPressed(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }

        let checker = PrivacyWarningChecker(conversation: conversation) {
            self.recordAudio()
        }
        checker.performAction()
    }

    private func recordAudio() {
        if displayAudioMessageAlertIfNeeded() {
            return
        }

        switch mode {
        case .audioRecord:
            if inputBar.textView.isFirstResponder {
                hideInKeyboardAudioRecordViewController()
            } else {
                inputBar.textView.becomeFirstResponder()
            }
        default:
            UIApplication.wr_requestOrWarnAboutMicrophoneAccess { accepted in
                if accepted {
                    self.mode = .audioRecord
                    self.inputBar.textView.becomeFirstResponder()
                }
            }
        }
    }

    private func displayAudioMessageAlertIfNeeded() -> Bool {
        CameraAccess.displayAlertIfOngoingCall(at: .recordAudioMessage, from: self)
    }

    @objc
    func audioButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard mode != .audioRecord, !displayAudioMessageAlertIfNeeded() else {
            return
        }

        type(of: self).cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(hideInlineAudioRecordViewController),
            object: nil
        )

        switch sender.state {
        case .began:
            createAudioViewController(userSession: userSession)
            showAudioRecordViewControllerIfGrantedAccess()
        case .changed:
            audioRecordViewController?.updateWithChangedRecognizer(sender)
        case .ended, .cancelled, .failed:
            audioRecordViewController?.finishRecordingIfNeeded(sender)
        default: break
        }
    }

    private func showAudioRecordViewControllerIfGrantedAccess() {
        if audioSession.recordPermission == .granted {
            audioRecordViewController?.beginRecording()
        } else {
            requestMicrophoneAccess()
        }
    }

    func createAudioViewController(audioRecorder: AudioRecorderType? = nil, userSession: UserSession) {
        removeAudioViewController()

        let audioRecordViewController = AudioRecordViewController(
            audioRecorder: audioRecorder,
            userSession: userSession
        )
        audioRecordViewController.view.translatesAutoresizingMaskIntoConstraints = false
        audioRecordViewController.delegate = self

        let audioRecordViewContainer = UIView()
        audioRecordViewContainer.translatesAutoresizingMaskIntoConstraints = false
        audioRecordViewContainer.backgroundColor = SemanticColors.View.backgroundDefault
        audioRecordViewContainer.isHidden = true

        addChild(audioRecordViewController)
        inputBar.addSubview(audioRecordViewContainer)
        audioRecordViewContainer.fitIn(view: inputBar)
        audioRecordViewContainer.addSubview(audioRecordViewController.view)

        _ = inputBar.convert(audioButton.bounds, from: audioButton)

        NSLayoutConstraint.activate([
            audioRecordViewController.view.trailingAnchor.constraint(equalTo: audioRecordViewContainer.trailingAnchor),
            audioRecordViewController.view.leadingAnchor.constraint(equalTo: audioRecordViewContainer.leadingAnchor),
            audioRecordViewController.view.bottomAnchor.constraint(equalTo: audioRecordViewContainer.bottomAnchor),
            audioRecordViewController.view.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: -0.5),
        ])

        self.audioRecordViewController = audioRecordViewController
        self.audioRecordViewContainer = audioRecordViewContainer
    }

    func removeAudioViewController() {
        audioRecordViewController?.removeFromParent()
        audioRecordViewContainer?.removeFromSuperview()

        audioRecordViewContainer = nil
        audioRecordViewController = nil
    }

    private func requestMicrophoneAccess() {
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { granted in
            guard granted else { return }
        }
    }

    func showAudioRecordViewController(animated: Bool = true) {
        guard let audioRecordViewContainer,
              let audioRecordViewController else {
            return
        }

        inputBar.buttonContainer.isHidden = true

        if animated {
            audioRecordViewController.setOverlayState(.hidden, animated: false)
            UIView.transition(
                with: inputBar,
                duration: 0.1,
                options: [.transitionCrossDissolve, .allowUserInteraction],
                animations: {
                    audioRecordViewContainer.isHidden = false
                },
                completion: { _ in
                    audioRecordViewController.setOverlayState(.expanded(0), animated: true)
                }
            )
        } else {
            audioRecordViewContainer.isHidden = false
            audioRecordViewController.setOverlayState(.expanded(0), animated: false)
        }
    }

    func hideAudioRecordViewController() {
        if mode == .audioRecord {
            hideInKeyboardAudioRecordViewController()
        } else {
            hideInlineAudioRecordViewController()
        }
    }

    private func hideInKeyboardAudioRecordViewController() {
        inputBar.textView.resignFirstResponder()
        delay(0.3) {
            self.mode = .textInput
        }
    }

    @objc
    private func hideInlineAudioRecordViewController() {
        inputBar.buttonContainer.isHidden = false
        guard let audioRecordViewContainer else {
            return
        }

        UIView.transition(with: inputBar, duration: 0.2, options: .transitionCrossDissolve, animations: {
            audioRecordViewContainer.isHidden = true
        }, completion: nil)
    }

    func hideCameraKeyboardViewController(_ completion: @escaping () -> Void) {
        inputBar.textView.resignFirstResponder()
        delay(0.3) {
            self.mode = .textInput
            completion()
        }
    }
}

extension ConversationInputBarViewController: AudioRecordViewControllerDelegate {
    func audioRecordViewControllerDidCancel(_: AudioRecordBaseViewController) {
        hideAudioRecordViewController()
    }

    func audioRecordViewControllerDidStartRecording(_: AudioRecordBaseViewController) {
        if mode != .audioRecord {
            showAudioRecordViewController()
        }
    }

    func audioRecordViewControllerWantsToSendAudio(
        _ audioRecordViewController: AudioRecordBaseViewController,
        recordingURL: URL,
        duration: TimeInterval,
        filter: AVSAudioEffectType
    ) {
        let checker = PrivacyWarningChecker(conversation: conversation) { [weak self] in
            self?.uploadFile(at: recordingURL as URL)

            self?.hideAudioRecordViewController()
        }
        checker.performAction()
    }
}

extension ConversationInputBarViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        let isRecording = audioRecordKeyboardViewController?.isRecording

        switch (callState, isRecording, wasRecordingBeforeCall) {
        case (.incoming(_, true, _), true, _),              // receiving incoming call while audio keyboard is visible
             (.outgoing, true, _):                          // making an outgoing call while audio keyboard is visible
            wasRecordingBeforeCall = true                   // -> remember that the audio keyboard was visible
            callCountWhileCameraKeyboardWasVisible += 1     // -> increment calls in progress counter
        case (.incoming(_, false, _), _, true),             // refusing an incoming call
             (.terminating, _, true):                       // terminating/closing the current call
            callCountWhileCameraKeyboardWasVisible -= 1     // -> decrement calls in progress counter
        default: break
        }

        if callCountWhileCameraKeyboardWasVisible == 0, wasRecordingBeforeCall {
            displayRecordKeyboard() // -> show the audio record keyboard again
        }
    }

    private func displayRecordKeyboard() {
        // do not show keyboard if conversation list is shown,
        guard let splitViewController = wr_splitViewController,
              let rightViewController = splitViewController.rightViewController,
              splitViewController.isRightViewControllerRevealed,
              rightViewController.isVisible,
              AppDelegate.shared.mainWindow.isKeyWindow
        else { return }

        wasRecordingBeforeCall = false
        mode = .audioRecord
        inputBar.textView.becomeFirstResponder()
    }
}
