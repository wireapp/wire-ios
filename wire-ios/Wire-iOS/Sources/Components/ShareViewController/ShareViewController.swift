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

import UIKit
import WireDataModel
import WireDesign
import WireMainNavigationUI
import WireSyncEngine

protocol ShareDestination: Hashable {
    var displayNameWithFallback: String { get }
    var securityLevel: ZMConversationSecurityLevel { get }
    var showsGuestIcon: Bool { get }
    var isUnderLegalHold: Bool { get }
    var avatarView: UIView? { get }
}

protocol Shareable {
    associatedtype I: ShareDestination
    func share(to: [some Any], userSession: UserSession)
    func previewView(userSession: UserSession) -> UIView?
}

private struct ShareViewModel<D: ShareDestination> {
    let destinations: [D]
    private(set) var filteredDestinations: [D]
    private(set) var selectedDestinations: Set<D> = []

    var isSendButtonEnabled: Bool {
        !selectedDestinations.isEmpty
    }

    init(destinations: [D]) {
        self.destinations = destinations
        self.filteredDestinations = destinations
    }

    mutating func updateFilterText(_ filterText: String) {
        guard !filterText.isEmpty else {
            filteredDestinations = destinations
            return
        }

        filteredDestinations = destinations.filter {
            $0.displayNameWithFallback.range(of: filterText, options: .caseInsensitive) != nil
        }
    }

    func destination(at indexPath: IndexPath) -> D {
        filteredDestinations[indexPath.row]
    }

    func isDestinationSelected(_ destination: D) -> Bool {
        selectedDestinations.contains(destination)
    }

    mutating func selectDestination(_ destination: D) {
        selectedDestinations.insert(destination)
    }

    mutating func deselectDestination(_ destination: D) {
        selectedDestinations.remove(destination)
    }

    mutating func updateSelectedDestinations(_ destinations: Set<D>) {
        selectedDestinations = destinations
    }
}

