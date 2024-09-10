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

/**
 * An object that coordinates disclosing the legal hold state to the user.
 */

final class LegalHoldDisclosureController: UserObserving {

    enum DisclosureState: Equatable {
        /// No legal hold status is being disclosed.
        case none

        /// The user is being warned about a pending legal hold alert.
        case warningAboutPendingRequest(LegalHoldRequest, String)

        /// The user is waiting for the response on the legal hold acceptation.
        case acceptingRequest

        /// The user is being warned about the result of accepting legal hold.
        case warningAboutAcceptationResult(UIAlertController)

        /// The user is being warned about the deactivation of legal hold.
        case warningAboutDisabled

        /// The user is being warned about the activation of legal hold.
        case warningAboutEnabled
    }

    enum DisclosureCause {
        /// We need to disclose the state because the user opened the app.
        case appOpen

        /// We need to disclose the state because the user tapped a button.
        case userAction

        /// We need to disclose the state because we detected a remote change.
        case remoteUserChange
    }

    // MARK: - Properties

    /// The self user, that can become under legal hold.
    let selfUserLegalHoldSubject: any SelfUserLegalHoldable

    /// The block that presents view controllers when requested.
    let presenter: ViewControllerPresenter

    /// UIAlertController currently presented
    var presentedAlertController: UIAlertController?

    /// The current state of legal hold disclosure. Defaults to none.
    var currentState: DisclosureState = .none {
        didSet {
            guard currentState != oldValue else { return }
            presentAlertController(for: currentState)
        }
    }

    private var userObserverToken: Any?

    // MARK: - Initialization

    init(
        selfUserLegalHoldSubject: SelfUserLegalHoldable,
        userSession: UserSession,
        presenter: @escaping ViewControllerPresenter
    ) {
        self.selfUserLegalHoldSubject = selfUserLegalHoldSubject
        self.presenter = presenter

        configureObservers(userSession: userSession)
    }

    private func configureObservers(userSession: UserSession) {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        userObserverToken = userSession.addUserObserver(self, for: selfUserLegalHoldSubject)
    }

    // MARK: - Notifications

    @objc private func applicationDidEnterForeground() {
        discloseCurrentState(cause: .appOpen)
    }

    // MARK: User Change

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.legalHoldStatusChanged else {
            return
        }

        discloseCurrentState(cause: .remoteUserChange)
    }

    // MARK: - Alerts

    /// Present the current legal hold state.
    func discloseCurrentState(cause: DisclosureCause) {
        switch selfUserLegalHoldSubject.legalHoldStatus {
        case .enabled:
            discloseEnabledStateIfPossible()

        case .pending(let request):
            disclosePendingRequestIfPossible(request)

        case .disabled:
            discloseDisabledStateIfPossible()
        }
    }

    /// Present an alert about legal hold being enabled.
    private func discloseEnabledStateIfPossible() {
        switch currentState {
        case .acceptingRequest, .warningAboutEnabled:
            // If we are already accepting the request or it's already accepted, do not show a popup
            return
        default:
            // If there is a current alert, replace it with the latest disclosure
            if selfUserLegalHoldSubject.needsToAcknowledgeLegalHoldStatus {
                currentState = .warningAboutEnabled
            }
        }
    }

    /// Present an alert about a pending legal hold request.
    private func disclosePendingRequestIfPossible(_ request: LegalHoldRequest) {
        // Do not present alert if we already in process of accepting the request
        if case .acceptingRequest = currentState { return }

        Task {
            let fingerprint = await selfUserLegalHoldSubject.fingerprint ?? "<fingerprint unavailable>"
            await MainActor.run(body: { currentState = .warningAboutPendingRequest(request, fingerprint) })
        }

        // If there is a current alert, replace it with the latest disclosure
    }

    private func discloseDisabledStateIfPossible() {
        switch currentState {
        case .warningAboutPendingRequest, .warningAboutAcceptationResult:
            currentState = .none
            return
        case .warningAboutDisabled:
            // If we are already warning about disabled, do nothing
            return
        default:
            break
        }

        // Do not show the alert for a remote change unless it requires attention
        if selfUserLegalHoldSubject.needsToAcknowledgeLegalHoldStatus {
            currentState = .warningAboutDisabled
        }
    }

    // MARK: - Helpers

    /// Dismisses the alert if it's presented, and calls the dismissal handler.
    private func dismissAlertIfNeeded(_ alert: UIAlertController?, dismissalHandler: @escaping () -> Void) {
        if let currentAlert = alert, currentAlert.presentingViewController != nil {
            currentAlert.dismiss(animated: true, completion: dismissalHandler)
        } else {
            dismissalHandler()
        }
    }

    /// Operator to assign the new state from a block parameter.
    private func assignState(_ newValue: DisclosureState) {
        currentState = newValue
    }

    private func presentAlertController(for state: DisclosureState) {
        var alertController: UIAlertController?

        switch state {
        case .warningAboutDisabled:
            alertController = LegalHoldAlertFactory.makeLegalHoldDeactivatedAlert(for: selfUserLegalHoldSubject, suggestedStateChangeHandler: assignState)
        case .warningAboutEnabled:
            alertController = LegalHoldAlertFactory.makeLegalHoldActivatedAlert(for: selfUserLegalHoldSubject, suggestedStateChangeHandler: assignState)
        case .warningAboutPendingRequest(let request, let fingerprint):
            alertController = LegalHoldAlertFactory.makeLegalHoldActivationAlert(
                for: request,
                fingerprint: fingerprint,
                user: selfUserLegalHoldSubject,
                suggestedStateChangeHandler: assignState
            )
        case .warningAboutAcceptationResult(let alert):
            alertController = alert
        case .acceptingRequest, .none:
            break
        }

        dismissAlertIfNeeded(presentedAlertController) {
            if let alertController {
                self.presentedAlertController = alertController
                self.presenter(alertController, true, nil)
            } else {
                self.presentedAlertController = nil
            }
        }
    }
}
