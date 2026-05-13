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
import WireDataModel

final class ConversationTimeoutOptionsViewModel {

    struct Option: Equatable {
        let value: MessageDestructionTimeoutValue
        let title: String?
        let isEnabled: Bool
        let isSelected: Bool
    }

    struct State: Equatable {
        let title: String
        let closeButtonAccessibilityLabel: String
        let connectionErrorTitle: String
        let connectionErrorMessage: String
        let options: [Option]
    }

    private let supportedValues: [MessageDestructionTimeoutValue]
    private var currentValue: MessageDestructionTimeoutValue

    init(
        currentValue: MessageDestructionTimeoutValue,
        supportedValues: [MessageDestructionTimeoutValue] = MessageDestructionTimeoutValue.all
    ) {
        self.currentValue = currentValue
        self.supportedValues = supportedValues
    }

    var state: State {
        State(
            title: L10n.Localizable.GroupDetails.TimeoutOptionsCell.title.capitalized,
            closeButtonAccessibilityLabel:
                L10n.Accessibility.SelfDeletingMessagesConversationSettings.CloseButton.description,
            connectionErrorTitle: L10n.Localizable.GuestRoom.Error.Generic.title,
            connectionErrorMessage: L10n.Localizable.GuestRoom.Error.Generic.message,
            options: options
        )
    }

    func updateCurrentValue(_ currentValue: MessageDestructionTimeoutValue) {
        self.currentValue = currentValue
    }

    func timeoutToSave(forOptionAt index: Int) -> MessageDestructionTimeoutValue? {
        guard options.indices.contains(index) else {
            return nil
        }

        let option = options[index]
        guard option.isEnabled, option.value != currentValue else {
            return nil
        }

        return option.value
    }

    private var options: [Option] {
        var values = supportedValues.map { option(for: $0, isEnabled: true) }

        if case .custom = currentValue, !supportedValues.contains(currentValue) {
            values.append(option(for: currentValue, isEnabled: false))
        }

        return values
    }

    private func option(for value: MessageDestructionTimeoutValue, isEnabled: Bool) -> Option {
        Option(
            value: value,
            title: value.displayString,
            isEnabled: isEnabled,
            isSelected: value == currentValue
        )
    }
}
