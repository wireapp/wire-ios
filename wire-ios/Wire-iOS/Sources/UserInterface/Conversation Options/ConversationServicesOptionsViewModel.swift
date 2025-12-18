//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireUtilities

protocol ConversationServicesOptionsViewModelConfiguration: AnyObject {

    /// `true` if at least one bot is whitelisted for the team.

    var areLegacyBotsAvailable: Bool { get }

    /// `true` if the team is able to use apps (feature flag enabled), `false` for individual users or free teams.

    var isAppsFeatureEnabled: Bool { get }

    /// `true` if apps can be participants of the conversation, `false` otherwise.

    var allowApps: Bool { get }

    var areAppsPresent: Bool { get }
    var allowAppsChangedHandler: ((Bool) -> Void)? { get set }

    func setAllowApps(_ allowApps: Bool, completion: @escaping (Result<Void, Error>) -> Void)

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

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration,
        confirmRemovingServices completion: @escaping (Bool) -> Void
    ) -> UIAlertController?

}

final class ConversationServicesOptionsViewModel {
    struct State {
        var rows = [CellConfiguration]()
        var isLoading = false
    }

    var state = State() {
        didSet {
            delegate?.conversationServicesOptionsViewModel(self, didUpdateState: state)
        }
    }

    weak var delegate: ConversationServicesOptionsViewModelDelegate?

    private let configuration: ConversationServicesOptionsViewModelConfiguration

    init(configuration: ConversationServicesOptionsViewModelConfiguration) {
        self.configuration = configuration
        updateRows()

        configuration.allowAppsChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }

    private func updateRows() {
        if configuration.isAppsFeatureEnabled || configuration.areLegacyBotsAvailable || configuration.allowApps {
            state.rows = [.allowAppsToggle(
                get: { [unowned self] in return configuration.allowApps },
                set: { [unowned self] in setAllowApps($0, sender: $1) }
            )]
        } else {
            state.rows = [
                .titleAndBody(
                    title: L10n.Localizable.Conversation.Create.AppsDisabled.title,
                    body: L10n.Localizable.Conversation.Create.AppsDisabled.message
                )
            ]
        }
    }

    /// set conversation option AllowApps
    /// - Parameters:
    ///   - allowApps: new state AllowApps
    ///   - sender: the source view which triggers setAllowApps action
    /// - Returns: alert controller
    @discardableResult
    func setAllowApps(
        _ allowApps: Bool,
        sender: UIView
    ) -> UIAlertController? {
        func _setAllowApps() {
            let item = CancelableItem(delay: 0.4) { [weak self] in
                self?.state.isLoading = true
            }

            configuration.setAllowApps(allowApps) { [weak self] result in
                guard let self else { return }
                item.cancel()
                state.isLoading = false

                switch result {
                case .success:
                    updateRows()
                case let .failure(error):
                    delegate?.conversationServicesOptionsViewModel(self, didReceiveError: error)
                }
            }
        }

        guard allowApps != configuration.allowApps else { return nil }

        // In case allow services mode should be deactivated & service in conversation, ask the delegate
        // to confirm this action as all services will be removed.
        if !allowApps, configuration.areAppsPresent {
            // Make "remove services" warning only appear if services are present
            return delegate?.conversationServicesOptionsViewModel(
                self,
                fallbackActivityPopoverConfiguration: .sourceView(
                    sourceView: sender.superview!,
                    sourceRect: sender.frame.insetBy(dx: -4, dy: -4)
                )
            ) { [weak self] remove in
                guard let self else { return }

                guard remove else { return updateRows() }
                _setAllowApps()
            }
        } else {
            _setAllowApps()
        }

        return nil
    }
}
