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
import WireSyncEngine
import WireTransport
import WireUtilities

// MARK: - ConversationGuestOptionsViewModelConfiguration

protocol ConversationGuestOptionsViewModelConfiguration: AnyObject {
    var allowGuests: Bool { get }
    var guestLinkFeatureStatus: GuestLinkFeatureStatus { get }
    var isCodeEnabled: Bool { get }
    var areGuestPresent: Bool { get }
    var isConversationFromSelfTeam: Bool { get }
    var allowGuestsChangedHandler: ((Bool) -> Void)? { get set }
    var guestLinkFeatureStatusChangedHandler: ((GuestLinkFeatureStatus) -> Void)? { get set }
    func setAllowGuests(_ allowGuests: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchConversationLink(completion: @escaping (Result<(uri: String?, secured: Bool), Error>) -> Void)
    func deleteLink(completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - ConversationGuestOptionsViewModelDelegate

// sourcery: AutoMockable
protocol ConversationGuestOptionsViewModelDelegate: AnyObject {
    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        didUpdateState state: ConversationGuestOptionsViewModel.State
    )

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        didReceiveError error: Error
    )

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        confirmRemovingGuests completion: @escaping (Bool) -> Void
    ) -> UIAlertController?

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        presentGuestLinkTypeSelection completion: @escaping (GuestLinkType) -> Void
    )

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        confirmRevokingLink completion: @escaping (Bool) -> Void
    )

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        wantsToShareMessage message: String,
        sourceView: UIView
    )

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        presentCreateSecureGuestLink viewController: UIViewController,
        animated: Bool
    )
}

// MARK: - ConversationGuestOptionsViewModel

final class ConversationGuestOptionsViewModel {
    private let conversation: ZMConversation
    private let createSecureGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol

    struct State {
        var rows = [CellConfiguration]()
        var isLoading = false
    }

    private var showLoadingCell = false {
        didSet {
            updateRows()
        }
    }

    private var link: String?

    var securedLink: String? {
        didSet {
            updateRows()
        }
    }

    var copyInProgress = false {
        didSet {
            updateRows()
        }
    }

    var state = State() {
        didSet {
            delegate?.conversationGuestOptionsViewModel(self, didUpdateState: state)
        }
    }

    weak var delegate: ConversationGuestOptionsViewModelDelegate?

    private var isGuestLinkWithPasswordAvailable: Bool {
        guard let apiVersion = BackendInfo.apiVersion else { return false }

        return apiVersion >= .v4
    }

    private let configuration: ConversationGuestOptionsViewModelConfiguration

    init(
        configuration: ConversationGuestOptionsViewModelConfiguration,
        conversation: ZMConversation,
        createSecureGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol
    ) {
        self.configuration = configuration
        self.conversation = conversation
        self.createSecureGuestLinkUseCase = createSecureGuestLinkUseCase

        updateRows()
        configuration.allowGuestsChangedHandler = { [weak self] allowGuests in
            guard let self else { return }
            if allowGuests, self.configuration.isCodeEnabled {
                fetchLink()
            } else {
                updateRows()
            }
        }

        if configuration.allowGuests, configuration.isCodeEnabled {
            fetchLink()
        }

        configuration.guestLinkFeatureStatusChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }

    private func updateRows() {
        state.rows = computeVisibleRows()
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: copy?
    private func computeVisibleRows() -> [CellConfiguration] {
        var rows: [CellConfiguration] = [.allowGuestsToogle(
            get: { [unowned self] in configuration.allowGuests },
            set: { [unowned self] in setAllowGuests($0, view: $1) },
            isEnabled: configuration.isConversationFromSelfTeam
        )]
        guard configuration.allowGuests else {
            return rows
        }

        switch configuration.guestLinkFeatureStatus {
        case .enabled:
            if securedLink != nil {
                rows.append(.secureLinkHeader)
            } else {
                rows.append(.linkHeader)
            }

            if !configuration.isConversationFromSelfTeam {
                rows.append(.info(infoText(isSelfTeam: configuration.isConversationFromSelfTeam, isDisabled: true)))
            } else if showLoadingCell {
                rows.append(.loading)
            } else {
                // Check if we have a link already
                if let link {
                    rows.append(.text(link))
                    rows.append(copyInProgress ? .copiedLink : .copyLink { [weak self] _ in self?.copyLink() })
                    rows.append(.shareLink { [weak self] view in self?.shareLink(view: view) })
                    rows.append(.revokeLink { [weak self] view in self?.revokeLink(view: view) })
                } else if let securedLink {
                    rows.append(.text(securedLink))
                    rows.append(copyInProgress ? .copiedLink : .copyLink { [weak self] _ in self?.copyLink() })
                    rows.append(.shareLink { [weak self] view in self?.shareLink(view: view) })
                    rows.append(.revokeLink { [weak self] view in self?.revokeLink(view: view) })
                } else {
                    rows.append(.createLinkButton { [weak self] view in
                        self?.startGuestLinkCreationFlow(from: view)
                    })
                }
            }
            return rows

        case .disabled:
            rows.append(.linkHeader)
            rows.append(.info(infoText(isSelfTeam: configuration.isConversationFromSelfTeam, isDisabled: false)))
            return rows

        case .unknown:
            return rows
        }
    }

    private func infoText(isSelfTeam: Bool, isDisabled: Bool) -> String {
        typealias GuestRoomLinkStrings = L10n.Localizable.GuestRoom.Link

        let guestLinkIsNotAllowedForSelfTeam = GuestRoomLinkStrings.NotAllowed.ForSelfTeam.explanation
        let guestLinkIsNotAllowedForOtherTeam = GuestRoomLinkStrings.NotAllowed.ForOtherTeam.explanation
        let guestLinkIsDisabledForOtherTeam = GuestRoomLinkStrings.Disabled.ForOtherTeam.explanation

        guard isSelfTeam else {
            return isDisabled ? guestLinkIsDisabledForOtherTeam : guestLinkIsNotAllowedForOtherTeam
        }
        return guestLinkIsNotAllowedForSelfTeam
    }

    /// revoke a conversation link
    ///
    /// - Parameter view: the source view which triggers revokeLink action
    private func revokeLink(view: UIView) {
        delegate?.conversationGuestOptionsViewModel(self, sourceView: view, confirmRevokingLink: { [weak self] revoke in
            guard let self else { return }
            guard revoke else { return updateRows() }

            let item = CancelableItem(delay: 0.4) { [weak self] in
                self?.state.isLoading = true
            }

            configuration.deleteLink { result in
                switch result {
                case .success:
                    self.link = nil
                    self.securedLink = nil
                    self.updateRows()

                case let .failure(error):
                    self.delegate?.conversationGuestOptionsViewModel(self, didReceiveError: error)
                }

                item.cancel()
                self.state.isLoading = false
            }
        })
    }

    /// share a conversation link
    ///
    /// - Parameter view: the source view which triggers shareLink action
    private func shareLink(view: UIView) {
        let linkToShare = securedLink ?? link
        guard let link = linkToShare else { return }
        let message = L10n.Localizable.GuestRoom.Share.message(link)
        delegate?.conversationGuestOptionsViewModel(self, wantsToShareMessage: message, sourceView: view)
    }

    private func copyLink() {
        let linkToCopy = securedLink ?? link
        guard let link = linkToCopy else { return }
        UIPasteboard.general.string = link
        copyInProgress = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.copyInProgress = false
        }
    }

