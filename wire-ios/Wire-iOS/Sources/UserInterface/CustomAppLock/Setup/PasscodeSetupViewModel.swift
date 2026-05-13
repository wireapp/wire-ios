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

import UIKit

struct PasscodeSetupViewModel {

    struct CreateButtonState: Equatable {
        let title: String
        let isEnabled: Bool
    }

    struct DisplayModel: Equatable {
        let title: String
        let info: String
        let passcodePlaceholder: String
        let createButton: CreateButtonState
        let useCompactLayout: Bool
    }

    let displayModel: DisplayModel

    init(
        context: PasscodeSetupViewController.Context,
        useCompactLayout: Bool?,
        windowHeight: CGFloat
    ) {
        displayModel = DisplayModel(
            title: Self.title(for: context),
            info: Self.info(for: context),
            passcodePlaceholder: L10n.Localizable.CreatePasscode.Textfield.placeholder,
            createButton: CreateButtonState(
                title: L10n.Localizable.CreatePasscode.CreateButton.title,
                isEnabled: false
            ),
            useCompactLayout: useCompactLayout ?? Self.shouldUseCompactLayout(windowHeight: windowHeight)
        )
    }

    func returnKeyType(isPasscodeValid: Bool) -> UIReturnKeyType {
        isPasscodeValid ? .done : .default
    }

    func shouldSubmitPasscode(isPasscodeValid: Bool) -> Bool {
        isPasscodeValid
    }

    private static func title(for context: PasscodeSetupViewController.Context) -> String {
        switch context {
        case .createPasscode:
            L10n.Localizable.CreatePasscode.titleLabel
        case .forcedForTeam:
            L10n.Localizable.WarningScreen.titleLabel
        }
    }

    private static func info(for context: PasscodeSetupViewController.Context) -> String {
        switch context {
        case .createPasscode:
            L10n.Localizable.CreatePasscode.infoLabel
        case .forcedForTeam:
            L10n.Localizable.WarningScreen.MainInfo.forcedApplock + "\n\n" + L10n.Localizable.CreatePasscode
                .infoLabelForcedApplock
        }
    }

    private static func shouldUseCompactLayout(windowHeight: CGFloat) -> Bool {
        windowHeight <= CGFloat.iPhone4Inch.height
    }
}

extension PasscodeSetupViewController {
    enum Context {
        case forcedForTeam
        case createPasscode
    }
}