final class ShareViewController<D: ShareDestination & NSObjectProtocol, S: Shareable>: UIViewController,
    UITableViewDelegate, UITableViewDataSource {

    typealias MainCoordinator = WireMainNavigationUI.MainCoordinator<MainCoordinatorDependencies>

    let destinations: [D]
    let shareable: S
    let userSession: UserSession
    private let mainCoordinator: any MainCoordinatorProtocol
    private var viewModel: ShareViewModel<D>
    private var selectedDestinations: Set<D> {
        viewModel.selectedDestinations
    }

    var tokenFieldTopConstraint: NSLayoutConstraint?
    var tokenFieldShareablePreviewSpacingConstraint: NSLayoutConstraint?
    var shareablePreviewTopConstraint: NSLayoutConstraint?

    var showPreview: Bool {
        didSet {
            shareablePreviewWrapper?.isHidden = !showPreview

            updateShareablePreviewConstraint()
        }
    }

    func updateShareablePreviewConstraint() {
        if showPreview {
            tokenFieldTopConstraint?.isActive = false
            shareablePreviewTopConstraint?.isActive = true
            tokenFieldShareablePreviewSpacingConstraint?.isActive = true
        } else {
            shareablePreviewTopConstraint?.isActive = false
            tokenFieldShareablePreviewSpacingConstraint?.isActive = false
            tokenFieldTopConstraint?.isActive = true
        }
    }

    let allowsMultipleSelection: Bool
    var onDismiss: ((ShareViewController, Bool) -> Void)?
    var bottomConstraint: NSLayoutConstraint?

    init(
        shareable: S,
        destinations: [D],
        showPreview: Bool = true,
        allowsMultipleSelection: Bool = true,
        userSession: UserSession,
        mainCoordinator: any MainCoordinatorProtocol
    ) {
        self.destinations = destinations
        self.shareable = shareable
        self.showPreview = showPreview
        self.allowsMultipleSelection = allowsMultipleSelection
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.viewModel = ShareViewModel(destinations: destinations)
        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        createViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let containerView = UIView()
    var shareablePreviewView: UIView?
    var shareablePreviewWrapper: UIView?
    let searchIcon = UIImageView()
    let topSeparatorView = OverflowSeparatorView()
    let destinationsTableView = UITableView()
    let closeButton = IconButton(style: .default)
    let sendButton = IconButton(style: .default)

    let clearButton = IconButton(style: .default)
    let tokenField = TokenField()
    let bottomSeparatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        return view
    }()

    // MARK: - Search

    // MARK: - Actions

    @objc
    func onCloseButtonPressed(sender: AnyObject?) {
        onDismiss?(self, false)
    }

    @objc
    func onSendButtonPressed(sender: AnyObject?) {
        if !selectedDestinations.isEmpty {
            shareable.share(to: Array(selectedDestinations), userSession: userSession)
            if let conversation = selectedDestinations.first as? ZMConversation,
               let mainCoordinator = mainCoordinator as? MainCoordinator {
                Task {
                    await mainCoordinator.showConversationList(conversationFilter: nil)
                    mainCoordinator.showConversation(conversation: conversation, message: nil)
                }
            } else {
                onDismiss?(self, true)
            }
        }
    }

    @objc
    func onClearButtonPressed() {
        tokenField.clearFilterText()
        tokenField.removeAllTokens()
        updateClearIndicator(for: tokenField)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredDestinations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: ShareDestinationCell<D>.reuseIdentifier) as! ShareDestinationCell<D>

        let destination = viewModel.destination(at: indexPath)
        cell.destination = destination
        cell.allowsMultipleSelection = allowsMultipleSelection
        cell.isSelected = viewModel.isDestinationSelected(destination)
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = viewModel.destination(at: indexPath)

        tokenField.addToken(forTitle: destination.displayNameWithFallback, representedObject: destination)

        viewModel.selectDestination(destination)
        updateSendButtonState()

        if !allowsMultipleSelection {
            onSendButtonPressed(sender: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let destination = viewModel.destination(at: indexPath)

        guard let token = tokenField.token(forRepresentedObject: destination) else {
            return
        }
        tokenField.removeToken(token)

        viewModel.deselectDestination(destination)
        updateSendButtonState()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        topSeparatorView.scrollViewDidScroll(scrollView: scrollView)
    }

    @objc
    private func keyboardFrameWillChange(notification: Notification) {
        let inputAccessoryHeight = UIResponder.currentFirst?.inputAccessoryView?.bounds.size.height ?? 0

        UIView.animate(
            withKeyboardNotification: notification,
            in: view,
            animations: { [weak self] keyboardFrameInView in
                guard let self else { return }

                let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
                bottomConstraint?.constant = keyboardHeight == 0 ? -view.safeAreaInsets.bottom : CGFloat(0)
                view.layoutIfNeeded()
            }
        )
    }

    private func updateClearIndicator(for tokenField: TokenField) {
        clearButton.isHidden = tokenField.filterText.isEmpty && tokenField.tokens.isEmpty
    }

    private func updateSendButtonState() {
        sendButton.isEnabled = viewModel.isSendButtonEnabled
    }
}

// MARK: - TokenFieldDelegate

extension ShareViewController: TokenFieldDelegate {
    func tokenField(_ tokenField: TokenField, changedTokensTo tokens: [Token<NSObjectProtocol>]) {
        viewModel.updateSelectedDestinations(Set(tokens.map { $0.representedObject.value as! D }))
        updateSendButtonState()
        destinationsTableView.reloadData()
    }

    func tokenField(_ tokenField: TokenField, changedFilterTextTo text: String) {
        updateClearIndicator(for: tokenField)
        viewModel.updateFilterText(text)
        destinationsTableView.reloadData()
    }

    func tokenFieldDidConfirmSelection(_ controller: TokenField) {
        // no-op
    }

}
