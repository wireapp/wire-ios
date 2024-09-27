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
import WireSyncEngine

// MARK: - CallViewControllerDelegate

protocol CallViewControllerDelegate: AnyObject {
    func callViewControllerDidDisappear(
        _ callController: CallViewController,
        for conversation: ZMConversation?
    )
}

// MARK: - CallViewController

final class CallViewController: UIViewController {
    weak var delegate: CallViewControllerDelegate?
    private var tapRecognizer: UITapGestureRecognizer!
    private let mediaManager: AVSMediaManagerInterface
    private let voiceChannel: VoiceChannel
    private var callInfoConfiguration: CallInfoConfiguration
    private var preferedVideoPlaceholderState: CallVideoPlaceholderState = .statusTextHidden
    private let callInfoRootViewController: CallInfoRootViewController
    private weak var overlayTimer: Timer?
    private let hapticsController = CallHapticsController()
    private let isOverlayEnabled: Bool

    private var classification: SecurityClassification? = .none {
        didSet { updateConfiguration() }
    }

    private var voiceChannelObserverTokens: [Any] = []
    private var conversationObserverToken: Any?
    private var callGridConfiguration: CallGridConfiguration
    private let callGridViewController: CallGridViewController
    private var cameraType: CaptureDevice = .front
    private var singleTapRecognizer: UITapGestureRecognizer!
    private var doubleTapRecognizer: UITapGestureRecognizer!

    private var isInteractiveDismissal = false

    let userSession: UserSession

    var conversation: ZMConversation? {
        voiceChannel.conversation
    }

    private var proximityMonitorManager: ProximityMonitorManager?

    private var permissions: CallPermissionsConfiguration {
        callInfoConfiguration.permissions
    }

    private static var userEnabledCBR: Bool {
        Settings.shared[.callingConstantBitRate] == true
    }

    weak var configurationObserver: CallInfoConfigurationObserver?

    init(
        voiceChannel: VoiceChannel,
        selfUser: UserType,
        proximityMonitorManager: ProximityMonitorManager? = ZClientViewController.shared?.proximityMonitorManager,
        mediaManager: AVSMediaManagerInterface = AVSMediaManager.sharedInstance(),
        permissionsConfiguration: CallPermissionsConfiguration = CallPermissions(),
        isOverlayEnabled: Bool = true,
        userSession: UserSession
    ) {
        self.voiceChannel = voiceChannel
        self.mediaManager = mediaManager
        self.proximityMonitorManager = proximityMonitorManager
        self.callGridConfiguration = CallGridConfiguration(voiceChannel: voiceChannel)
        self.isOverlayEnabled = isOverlayEnabled
        self.userSession = userSession

        if let participants = voiceChannel.conversation?.participants {
            self.classification = userSession.classification(users: participants, conversationDomain: nil)
        }

        self.callInfoConfiguration = CallInfoConfiguration(
            voiceChannel: voiceChannel,
            preferedVideoPlaceholderState: preferedVideoPlaceholderState,
            permissions: permissionsConfiguration,
            cameraType: cameraType,
            mediaManager: mediaManager,
            userEnabledCBR: CallViewController.userEnabledCBR,
            classification: classification,
            selfUser: selfUser
        )

        self.callInfoRootViewController = CallInfoRootViewController(
            configuration: callInfoConfiguration,
            selfUser: userSession.selfUser,
            userSession: userSession
        )

        self.callGridViewController = CallGridViewController(
            voiceChannel: voiceChannel,
            configuration: callGridConfiguration
        )

        super.init(nibName: nil, bundle: nil)
        callInfoRootViewController.delegate = self
        callGridViewController.delegate = self

        setupObservers()

        proximityMonitorManager?.stateChanged = { [weak self] raisedToEar in
            self?.proximityStateDidChange(raisedToEar)
        }
        disableVideoIfNeeded()

        setupViews()
        createConstraints()

        updateConfiguration()

        self.singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        if isOverlayEnabled {
            view.addGestureRecognizer(singleTapRecognizer)
        } else {
            callInfoRootViewController.view.alpha = 0
        }

        self.doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapRecognizer)

