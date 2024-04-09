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
import WireDataModel

protocol E2EIPrivacyWarningPresenter: AnyObject {
    func presentE2EIPrivacyWarningAlert(_ notification: Notification)
}

// Checks if E2EIPrivacyWarningAlert needs to be presented before given action
struct E2EIPrivacyWarningChecker {
    enum AlertType: Int {
        case message, outgoingCall, incomingCall
    }
    var conversation: ConversationLike
    var alertType = AlertType.message
    var continueAction: () -> Void

    // set if need to do extra action on cancel
    var cancelAction: (() -> Void)?
    // set if need to present differently the alert without notification: `.presentE2EIPrivacyWarningAlert`
    var showAlert: (() -> Void)?

    func performAction() {
        guard conversation.isMLSConversationDegraded else {
            continueAction()
            return
        }

        if let showAlert {
            showAlert()
        } else {
            NotificationCenter.default.post(.presentE2EIPrivacyWarningAlert(type: alertType))
        }

        Task {
            var shouldContinue = false
            for await notification in NotificationCenter.default.notifications(named: .e2eiPrivacyWarningConfirm) {
                shouldContinue = notification.sendAnyway
                break
            }

            if shouldContinue {
                await MainActor.run {
                    continueAction()
                }
            } else {
                await MainActor.run {
                    cancelAction?()
                }
            }
        }
    }

    // Notifies all MLSConversationChecker about user's choice following e2eiPrivacyWarningAlert
    static func e2eiPrivacyWarningConfirm(sendAnyway: Bool) {
        NotificationCenter.default.post(.e2eiPrivacyWarningConfirm(sendAnyway: sendAnyway))
    }

    // add object in charge to present e2eiPrivacyWarningAlert
    static func addPresenter(_ observer: E2EIPrivacyWarningPresenter) -> SelfUnregisteringNotificationCenterToken {
        let token = NotificationCenter.default.addObserver(forName: .presentE2EIPrivacyWarningAlert,
                                               object: nil,
                                               queue: .main) { [weak observer] note in
            observer?.presentE2EIPrivacyWarningAlert(note)
        }

        return SelfUnregisteringNotificationCenterToken(token)
    }
}

private extension Notification.Name {
    static let presentE2EIPrivacyWarningAlert = Notification.Name("presentE2EIPrivacyWarningAlert")
    static let e2eiPrivacyWarningConfirm = Notification.Name("e2eiPrivacyWarningConfirm")
}

private extension Notification {
    var sendAnyway: Bool {
        get {
            userInfo?["sendAnyway"] as? Bool ?? false
        }
        set {
            userInfo?["sendAnyway"] = newValue
        }
    }
}

extension Notification {

    var alertType: E2EIPrivacyWarningChecker.AlertType? {
        userInfo?["alertType"] as? E2EIPrivacyWarningChecker.AlertType
    }
}

private extension Notification {

    static func e2eiPrivacyWarningConfirm(sendAnyway: Bool) -> Notification {
        Notification(name: .e2eiPrivacyWarningConfirm, object: nil, userInfo: ["sendAnyway": sendAnyway])
    }

    static func presentE2EIPrivacyWarningAlert(type: E2EIPrivacyWarningChecker.AlertType) -> Notification {
        Notification(name: .presentE2EIPrivacyWarningAlert, object: nil, userInfo: ["alertType": type])
    }
}
