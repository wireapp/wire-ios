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
import WireSyncEngine

// MARK: - CallController

final class CallController: NSObject {
    // MARK: Lifecycle

    // MARK: - Init

    init(userSession: UserSession) {
        super.init()
        addObservers(userSession: userSession)
    }

    deinit {
        observerTokens.removeAll()
    }

    // MARK: Internal

    // MARK: - Public Implentation

    weak var router: ActiveCallRouterProtocol?
    var callConversationProvider: CallConversationProvider?

    // MARK: - Public Implementation

    func updateActiveCallPresentationState() {
        guard let priorityCallConversation else {
            dismissCall()
            return
        }
        showCallTopOverlay(for: priorityCallConversation)
        presentOrMinimizeActiveCall(for: priorityCallConversation)
    }

    // MARK: Private

    // MARK: - Private Implentation

    private var observerTokens: [Any] = []
    private var minimizedCall: ZMConversation?

    private var dateOfLastErrorAlertByConversationId = [AVSIdentifier: Date]()

    private var priorityCallConversation: ZMConversation? {
        callConversationProvider?.priorityCallConversation
    }

    private var alertDebounceInterval: TimeInterval { 15 * .oneMinute  }

    // MARK: - Private Implementation

    private func addObservers(userSession: UserSession) {
        observerTokens.append(userSession.addConferenceCallStateObserver(self))
        observerTokens.append(userSession.addConferenceCallErrorObserver(self))
    }

    private func presentOrMinimizeActiveCall(for conversation: ZMConversation) {
        if conversation == minimizedCall {
            minimizeCall()
        } else {
            presentCall(in: conversation)
        }
    }

    private func minimizeCall() {
        router?.minimizeCall(animated: true, completion: nil)
    }

    private func presentCall(in conversation: ZMConversation) {
        guard let voiceChannel = conversation.voiceChannel else { return }
        if minimizedCall == conversation { minimizedCall = nil }

        let animated = shouldAnimateTransitionForCall(in: conversation)
        router?.presentActiveCall(for: voiceChannel, animated: animated)
    }

    private func dismissCall() {
        router?.dismissActiveCall(animated: true, completion: { [weak self] in
            self?.hideCallTopOverlay()
            self?.minimizedCall = nil
        })
    }

    private func showCallTopOverlay(for conversation: ZMConversation) {
        router?.showCallTopOverlay(for: conversation)
    }

    private func hideCallTopOverlay() {
        router?.hideCallTopOverlay()
    }

    private func shouldAnimateTransitionForCall(in conversation: ZMConversation) -> Bool {
        guard SessionManager.shared?.callNotificationStyle == .callKit else {
            return true
        }

        switch conversation.voiceChannel?.state {
        case .outgoing?:
            return true
        default:
            return false // We don't want animate when transition from CallKit screen
        }
    }

    private func isClientOutdated(callState: CallState) -> Bool {
        switch callState {
        case let .terminating(reason) where reason == .outdatedClient:
            true
        default:
            false
        }
    }

    private func acceptDegradedCall(conversation: ZMConversation) {
        guard let userSession = ZMUserSession.shared() else { return }

        userSession.enqueue({
            conversation.voiceChannel?.continueByDecreasingConversationSecurity(userSession: userSession)
        }, completionHandler: {
            conversation.joinCall()
        })
    }

    private func cancelCall(conversation: ZMConversation) {
        guard let userSession = ZMUserSession.shared() else { return }
        conversation.voiceChannel?.leave(userSession: userSession, completion: nil)
    }
}

// MARK: WireCallCenterCallStateObserver

extension CallController: WireCallCenterCallStateObserver {
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        presentUnsupportedVersionAlertIfNecessary(callState: callState)
        presentSecurityDegradedAlertIfNecessary(for: conversation, callState: callState) { continueCall in
            if continueCall {
                self.updateActiveCallPresentationState()
            }
        }
    }

    private func presentUnsupportedVersionAlertIfNecessary(callState: CallState) {
        guard isClientOutdated(callState: callState) else { return }
        router?.presentUnsupportedVersionAlert()
    }

    /// Present warning about incoming call on unverified conversation
    /// - Parameters:
    ///   - conversation: unverified conversation
    ///   - callState: state of the incoming call
    ///   - continueCallBlock: block to execute if no alert is shown or after user confirm or cancel choice on alert
    private func presentSecurityDegradedAlertIfNecessary(
        for conversation: ZMConversation,
        callState: CallState,
        continueCallBlock: @escaping (Bool) -> Void
    ) {
        guard let voiceChannel = conversation.voiceChannel else {
            // no alert to show, continue
            continueCallBlock(true)
            return
        }

        let degradationState = voiceChannel.degradationState

        let alertCompletion: (AlertChoice) -> Void = { [weak self] choice in
            switch choice {
            case .cancel:
                self?.cancelCall(conversation: conversation)
                continueCallBlock(false)

            case .confirm:
                self?.acceptDegradedCall(conversation: conversation)
                continueCallBlock(true)

            case .ok:
                continueCallBlock(true)

            case .alreadyPresented:
                // do nothing
                break
            }
        }

        switch (degradationState, callState) {
        case (
            .incoming(reason: let degradationReason),
            .incoming(video: _, shouldRing: true, degraded: true)
        ):
            router?.presentIncomingSecurityDegradedAlert(
                for: degradationReason,
                completion: alertCompletion
            )

        case (_, .terminating(reason: .securityDegraded)):
            if let reason = voiceChannel.degradationReason {
                router?.presentEndingSecurityDegradedAlert(
                    for: reason,
                    completion: alertCompletion
                )
            }

        default:
            // no alert to show, continue
            continueCallBlock(true)
            // dismiss alert that would be there
            router?.dismissSecurityDegradedAlertIfNeeded()
        }
    }
}

// MARK: ActiveCallViewControllerDelegate

extension CallController: ActiveCallViewControllerDelegate {
    func activeCallViewControllerDidDisappear(
        _ activeCallViewController: UIViewController,
        for conversation: ZMConversation?
    ) {
        router?.dismissActiveCall(animated: true, completion: nil)
        minimizedCall = conversation
    }
}

// MARK: WireCallCenterCallErrorObserver

extension CallController: WireCallCenterCallErrorObserver {
    func callCenterDidReceiveCallError(_ error: CallError, conversationId: AVSIdentifier) {
        guard
            error == .unknownProtocol,
            shouldDisplayErrorAlert(for: conversationId)
        else {
            return
        }

        dateOfLastErrorAlertByConversationId[conversationId] = Date()
        router?.presentUnsupportedVersionAlert()
    }

    private func shouldDisplayErrorAlert(for conversation: AVSIdentifier) -> Bool {
        guard let dateOfLastErrorAlert = dateOfLastErrorAlertByConversationId[conversation] else {
            return true
        }

        let elapsedTimeIntervalSinceLastAlert = -dateOfLastErrorAlert.timeIntervalSinceNow
        return elapsedTimeIntervalSinceLastAlert > alertDebounceInterval
    }
}

extension CallController {
    // NOTA BENE: THIS MUST BE USED JUST FOR TESTING PURPOSE
    func testHelper_setMinimizedCall(_ conversation: ZMConversation?) {
        minimizedCall = conversation
    }
}
