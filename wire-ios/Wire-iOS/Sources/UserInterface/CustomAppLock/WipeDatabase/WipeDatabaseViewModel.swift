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

struct WipeDatabaseViewModel {

    struct ButtonState: Equatable {
        let title: String
        let isEnabled: Bool
    }

    struct ConfirmationState: Equatable {
        let expectedInput: String
        let isConfirmEnabled: Bool
    }

    struct DisplayModel: Equatable {
        let title: String
        let info: String
        let highlightedInfo: String
        let confirmButton: ButtonState
    }

    enum Action: Equatable {
        case confirmTapped
        case confirmationInputChanged(String?)
        case confirmationSubmitted(String?)
        case confirmationCancelled
        case confirmationFailed
    }

    enum Route: Equatable {
        case presentConfirmation
        case wipeDatabase
        case cancel
        case none
    }

    let displayModel = DisplayModel(
        title: L10n.Localizable.WipeDatabase.titleLabel,
        info: L10n.Localizable.WipeDatabase.infoLabel,
        highlightedInfo: L10n.Localizable.WipeDatabase.InfoLabel.highlighted,
        confirmButton: ButtonState(
            title: L10n.Localizable.WipeDatabase.Button.title,
            isEnabled: true
        )
    )

    func confirmationState(for input: String?) -> ConfirmationState {
        let expectedInput = L10n.Localizable.WipeDatabase.Alert.confirmInput

        return ConfirmationState(
            expectedInput: expectedInput,
            isConfirmEnabled: input == expectedInput
        )
    }

    func route(for action: Action) -> Route {
        switch action {
        case .confirmTapped:
            return .presentConfirmation
        case .confirmationInputChanged:
            return .none
        case let .confirmationSubmitted(input):
            guard input != nil else { return .cancel }

            return confirmationState(for: input).isConfirmEnabled ? .wipeDatabase : .none
        case .confirmationCancelled:
            return .cancel
        case .confirmationFailed:
            return .none
        }
    }

}
