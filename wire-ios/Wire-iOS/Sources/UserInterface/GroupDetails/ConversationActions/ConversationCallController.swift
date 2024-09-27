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
import WireDataModel
import WireSyncEngine

final class ConversationCallController: NSObject {
    // MARK: Lifecycle

    init(conversation: ZMConversation, target: UIViewController) {
        self.conversation = conversation
        self.target = target
        super.init()
    }

    // MARK: Internal

    func startAudioCall(started: Completion?) {
        let startCall = { [weak self] in
            guard let self else {
                return
            }
            conversation.confirmJoiningCallIfNeeded(alertPresenter: target) {
                started?()
                self.conversation.startAudioCall()
            }
        }

        if conversation.localParticipants.count <= confirmGroupCallParticipantsLimit {
            startCall()
        } else {
            confirmGroupCall { [weak self] accepted in
                self?.target.setNeedsStatusBarAppearanceUpdate()

                guard accepted else {
                    return
                }
                startCall()
            }
        }
    }

    func startVideoCall(started: Completion?) {
        let startVideoCall = { [weak self] in
            guard let self else {
                return
            }
            conversation.confirmJoiningCallIfNeeded(alertPresenter: target) {
                started?()
                self.conversation.startVideoCall()
            }
        }

        if conversation.localParticipants.count <= confirmGroupCallParticipantsLimit {
            startVideoCall()
        } else {
            confirmGroupCall { [weak self] accepted in
                self?.target.setNeedsStatusBarAppearanceUpdate()

                guard accepted else {
                    return
                }
                startVideoCall()
            }
        }
    }

    func joinCall() {
        guard conversation.canJoinCall else {
            return
        }

        let checker = PrivacyWarningChecker(
            conversation: conversation,
            alertType: .incomingCall,
            continueAction: { [conversation] in
                conversation.acknowledgePrivacyChanges()
                conversation.confirmJoiningCallIfNeeded(alertPresenter: self.target) { [conversation] in
                    conversation.joinCall() // This will result in joining an ongoing call.
                }
            },
            cancelAction: { [weak self] in
                guard let userSession = ZMUserSession.shared() else {
                    return
                }
                self?.conversation.voiceChannel?.leave(userSession: userSession, completion: nil)

            },
            showAlert: { [weak self] in
                self?.presentIncomingCallDegradedAlert()
            }
        )
        checker.performAction()
    }

    // MARK: Private

    private unowned let target: UIViewController
    private let conversation: ZMConversation
    private let confirmGroupCallParticipantsLimit = 4

    // MARK: - Helper

    private func presentIncomingCallDegradedAlert() {
        let alert = UIAlertController.makeIncomingDegradedMLSCall(confirmationBlock: { answerDegradedCall in
            PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: answerDegradedCall)
        })
        target.present(alert, animated: true)
    }

    private func confirmGroupCall(completion: @escaping (_ completion: Bool) -> Void) {
        let controller = UIAlertController.confirmGroupCall(
            participants: conversation.localParticipants.count - 1,
            completion: completion
        )

        target.present(controller, animated: true)
    }
}