        singleTapRecognizer.require(toFail: doubleTapRecognizer)
    }

    @objc
    private func handleSingleTap(_ sender: UITapGestureRecognizer) {
        guard canHideOverlay else { return }

        if let overlay = callGridViewController.previewOverlay,
           overlay.point(inside: sender.location(in: overlay), with: nil), !isOverlayVisible {
            return
        }
        toggleOverlayVisibility()
    }

    @objc
    func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        guard !isOverlayVisible else { return }

        callGridViewController.handleDoubleTap(gesture: sender)
    }

    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
        NotificationCenter.default.removeObserver(self)
        stopOverlayTimer()
    }

    private func setupApplicationStateObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                resumeVideoIfNeeded
            ),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                pauseVideoIfNeeded
            ),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateVideoStatusPlaceholder()
        AVSMediaManagerClientChangeNotification.add(self)
        proximityMonitorManager?.startListening()
        resumeVideoIfNeeded()
        setupApplicationStateObservers()
        updateIdleTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        proximityMonitorManager?.stopListening()
        pauseVideoIfNeeded()
        isInteractiveDismissal = transitionCoordinator?.isInteractive == true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false

        if isInteractiveDismissal {
            delegate?.callViewControllerDidDisappear(self, for: conversation)
        }
    }

    func reloadGrid() {
        callGridViewController.releadGridData()
    }

    override func accessibilityPerformEscape() -> Bool {
        guard let delegate else { return false }
        delegate.callViewControllerDidDisappear(self, for: conversation)
        return true
    }

    override var prefersStatusBarHidden: Bool {
        !isOverlayVisible
    }

    @objc
    private func resumeVideoIfNeeded() {
        guard voiceChannel.videoState.isPaused else { return }
        voiceChannel.videoState = .started
        updateConfiguration()
    }

    @objc
    private func pauseVideoIfNeeded() {
        guard voiceChannel.videoState.isSending else { return }
        voiceChannel.videoState = .paused
        updateConfiguration()
    }

    private func setupViews() {
        if isOverlayEnabled {
            [callGridViewController, callInfoRootViewController].forEach(addToSelf)
        } else {
            addToSelf(callGridViewController)
        }

        view.backgroundColor = .clear
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            callGridViewController.view.topAnchor.constraint(equalTo: view.safeTopAnchor),
            callGridViewController.view.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            callGridViewController.view.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            callGridViewController.view.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
        ])
    }

    private func setupObservers() {
        voiceChannelObserverTokens += [
            voiceChannel.addCallStateObserver(self),
            voiceChannel.addParticipantObserver(self),
            voiceChannel.addConstantBitRateObserver(self),
            voiceChannel.addMuteStateObserver(self),
            voiceChannel.addActiveSpeakersObserver(self),
        ]

        guard
            let conversation,
            conversation.managedObjectContext != nil
        else {
            return
        }

        conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
    }

    private func minimizeOverlay() {
        delegate?.callViewControllerDidDisappear(self, for: conversation)
    }

    private lazy var establishingCallStatusView = EstablishingCallStatusView()

    private func acceptDegradedCall() {
        guard let userSession = userSession as? ZMUserSession else { return }

        userSession.enqueue({
            self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession)
        }, completionHandler: {
            self.conversation?.joinCall()
        })
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateConfiguration() {
        callInfoConfiguration = CallInfoConfiguration(
            voiceChannel: voiceChannel,
            preferedVideoPlaceholderState: preferedVideoPlaceholderState,
            permissions: permissions,
            cameraType: cameraType,
            mediaManager: mediaManager,
            userEnabledCBR: CallViewController.userEnabledCBR,
            classification: classification,
            selfUser: userSession.selfUser
        )

        callInfoRootViewController.configuration = callInfoConfiguration
        callGridConfiguration = CallGridConfiguration(voiceChannel: voiceChannel)
        callGridViewController.configuration = callGridConfiguration
        updateOverlayAfterStateChanged()
        updateIdleTimer()
        configurationObserver?.didUpdateConfiguration(configuration: callInfoConfiguration)
        showIncomingCallStatusViewIfNeeded(forConfiguration: callInfoConfiguration)
    }

    private func showIncomingCallStatusViewIfNeeded(forConfiguration configuration: CallInfoConfiguration) {
        let state = configuration.state
        guard state.requiresShowingStatusView else {
            establishingCallStatusView.removeFromSuperview()
            return
        }
        establishingCallStatusView.setProfileImage(hidden: configuration.mediaState.isSendingVideo)
        establishingCallStatusView.updateState(state: state)
        establishingCallStatusView.setTitle(title: configuration.title)
        guard establishingCallStatusView.superview == nil else { return }
        establishingCallStatusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(establishingCallStatusView)
        NSLayoutConstraint.activate(
            NSLayoutConstraint.forView(view: establishingCallStatusView, inContainer: view, withInsets: .zero)
        )
        guard let user = voiceChannel.getSecondParticipant(),
              let session = userSession as? ZMUserSession else { return }
        user.fetchProfileImage(
            session: session,
            imageCache: UIImage.defaultUserImageCache,
            sizeLimit: UserImageView.Size.normal.rawValue,
            isDesaturated: false,
            completion: { [weak self] image, _ in
                guard let image else { return }
                self?.establishingCallStatusView.setProfileImage(image: image)
            }
        )
    }

    private func updateIdleTimer() {
        let disabled = callInfoConfiguration.disableIdleTimer
        UIApplication.shared.isIdleTimerDisabled = disabled
        Log.calling.debug("Updated idle timer: \(disabled ? "disabled" : "enabled")")
    }

    private func alertVideoUnavailable() {
        guard voiceChannel.videoState == .stopped else { return }

        if !callInfoConfiguration.permissions.canAcceptVideoCalls {
            present(UIAlertController.cameraPermissionAlert(), animated: true)
        } else {
            presentLegacyAlertIfNeeded()
        }
    }

    private func presentLegacyAlertIfNeeded() {
        guard
            !voiceChannel.isConferenceCall,
            voiceChannel.isLegacyGroupVideoParticipantLimitReached
        else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Localizable.Call.Video.TooMany.Alert.title,
            message: L10n.Localizable.Call.Video.TooMany.Alert.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(alert, animated: true)
    }

    func toggleVideoState() {
        if !permissions.canAcceptVideoCalls {
            permissions.requestOrWarnAboutVideoPermission { isVideoPermissionGranted in
                self.disableVideoIfNeeded()
                self.updateVideoStatusPlaceholder()
                guard isVideoPermissionGranted else { return }
            }
        }

        let newState = voiceChannel.videoState.toggledState
        preferedVideoPlaceholderState = newState == .stopped ? .statusTextHidden : .hidden
        voiceChannel.videoState = newState
        updateConfiguration()
        AnalyticsCallingTracker.userToggledVideo(in: voiceChannel)
    }

    private func toggleCameraAnimated() {
        toggleCameraType()
    }

    private func toggleCameraType() {
        do {
            let newType: CaptureDevice = cameraType == .front ? .back : .front
            try voiceChannel.setVideoCaptureDevice(newType)
            cameraType = newType
        } catch {
            Log.calling.error("error toggling capture device: \(error)")
        }
    }
}

