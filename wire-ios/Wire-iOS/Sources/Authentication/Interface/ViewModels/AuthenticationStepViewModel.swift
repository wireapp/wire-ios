//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class AuthenticationStepViewModel {

    // MARK: - Types

    struct DisplayState {
        let validationMessage: String?
        let validationAccessibilityIdentifier: String?
        let validationMessageStyle: ValidationMessageStyle?
        let isValidationMessageHidden: Bool
        let secondaryErrorDescription: ViewDescriptor?
        let shouldAnnounceValidationMessage: Bool
    }

    enum ValidationMessageStyle: Equatable {
        case info
        case error
    }

    // MARK: - Properties

    private let initialValidation: ValueValidation?
    private weak var secondaryView: AuthenticationSecondaryViewDescription?

    // MARK: - Initialization

    init(
        initialValidation: ValueValidation?,
        secondaryView: AuthenticationSecondaryViewDescription?
    ) {
        self.initialValidation = initialValidation
        self.secondaryView = secondaryView
    }

    // MARK: - Methods

    func displayState(for suggestedValidation: ValueValidation?) -> DisplayState {
        displayState(
            for: suggestedValidation,
            fallbackToInitialValidation: true,
            shouldAnnounceValidationMessage: suggestedValidation?.isError == true
        )
    }

    private func displayState(
        for suggestedValidation: ValueValidation?,
        fallbackToInitialValidation: Bool,
        shouldAnnounceValidationMessage: Bool
    ) -> DisplayState {
        switch suggestedValidation {
        case let .info(infoText)?:
            return DisplayState(
                validationMessage: infoText,
                validationAccessibilityIdentifier: "validation-rules",
                validationMessageStyle: .info,
                isValidationMessageHidden: false,
                secondaryErrorDescription: nil,
                shouldAnnounceValidationMessage: shouldAnnounceValidationMessage
            )

        case let .error(error, showVisualFeedback)?:
            guard showVisualFeedback else {
                return fallbackToInitialValidation
                    ? displayState(
                        for: initialValidation,
                        fallbackToInitialValidation: false,
                        shouldAnnounceValidationMessage: shouldAnnounceValidationMessage
                    )
                    : hiddenDisplayState(shouldAnnounceValidationMessage: shouldAnnounceValidationMessage)
            }

            return DisplayState(
                validationMessage: error.errorDescription,
                validationAccessibilityIdentifier: "validation-failure",
                validationMessageStyle: .error,
                isValidationMessageHidden: false,
                secondaryErrorDescription: secondaryView?.display(on: error),
                shouldAnnounceValidationMessage: shouldAnnounceValidationMessage
            )

        case nil:
            return hiddenDisplayState(shouldAnnounceValidationMessage: shouldAnnounceValidationMessage)
        }
    }

    private func hiddenDisplayState(shouldAnnounceValidationMessage: Bool) -> DisplayState {
        DisplayState(
            validationMessage: nil,
            validationAccessibilityIdentifier: nil,
            validationMessageStyle: nil,
            isValidationMessageHidden: true,
            secondaryErrorDescription: nil,
            shouldAnnounceValidationMessage: shouldAnnounceValidationMessage
        )
    }
}

private extension ValueValidation {

    var isError: Bool {
        guard case .error = self else {
            return false
        }
        return true
    }
}
