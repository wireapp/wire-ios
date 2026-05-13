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

import WireDataModel

final class ConversationNotificationOptionsViewModel {

    struct State: Equatable {
        let options: [Option]
        let footerDescription: String
    }

    struct Option: Equatable {
        let value: MutedMessageTypes
        let title: String?
        let isSelected: Bool
    }

    enum Action: Equatable {
        case none
        case update(MutedMessageTypes)
    }

    private let optionValues: [MutedMessageTypes] = [.none, .regular, .all]
    private var currentSelection: MutedMessageTypes

    var state: State {
        State(
            options: optionValues.map {
                Option(
                    value: $0,
                    title: $0.localizationKey,
                    isSelected: $0 == currentSelection
                )
            },
            footerDescription: L10n.Localizable.GroupDetails.NotificationOptionsCell.description
        )
    }

    init(currentSelection: MutedMessageTypes) {
        self.currentSelection = currentSelection
    }

    func option(at index: Int) -> Option {
        state.options[index]
    }

    func updateCurrentSelection(_ currentSelection: MutedMessageTypes) {
        self.currentSelection = currentSelection
    }

    func actionForSelection(at index: Int) -> Action {
        guard state.options.indices.contains(index) else {
            return .none
        }

        let selectedOption = optionValues[index]
        guard selectedOption != currentSelection else {
            return .none
        }

        return .update(selectedOption)
    }
}

extension MutedMessageTypes {

    var localizationKey: String? {
        switch self {
        case .none:         L10n.Localizable.Meta.Menu.ConfigureNotification.buttonEverything
        case .regular:      L10n.Localizable.Meta.Menu.ConfigureNotification.buttonMentionsAndReplies
        case .all:          L10n.Localizable.Meta.Menu.ConfigureNotification.buttonNothing
        default:            nil
        }
    }
}
