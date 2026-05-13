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
import WireLocators

struct AddParticipantsViewModel {
    struct SelectionOverflowAlertContent {
        let title: String
        let message: String
        let buttonTitle: String
    }

    struct ConfirmButtonState {
        let isVisible: Bool
        let title: String?
        let isEnabled: Bool
    }

    struct SearchGroupSelectionState {
        let clearsInput: Bool
        let isConfirmButtonVisible: Bool
    }

    struct SearchState {
        enum Action {
            case searchApps(String)
            case searchBots(String)
            case listPeople
            case searchPeople(String)
        }

        let action: Action
        let mode: SearchResultsViewControllerMode
        let isSearchingForBots: Bool
        let hasFilter: Bool
        let showsEmptyAppsPlaceholder: Bool
    }

    struct RightNavigationItemState {
        enum Style {
            case close
            case text(String)
        }

        let style: Style
        let accessibilityIdentifier: String
    }

    enum RightNavigationAction {
        case dismiss
        case createConversation
    }

    enum ConfirmAction {
        case addParticipants(GroupDetailsConversationType)
    }

    let context: AddParticipantsViewController.Context
    let isAppsFeatureEnabled: Bool
    let areLegacyBotsAvailable: Bool

    init(
        context: AddParticipantsViewController.Context,
        isAppsFeatureEnabled: Bool,
        areLegacyBotsAvailable: Bool
    ) {
        self.context = context
        self.isAppsFeatureEnabled = isAppsFeatureEnabled
        self.areLegacyBotsAvailable = areLegacyBotsAvailable
    }

    var botCanBeAdded: Bool { // TODO: [WPB-20362] apps vs bots?
        switch context {
        case .create:
            return false
        case let .add(conversation):
            guard conversation.botCanBeAdded else { return false }

            switch conversation.messageProtocol {
            case .mls where isAppsFeatureEnabled:
                return conversation.allowApps
            case .proteus where areLegacyBotsAvailable:
                return conversation.allowApps
            default:
                return false
            }
        }
    }

    var selectedUsers: UserSet {
        switch context {
        case let .add(conversation) where conversation.conversationType == .oneOnOne:
            conversation.connectedUserType.map { [$0] } ?? []
        case let .create(values): values.participants
        default: []
        }
    }

    var includeGuests: Bool {
        switch context {
        case let .add(conversation):
            conversation.canAddGuest
        case let .create(creationValues):
            creationValues.allowGuests
        }
    }

    var selectionLimit: Int {
        switch context {
        case let .add(conversation):
            conversation.freeParticipantSlots
        case let .create(context):
            ZMConversation
                .maxParticipantsExcludingSelf(isChannel: context.isChannel)
        }
    }

    var selectionOverflowAlertContent: SelectionOverflowAlertContent {
        typealias AddParticipantsAlert = L10n.Localizable.AddParticipants.Alert
        let message: String
        switch context {
        case let .add(conversation):
            let freeSpace = conversation.freeParticipantSlots
            let max = ZMConversation.getMaxParticipants(isChannel: conversation.isChannel)
            message = AddParticipantsAlert.Message
                .existingConversation(
                    max.formatted(.number),
                    freeSpace.formatted(.number)
                )
        case let .create(context):
            message = AddParticipantsAlert.Message
                .newConversation(ZMConversation.getMaxParticipants(isChannel: context.isChannel).formatted(.number))
        }

        return SelectionOverflowAlertContent(
            title: AddParticipantsAlert.title.capitalized,
            message: message,
            buttonTitle: L10n.Localizable.General.ok
        )
    }

    private func title(selectedUsers: UserSet) -> String {
        selectedUsers.isEmpty
            ? L10n.Localizable.Peoplepicker.Group.Title.singular.capitalized
            : L10n.Localizable.Peoplepicker.Group.Title.plural(selectedUsers.count).capitalized
    }

    func navigationTitle(currentSelectedUsers: UserSet) -> String {
        switch context {
        case let .create(values):
            title(selectedUsers: values.participants)
        case .add:
            title(selectedUsers: currentSelectedUsers)
        }
    }

    var filterConversation: ZMConversation? {
        switch context {
        case let .add(conversation) where conversation.conversationType == .group: conversation as? ZMConversation
        default: nil
        }
    }