// MARK: ZMConversationObserver

extension CallViewController: ZMConversationObserver {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard
            changeInfo.participantsChanged,
            let participants = conversation?.participants
        else {
            return
        }

        classification = userSession.classification(users: participants, conversationDomain: nil)
    }
}

// MARK: WireCallCenterCallStateObserver

extension CallViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        updateConfiguration()
        hideOverlayAfterCallEstablishedIfNeeded()
        hapticsController.updateCallState(callState)
    }
}

// MARK: ActiveSpeakersObserver

extension CallViewController: ActiveSpeakersObserver {
    func callCenterDidChangeActiveSpeakers() {
        updateConfiguration()
    }
}

// MARK: WireCallCenterCallParticipantObserver

extension CallViewController: WireCallCenterCallParticipantObserver {
    func callParticipantsDidChange(
        conversation: ZMConversation,
        participants: [CallParticipant]
    ) {
        hapticsController.updateParticipants(participants)
        updateVideoGridPresentationModeIfNeeded(participants: participants)
        updateConfiguration() // Has to succeed updating the timestamps
    }

    private func updateVideoGridPresentationModeIfNeeded(participants: [CallParticipant]) {
        guard !participants.hasMoreThanTwoConnectedParticipants else { return }

        voiceChannel.videoGridPresentationMode = .allVideoStreams
    }
}

