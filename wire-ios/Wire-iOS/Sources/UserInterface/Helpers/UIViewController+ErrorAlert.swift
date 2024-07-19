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
import WireSyncEngine

extension UIViewController {

    func showAlert(for error: LocalizedError, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(
            title: error.errorDescription,
            message: error.failureReason ?? L10n.Localizable.Error.User.unkownError,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel,
            handler: handler
        ))

        present(alert, animated: true)
    }

    func showAlert(for error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
        let nsError: NSError = error as NSError
        var message = ""

        if nsError.domain == ZMObjectValidationErrorDomain,
            let code: ZMManagedObjectValidationErrorCode = ZMManagedObjectValidationErrorCode(rawValue: nsError.code) {
            switch code {
            case .tooLong:
                message = L10n.Localizable.Error.Input.tooLong
            case .tooShort:
                message = L10n.Localizable.Error.Input.tooShort
            case .emailAddressIsInvalid:
                message = L10n.Localizable.Error.Email.invalid
            default:
                break
            }
        } else if nsError.domain == NSError.userSessionErrorDomain,
            let code = UserSessionErrorCode(rawValue: nsError.code) {
            switch code {
            case .noError:
                message = ""
            case .needsCredentials:
                message = L10n.Localizable.Error.User.needsCredentials
            case .domainBlocked:
                message = L10n.Localizable.Error.User.domainBlocked
            case .invalidCredentials:
                message = L10n.Localizable.Error.User.invalidCredentials
            case .accountIsPendingActivation:
                message = L10n.Localizable.Error.User.accountPendingActivation
            case .networkError:
                message = L10n.Localizable.Error.User.networkError
            case .emailIsAlreadyRegistered:
                message = L10n.Localizable.Error.User.emailIsTaken
            case .invalidEmailVerificationCode, .invalidActivationCode:
                message = L10n.Localizable.Error.User.verificationCodeInvalid
            case .registrationDidFailWithUnknownError:
                message = L10n.Localizable.Error.User.registrationUnknownError
            case .invalidEmail:
                message = L10n.Localizable.Error.Email.invalid
            case .requestIsAlreadyPending:
                 message = L10n.Localizable.Error.User.verificationCodeTooMany
            case .clientDeletedRemotely:
                message = L10n.Localizable.Error.User.deviceDeletedRemotely
            case .lastUserIdentityCantBeDeleted:
                message = L10n.Localizable.Error.User.lastIdentityCantBeDeleted
            case .accountSuspended:
                message = L10n.Localizable.Error.User.accountSuspended
            case .accountLimitReached:
                message = L10n.Localizable.Error.User.accountLimitReached
            case .unknownError:
                message = L10n.Localizable.Error.User.unkownError
            default:
                message = L10n.Localizable.Error.User.unkownError
            }
        } else {
            message = error.localizedDescription
        }

        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel,
            handler: handler
        ))

        present(alert, animated: true)
    }
}