    var showsConfirmButton: Bool {
        switch context {
        case .add: true
        case .create: false
        }
    }

    var confirmButtonTitle: String? {
        switch context {
        case .create: nil
        case let .add(conversation):
            if conversation.conversationType == .oneOnOne {
                L10n.Localizable.Peoplepicker.Button.createConversation.capitalized
            } else {
                L10n.Localizable.Peoplepicker.Button.addToConversation.capitalized
            }
        }
    }

    func confirmButtonState(selectedUsers: UserSet, searchGroup: SearchGroup = .people) -> ConfirmButtonState {
        guard searchGroup != .apps, showsConfirmButton else {
            return ConfirmButtonState(isVisible: false, title: nil, isEnabled: false)
        }

        return ConfirmButtonState(
            isVisible: true,
            title: confirmButtonTitle,
            isEnabled: !selectedUsers.isEmpty
        )
    }

    func stateForSelectedUsers(_ selectedUsers: UserSet, defaultProtocol: MessageProtocol, selfUser: UserType) -> AddParticipantsViewModel {
        guard case let .create(values) = context else {
            return self
        }

        let updated = ConversationCreationValues(
            isChannel: values.isChannel,
            isAppsFeatureEnabled: values.isAppsFeatureEnabled,
            areLegacyBotsAvailable: values.areLegacyBotsAvailable,
            name: values.name,
            participants: selectedUsers,
            allowGuests: values.allowGuests,
            allowApps: values.allowApps,
            enableReceipts: values.enableReceipts,
            enableFileManagement: values.enableFileManagement,
            encryptionProtocol: defaultProtocol,
            selfUser: selfUser
        )
        updated.channelHistoryDepth = values.channelHistoryDepth

        return AddParticipantsViewModel(
            context: .create(updated),
            isAppsFeatureEnabled: values.isAppsFeatureEnabled,
            areLegacyBotsAvailable: values.areLegacyBotsAvailable
        )
    }

    func stateForSelectingSearchGroup(_ group: SearchGroup, selectedUsers: UserSet) -> SearchGroupSelectionState {
        SearchGroupSelectionState(
            clearsInput: group == .apps,
            isConfirmButtonVisible: confirmButtonState(selectedUsers: selectedUsers, searchGroup: group).isVisible
        )
    }

    func searchState(searchGroup: SearchGroup, query: String) -> SearchState {
        let searchingForBots = [.apps, .bots].contains(searchGroup)
        let hasFilter = !query.isEmpty
        let action: SearchState.Action
        let mode: SearchResultsViewControllerMode

        switch (searchGroup, hasFilter) {
        case (.apps, _):
            action = .searchApps(query)
            mode = .search
        case (.bots, _):
            action = .searchBots(query)
            mode = .search
        case (.people, false):
            action = .listPeople
            mode = .list
        case (.people, true):
            action = .searchPeople(query)
            mode = .search
        }

        return SearchState(
            action: action,
            mode: mode,
            isSearchingForBots: searchingForBots,
            hasFilter: hasFilter,
            showsEmptyAppsPlaceholder: searchGroup == .apps && !hasFilter
        )
    }

    var rightNavigationItemState: RightNavigationItemState {
        switch context {
        case .add:
            return RightNavigationItemState(
                style: .close,
                accessibilityIdentifier: Locators.ConversationDetailsPage.close.rawValue
            )
        case let .create(values):
            let key = values.participants.isEmpty ? L10n.Localizable.Peoplepicker.Group.skip : L10n.Localizable
                .Peoplepicker.Group.done
            let accessibilityIdentifier = values.participants
                .isEmpty ? Locators.SelectParticipantsPage.skip.rawValue : Locators.SelectParticipantsPage.done.rawValue

            return RightNavigationItemState(
                style: .text(key),
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }

    var rightNavigationAction: RightNavigationAction {
        switch context {
        case .add:
            return .dismiss
        case .create:
            return .createConversation
        }
    }

    var confirmAction: ConfirmAction? {
        switch context {
        case let .add(conversation):
            return .addParticipants(conversation)
        case .create:
            return nil
        }
    }

}
