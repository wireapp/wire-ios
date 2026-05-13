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

struct GiphyConfirmationViewModel {

    struct ButtonState: Equatable {
        let title: String
        let isEnabled: Bool
    }

    struct DisplayState: Equatable {
        let previewImageData: Data?
        let confirmButton: ButtonState
        let cancelButton: ButtonState
        let closeAccessibilityLabel: String
    }

    enum Action: Equatable {
        case open
        case imageFetchSucceeded(Data)
        case imageFetchFailed
        case confirmTapped
        case cancelTapped
        case closeTapped
    }

    enum Route: Equatable {
        case confirm(Data)
        case pop
        case dismiss
        case none
    }

    enum Effect: Equatable {
        case fetchImage
        case none
    }

    private let canFetchImage: Bool

    private(set) var displayState: DisplayState

    init(canFetchImage: Bool) {
        self.canFetchImage = canFetchImage
        self.displayState = DisplayState(
            previewImageData: nil,
            confirmButton: ButtonState(
                title: L10n.Localizable.Giphy.confirm.capitalized,
                isEnabled: false
            ),
            cancelButton: ButtonState(
                title: L10n.Localizable.Giphy.cancel.capitalized,
                isEnabled: true
            ),
            closeAccessibilityLabel: L10n.Localizable.General.close
        )
    }

    mutating func effect(for action: Action) -> Effect {
        switch action {
        case .open:
            return canFetchImage ? .fetchImage : .none
        case let .imageFetchSucceeded(imageData):
            displayState = DisplayState(
                previewImageData: imageData,
                confirmButton: ButtonState(
                    title: displayState.confirmButton.title,
                    isEnabled: true
                ),
                cancelButton: displayState.cancelButton,
                closeAccessibilityLabel: displayState.closeAccessibilityLabel
            )

            return .none
        case .imageFetchFailed:
            return .none
        case .confirmTapped, .cancelTapped, .closeTapped:
            return .none
        }
    }

    func route(for action: Action) -> Route {
        switch action {
        case .confirmTapped:
            guard let imageData = displayState.previewImageData else { return .none }

            return .confirm(imageData)
        case .cancelTapped:
            return .pop
        case .closeTapped:
            return .dismiss
        case .open, .imageFetchSucceeded, .imageFetchFailed:
            return .none
        }
    }

}
