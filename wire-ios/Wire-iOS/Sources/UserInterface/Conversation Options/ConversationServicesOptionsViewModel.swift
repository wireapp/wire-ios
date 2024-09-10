//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
    var allowServices: Bool { get }
    var areServicePresent: Bool { get }
    var allowServicesChangedHandler: ((Bool) -> Void)? { get set }
    func setAllowServices(_ allowServices: Bool, completion: @escaping (Result<Void, Error>) -> Void)
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

        configuration.allowServicesChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }

    private func updateRows() {
        state.rows = [.allowServicesToggle(
            get: { [unowned self] in return self.configuration.allowServices },
            set: { [unowned self] in self.setAllowServices($0, sender: $1) }
        )]
    }

    /// set conversation option AllowServices
    /// - Parameters:
    ///   - allowServices: new state AllowServices
    ///   - sender: the source view which triggers setAllowServices action
    /// - Returns: alert controller
    @discardableResult func setAllowServices(
        _ allowServices: Bool,
        sender: UIView
    ) -> UIAlertController? {
        func _setAllowServices() {
            let item = CancelableItem(delay: 0.4) { [weak self] in
                self?.state.isLoading = true
            }

            configuration.setAllowServices(allowServices) { [weak self] result in
                guard let self else { return }
                item.cancel()
                self.state.isLoading = false

                switch result {
                case .success:
                    self.updateRows()
                case let .failure(error):
                    self.delegate?.conversationServicesOptionsViewModel(self, didReceiveError: error)
                }
            }
        }

        guard allowServices != configuration.allowServices else { return nil }

        // In case allow services mode should be deactivated & service in conversation, ask the delegate
        // to confirm this action as all services will be removed.
        if !allowServices, configuration.areServicePresent {
            // Make "remove services" warning only appear if services are present
            return delegate?.conversationServicesOptionsViewModel(
                self,
                fallbackActivityPopoverConfiguration: .sourceView(
                    sourceView: sender.superview!,
                    sourceRect: sender.frame.insetBy(dx: -4, dy: -4)
                )
            ) { [weak self] remove in
                guard let self else { return }

                guard remove else { return self.updateRows() }
                _setAllowServices()
            }
        } else {
            _setAllowServices()
        }

        return nil
    }
}
