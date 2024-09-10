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

extension UserType where Self: SelfLegalHoldSubject {
    /**
     * Creates the password input request to respond to a legal hold activation request from the team admin.
     * - parameter request: The legal hold request that the user received.
     * - parameter cancellationHandler: The block to execute when the user ignores the legal hold request.
     * - parameter inputHandler: The block to execute with the password of the user.
     * - note: If the user dismisses the alert, we will make the legal hold request as acknowledged.
     */
    func makeLegalHoldInputRequest(with fingerprint: String, cancellationHandler: @escaping () -> Void, inputHandler: @escaping (String?) -> Void) -> UserInputRequest {
        let fingerprintString = fingerprint.fingerprintStringWithSpaces

        var legalHoldMessage = L10n.Localizable.LegalholdRequest.Alert.detail(fingerprintString)

        var inputConfiguration: UserInputRequest.InputConfiguration?

        if !usesCompanyLogin {
            inputConfiguration = UserInputRequest.InputConfiguration(
                placeholder: L10n.Localizable.Password.placeholder,
                prefilledText: nil,
                isSecure: true,
                textContentType: .password,
                accessibilityIdentifier: "legalhold-request-password-input",
                validator: { !$0.isEmpty }
            )

            legalHoldMessage += "\n"
            legalHoldMessage += L10n.Localizable.LegalholdRequest.Alert.Detail.enterPassword
        }

        return UserInputRequest(
            title: L10n.Localizable.LegalholdRequest.Alert.title,
            message: legalHoldMessage,
            continueActionTitle: L10n.Localizable.General.accept,
            cancelActionTitle: L10n.Localizable.General.skip,
            inputConfiguration: inputConfiguration,
            completionHandler: inputHandler,
            cancellationHandler: cancellationHandler
        )
    }
}
