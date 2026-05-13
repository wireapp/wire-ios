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

protocol ConversationServicesOptionsViewModelConfiguration: AnyObject {

    var messageProtocol: MessageProtocol { get }

    /// `true` if at least one bot is whitelisted for the team.

    var areLegacyBotsAvailable: Bool { get }

    /// `true` if the team is able to use apps (feature flag enabled), `false` for individual users or free teams.

    var isAppsFeatureEnabled: Bool { get }

    /// `true` if apps can be participants of the conversation, `false` otherwise.

    var allowApps: Bool { get }

    var areAppsPresent: Bool { get }
    var allowAppsChangedHandler: ((Bool) -> Void)? { get set }

}

protocol ConversationServicesOptionsViewModelDelegate: AnyObject {

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        didUpdateState state: ConversationServicesOptionsViewModel.State
    )

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        didReceiveError error: Error
    )

}

final class ConversationServicesOptionsViewModel {

    struct State: Equatable {
        let title: String
        let closeButtonAccessibilityLabel: String
        var rows: [Row]
        var isLoading: Bool
    }

    enum Row: Equatable {
        case appsDisabledHint(title: String, body: String)
        case allowAppsToggle(Toggle)
    }

    struct Toggle: Equatable {
        let title: String
        let subtitle: String
        let accessibilityIdentifier: String
        let titleAccessibilityIdentifier: String
        let isEnabled: Bool
        let isOn: Bool
    }

    enum Action: Equatable {
        case none
        case setAllowApps(Bool)
        case confirmRemovingServices(Bool)
    }

    private(set) var state: State {
        didSet {
            delegate?.conversationServicesOptionsViewModel(self, didUpdateState: state)
        }
    }

    weak var delegate: ConversationServicesOptionsViewModelDelegate?

    private let configuration: ConversationServicesOptionsViewModelConfiguration

    init(configuration: ConversationServicesOptionsViewModelConfiguration) {
        self.configuration = configuration
        self.state = State(
            title: L10n.Localizable.GroupDetails.AppsOptionsCell.title.capitalized,
            closeButtonAccessibilityLabel: L10n.Accessibility.ServiceConversationSettings.CloseButton.description,
            rows: ConversationServicesOptionsViewModel.makeRows(from: configuration),
            isLoading: false
        )

        configuration.allowAppsChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }

    private func updateRows() {
        state.rows = Self.makeRows(from: configuration)
    }

    private static func makeRows(from configuration: ConversationServicesOptionsViewModelConfiguration) -> [Row] {
        var showAppsNotEnabledHint = true

        if configuration.allowApps {
            // if apps are already enabled for the conversation, show the toggle
            showAppsNotEnabledHint = false
        } else if configuration.messageProtocol == .mls, configuration.isAppsFeatureEnabled {
            // for MLS conversations consider the apps feature flag
            showAppsNotEnabledHint = false
        } else if configuration.messageProtocol == .proteus, configuration.areLegacyBotsAvailable {
            // for Proteus conversations what matters is if bots are whitelisted for the team
            showAppsNotEnabledHint = false
        }

        if showAppsNotEnabledHint {
            return [
                .appsDisabledHint(
                    title: L10n.Localizable.Conversation.Create.AppsDisabled.title,
                    body: L10n.Localizable.Conversation.Create.AppsDisabled.message
                )
            ]
        } else {
            return [
                .allowAppsToggle(
                    Toggle(
                        title: L10n.Localizable.AppsOptions.AllowApps.title,
                        subtitle: L10n.Localizable.AppsOptions.AllowApps.subtitle,
                        accessibilityIdentifier: "toggle.guestoptions.allowapps",
                        titleAccessibilityIdentifier: "label.guestoptions.apps.description",
                        isEnabled: true,
                        isOn: configuration.allowApps
                    )
                )
            ]
        }

    }

    func actionForAllowAppsToggle(_ allowApps: Bool) -> Action {
        guard allowApps != configuration.allowApps else { return .none }

        if !allowApps, configuration.areAppsPresent {
            return .confirmRemovingServices(allowApps)
        }

        return .setAllowApps(allowApps)
    }

    func actionForRemovingServicesConfirmation(confirmed: Bool, allowApps: Bool) -> Action {
        guard confirmed else {
            updateRows()
            return .none
        }

        return .setAllowApps(allowApps)
    }

    func updateIsLoading(_ isLoading: Bool) {
        state.isLoading = isLoading
    }

    func applySetAllowAppsResult(_ result: Result<Void, Error>) {
        state.isLoading = false

        switch result {
        case .success:
            updateRows()
        case let .failure(error):
            delegate?.conversationServicesOptionsViewModel(self, didReceiveError: error)
        }
    }
}
