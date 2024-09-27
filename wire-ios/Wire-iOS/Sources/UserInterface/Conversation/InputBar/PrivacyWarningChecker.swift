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

// MARK: - PrivacyWarningPresenter

protocol PrivacyWarningPresenter: AnyObject {
    func presentPrivacyWarningAlert(_ notification: Notification)
}

// MARK: - PrivacyWarningChecker

// Checks if PrivacyWarningAlert needs to be presented before given action
struct PrivacyWarningChecker {
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

    // Notifies all MLSConversationChecker about user's choice following e2eiPrivacyWarningAlert
    static func privacyWarningConfirm(sendAnyway: Bool) {
        NotificationCenter.default.post(.privacyWarningConfirm(sendAnyway: sendAnyway))
    }

    // add object in charge to present e2eiPrivacyWarningAlert
    static func addPresenter(_ observer: PrivacyWarningPresenter) -> SelfUnregisteringNotificationCenterToken {
        let token = NotificationCenter.default.addObserver(
            forName: .presentPrivacyWarningAlert,
            object: nil,
            queue: .main
        ) { [weak observer] note in
            observer?.presentPrivacyWarningAlert(note)
        }

        return SelfUnregisteringNotificationCenterToken(token)
    }

    func performAction() {
        guard conversation.isMLSConversationDegraded || conversation.isProteusConversationDegraded else {
            continueAction()
            return
        }

        if let showAlert {
            showAlert()
        } else {
            NotificationCenter.default.post(.presentPrivacyWarningAlert(type: alertType))
        }

        Task {
            var shouldContinue = false
            for await notification in NotificationCenter.default.notifications(named: .privacyWarningConfirm) {
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
}

extension Notification.Name {
    fileprivate static let presentPrivacyWarningAlert = Notification.Name("presentPrivacyWarningAlert")
    fileprivate static let privacyWarningConfirm = Notification.Name("privacyWarningConfirm")
}

extension Notification {
    fileprivate var sendAnyway: Bool {
        get {
            userInfo?["sendAnyway"] as? Bool ?? false
        }
        set {
            userInfo?["sendAnyway"] = newValue
        }
    }
}

extension Notification {
    var alertType: PrivacyWarningChecker.AlertType? {
        userInfo?["alertType"] as? PrivacyWarningChecker.AlertType
    }
}

extension Notification {
    fileprivate static func privacyWarningConfirm(sendAnyway: Bool) -> Notification {
        Notification(name: .privacyWarningConfirm, object: nil, userInfo: ["sendAnyway": sendAnyway])
    }

    fileprivate static func presentPrivacyWarningAlert(type: PrivacyWarningChecker.AlertType) -> Notification {
        Notification(name: .presentPrivacyWarningAlert, object: nil, userInfo: ["alertType": type])
    }
}