// MARK: AVSMediaManagerClientObserver

extension CallViewController: AVSMediaManagerClientObserver {
    func mediaManagerDidChange(_: AVSMediaManagerClientChangeNotification!) {
        updateConfiguration()
    }
}

// MARK: MuteStateObserver

extension CallViewController: MuteStateObserver {
    func callCenterDidChange(muted: Bool) {
        updateConfiguration()
    }
}

extension CallViewController {
    private func acceptCallIfPossible() {
        guard let conversation else {
            fatalError("Trying to accept a call for a voice channel without conversation.")
        }

        permissions.requestOrWarnAboutAudioPermission { audioGranted in
            guard audioGranted else {
                guard let userSession = self.userSession as? ZMUserSession else { return }
                return self.voiceChannel.leave(userSession: userSession, completion: nil)
            }

            conversation.confirmJoiningCallIfNeeded(alertPresenter: self, forceAlertModal: true) {
                self.checkVideoPermissions { videoGranted in
                    let video = videoGranted && self.voiceChannel.videoState.isSending
                    conversation.joinVoiceChannel(video: video)
                    self.disableVideoIfNeeded()
                }
            }
        }
    }

    private func checkVideoPermissions(resultHandler: @escaping (Bool) -> Void) {
        guard voiceChannel.isVideoCall else { return resultHandler(false) }

        if !permissions.isPendingVideoPermissionRequest {
            resultHandler(permissions.canAcceptVideoCalls)
            updateConfiguration()
            return
        }

        permissions.requestVideoPermissionWithoutWarning { granted in
            resultHandler(granted)
            self.disableVideoIfNeeded()
            self.updateVideoStatusPlaceholder()
        }
    }

    private func updateVideoStatusPlaceholder() {
        preferedVideoPlaceholderState = permissions.preferredVideoPlaceholderState
        updateConfiguration()
    }

    private func disableVideoIfNeeded() {
        if permissions.isVideoDisabledForever {
            voiceChannel.videoState = .stopped
        }
    }
}

// MARK: ConstantBitRateAudioObserver

extension CallViewController: ConstantBitRateAudioObserver {
    func callCenterDidChange(constantAudioBitRateAudioEnabled: Bool) {
        updateConfiguration()
    }
}

// MARK: CallInfoRootViewControllerDelegate

