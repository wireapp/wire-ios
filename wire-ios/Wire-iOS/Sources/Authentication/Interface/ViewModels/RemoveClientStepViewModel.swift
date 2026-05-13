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

import CoreGraphics

final class RemoveClientStepViewModel {

    // MARK: - Types

    struct DisplayState: Equatable {
        let navigationTitle: String
        let regularContentWidth: CGFloat
        let showsCancelButton: Bool
        let isCancelButtonEnabled: Bool
    }

    enum Action {
        case continueAfterRemovingClient
        case showRemovalError(Error)
    }

    enum Route: Equatable {
        case cancel
    }

    // MARK: - Methods

    func displayState(canCancel: Bool) -> DisplayState {
        DisplayState(
            navigationTitle: L10n.Localizable.Registration.Signin.TooManyDevices.ManageScreen.title,
            regularContentWidth: 375,
            showsCancelButton: canCancel,
            isCancelButtonEnabled: canCancel
        )
    }

    func routeForCancelTapped() -> Route {
        .cancel
    }

    func actionForFinishedDeleting() -> Action {
        .continueAfterRemovingClient
    }

    func actionForFailedToDeleteClients(_ error: Error) -> Action {
        .showRemovalError(error)
    }
}