    private func fetchLink() {
        let item = CancelableItem(delay: 0.4) { [weak self] in
            self?.showLoadingCell = true
        }

        configuration.fetchConversationLink { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(linkData):
                if linkData.secured {
                    securedLink = linkData.uri
                    link = nil
                } else {
                    link = linkData.uri
                    securedLink = nil
                }

            case let .failure(error):
                delegate?.conversationGuestOptionsViewModel(self, didReceiveError: error)
            }

            item.cancel()
            showLoadingCell = false
        }
    }

    private func createLink() {
        let item = CancelableItem(delay: 0.4) { [weak self] in
            self?.showLoadingCell = true
        }

        createSecureGuestLinkUseCase.invoke(conversation: conversation, password: nil) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(link):
                self.link = link
            case let .failure(error):
                delegate?.conversationGuestOptionsViewModel(self, didReceiveError: error)
            }

            item.cancel()
            showLoadingCell = false
        }
    }

    /// Starts the Guest Link Creation Flow
    /// - Parameter view: the source view which triggers create action
    func startGuestLinkCreationFlow(from view: UIView) {
        if isGuestLinkWithPasswordAvailable {
            delegate?.conversationGuestOptionsViewModel(
                self,
                sourceView: view,
                presentGuestLinkTypeSelection: { [weak self] guestLinkType in
                    guard let self else { return }
                    switch guestLinkType {
                    case .secure:
                        let viewController = CreateSecureGuestLinkViewController(
                            conversationSecureGuestLinkUseCase: createSecureGuestLinkUseCase,
                            conversation: conversation
                        )

                        let navigationController = viewController.wrapInNavigationController()
                        delegate?.conversationGuestOptionsViewModel(
                            self,
                            presentCreateSecureGuestLink: navigationController,
                            animated: true
                        )

                    case .normal:
                        createLink()
                    }
                }
            )
        } else {
            createLink()
        }
    }

    /// set conversation option AllowGuests
    /// - Parameters:
    ///   - allowGuests: new state AllowGuests
    ///   - view: the source view which triggers setAllowGuests action
    /// - Returns: alert controller
    @discardableResult
    func setAllowGuests(_ allowGuests: Bool, view: UIView) -> UIAlertController? {
        func _setAllowGuests() {
            let item = CancelableItem(delay: 0.4) { [weak self] in
                self?.state.isLoading = true
            }

            configuration.setAllowGuests(allowGuests) { [weak self] result in
                guard let self else { return }
                item.cancel()
                state.isLoading = false

                switch result {
                case .success:
                    updateRows()
                    if link == nil, securedLink == nil, allowGuests {
                        fetchLink()
                    }

                case let .failure(error): delegate?.conversationGuestOptionsViewModel(self, didReceiveError: error)
                }
            }
        }

        guard allowGuests != configuration.allowGuests else { return nil }

        // In case allow guests mode should be deactivated & guest in conversation, ask the delegate
        // to confirm this action as all guests will be removed.
        if !allowGuests, configuration.areGuestPresent {
            // Make "remove guests and services" warning only appear if guests or services are present
            return delegate?.conversationGuestOptionsViewModel(
                self,
                sourceView: view,
                confirmRemovingGuests: { [weak self] remove in
                    guard let self else { return }
                    guard remove else { return updateRows() }
                    link = nil
                    securedLink = nil
                    _setAllowGuests()
                }
            )
        } else {
            _setAllowGuests()
        }

        return nil
    }
}