extension CallViewController: CallInfoRootViewControllerDelegate {
    func callingActionsViewPerformAction(_ action: CallAction) {
        Log.calling.debug("request to perform call action: \(action)")
        guard let userSession = userSession as? ZMUserSession else { return }

        switch action {
        case .continueDegradedCall: userSession
            .enqueue { self.voiceChannel.continueByDecreasingConversationSecurity(userSession: userSession) }

        case .acceptCall: acceptCallIfPossible()

        case .acceptDegradedCall: acceptDegradedCall()

        case .terminateCall: voiceChannel.leave(userSession: userSession, completion: nil)

        case .terminateDegradedCall: userSession.enqueue { self.voiceChannel.leave(
                userSession: userSession,
                completion: nil
            ) }

        case .toggleMuteState: voiceChannel.toggleMuteState(userSession: userSession)

        case .toggleSpeakerState: AVSMediaManager.sharedInstance().toggleSpeaker()

        case .minimizeOverlay: minimizeOverlay()

        case .toggleVideoState: toggleVideoState()

        case .alertVideoUnavailable: alertVideoUnavailable()

        case .flipCamera: toggleCameraAnimated()

        case .showParticipantsList: return // Handled in `CallInfoRootViewController`, we don't want to update.
        case let .updateVideoGridPresentationMode(mode): voiceChannel.videoGridPresentationMode = mode
        }

        updateConfiguration()
        restartOverlayTimerIfNeeded()
    }

    func infoRootViewController(
        _ viewController: CallInfoRootViewController,
        contextDidChange context: CallInfoRootViewController.Context
    ) {
        guard canHideOverlay else { return }
        switch context {
        case .overview: startOverlayTimer()
        case .participants: stopOverlayTimer()
        }
    }
}

// MARK: CallGridViewControllerDelegate

extension CallViewController: CallGridViewControllerDelegate {
    func callGridViewController(_ viewController: CallGridViewController, perform action: CallGridAction) {
        switch action {
        case let .requestVideoStreamsForClients(clients): voiceChannel.request(videoStreams: clients)
        }
    }
}

// MARK: - Hide + Show Overlay

extension CallViewController {
    var isOverlayVisible: Bool {
        callInfoRootViewController.view.alpha > 0
    }

    private var shouldOverlayStayVisibleForAutomation: Bool {
        AutomationHelper.sharedHelper.keepCallingOverlayVisible
    }

    private var canHideOverlay: Bool {
        guard case .established = callInfoConfiguration.state else { return false }

        return !shouldOverlayStayVisibleForAutomation
    }

    private func toggleOverlayVisibility() {
        animateOverlay(show: !isOverlayVisible)
    }

    private func animateOverlay(show: Bool) {
        guard isOverlayEnabled else { return }
        if show {
            startOverlayTimer()
        } else {
            stopOverlayTimer()
        }

        let animations = { [callInfoRootViewController, updateConfiguration] in
            callInfoRootViewController.view.alpha = show ? 1 : 0
            // We update the configuration here to ensure the mute overlay fade animation is in sync with the overlay
            updateConfiguration()
        }

        callGridViewController.isCovered = show

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: animations,
            completion: { [updateConfiguration] _ in updateConfiguration() }
        )
    }

    private func hideOverlayAfterCallEstablishedIfNeeded() {
        let isNotAnimating = callInfoRootViewController.view.layer.animationKeys()?.isEmpty ?? true

        guard
            overlayTimer == nil,
            canHideOverlay,
            isOverlayVisible,
            isNotAnimating
        else { return }

        animateOverlay(show: false)
    }

    func startOverlayTimer() {
        guard !shouldOverlayStayVisibleForAutomation else { return }

        stopOverlayTimer()
        overlayTimer = .scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            self?.animateOverlay(show: false)
        }
    }

    private func updateOverlayAfterStateChanged() {
        if canHideOverlay {
            if overlayTimer == nil {
                startOverlayTimer()
            }
        } else {
            if !isOverlayVisible {
                animateOverlay(show: true)
            }
            stopOverlayTimer()
        }
    }

    private func restartOverlayTimerIfNeeded() {
        guard overlayTimer != nil, canHideOverlay else { return }
        startOverlayTimer()
    }

    private func stopOverlayTimer() {
        overlayTimer?.invalidate()
        overlayTimer = nil
    }
}

extension CallViewController {
    func proximityStateDidChange(_ raisedToEar: Bool) {
        guard voiceChannel.isVideoCall, voiceChannel.videoState != .stopped else { return }
        voiceChannel.videoState = raisedToEar ? .paused : .started
        updateConfiguration()
    }
}
