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

typealias ViewControllerPresenter = (UIViewController, Bool, (() -> Void)?) -> Void
typealias SuggestedStateChangeHandler = (LegalHoldDisclosureController.DisclosureState) -> Void

enum LegalHoldAlertFactory {

    static func makeLegalHoldDeactivatedAlert(
        for user: SelfUserLegalHoldable,
        suggestedStateChangeHandler: SuggestedStateChangeHandler?
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.LegalHold.Deactivated.title,
            message: L10n.Localizable.LegalHold.Deactivated.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel,
            handler: { _ in
                user.acceptLegalHoldChangeAlert()
                suggestedStateChangeHandler?(.none)
            }
        ))

        return alert
    }

    static func makeLegalHoldActivatedAlert(
        for user: SelfUserLegalHoldable,
        suggestedStateChangeHandler: SuggestedStateChangeHandler?
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.LegalholdActive.Alert.title,
            message: L10n.Localizable.LegalholdActive.Alert.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel,
            handler: { _ in
                user.acceptLegalHoldChangeAlert()
                suggestedStateChangeHandler?(.none)
            }
        ))

        return alert
    }

    static func makeLegalHoldActivationAlert(
        for legalHoldRequest: LegalHoldRequest,
        fingerprint: String,
        user: SelfUserLegalHoldable,
        suggestedStateChangeHandler: SuggestedStateChangeHandler?
    ) -> UIAlertController {

        func handleLegalHoldActivationResult(_ error: LegalHoldActivationError?) {

            switch error {
            case .invalidPassword?:
                user.acceptLegalHoldChangeAlert()

                let alert = UIAlertController(
                    title: L10n.Localizable.LegalholdRequest.Alert.errorWrongPassword,
                    message: L10n.Localizable.General.Failure.tryAgain,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: L10n.Localizable.General.ok,
                    style: .cancel,
                    handler: { _ in
                        suggestedStateChangeHandler?(.warningAboutPendingRequest(legalHoldRequest, fingerprint))
                    }
                ))

                suggestedStateChangeHandler?(.warningAboutAcceptationResult(alert))

            case .some:
                user.acceptLegalHoldChangeAlert()

                let alert = UIAlertController(
                    title: L10n.Localizable.General.failure,
                    message: L10n.Localizable.General.Failure.tryAgain,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: L10n.Localizable.General.ok,
                    style: .cancel,
                    handler: { _ in
                        suggestedStateChangeHandler?(.warningAboutPendingRequest(legalHoldRequest, fingerprint))
                    }
                ))

                suggestedStateChangeHandler?(.warningAboutAcceptationResult(alert))

            case .none:
                user.acceptLegalHoldChangeAlert()
                suggestedStateChangeHandler?(.none)
            }
        }

        let cancellationHandler = {
            user.acceptLegalHoldChangeAlert()
            suggestedStateChangeHandler?(.none)
        }

        let request = user.makeLegalHoldInputRequest(with: fingerprint, cancellationHandler: cancellationHandler) { password in

            suggestedStateChangeHandler?(.acceptingRequest)

            ZMUserSession.shared()?.accept(legalHoldRequest: legalHoldRequest, password: password) { error in
                handleLegalHoldActivationResult(error)
            }

        }
        return UIAlertController(inputRequest: request)
    }

}

// MARK: - SelfLegalHoldSubject + Accepting Alert

extension SelfLegalHoldSubject {

    fileprivate func acceptLegalHoldChangeAlert() {
        ZMUserSession.shared()?.perform {
            self.acknowledgeLegalHoldStatus()
        }
    }
}
