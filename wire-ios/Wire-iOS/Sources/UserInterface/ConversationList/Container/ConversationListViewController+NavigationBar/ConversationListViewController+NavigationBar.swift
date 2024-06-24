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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

enum ConversationFilterType {
    case favorites, groups, oneToOneConversations
}

extension ConversationListViewController {

    func conversationListViewControllerViewModelRequiresUpdatingAccountView(_ viewModel: ViewModel) {
        setupLeftNavigationBarButtons()
    }

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_ viewModel: ViewModel) {
        setupLeftNavigationBarButtons()
    }

    // MARK: - Title View

    func setupTitleView() {
        let titleLabel = UILabel()
        titleLabel.font = FontSpec(.normal, .semibold).font
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.accessibilityTraits = .header
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.text = L10n.Localizable.List.title
        titleLabel.accessibilityValue = L10n.Localizable.List.title
        navigationItem.titleView = titleLabel
        self.titleViewLabel = titleLabel
    }

    // MARK: - Navigation Bar Items

    func setupLeftNavigationBarButtons() {

        // in the design the left bar button items are very close to each other,
        // so we'll use stack view instead
        let stackView = UIStackView()
        stackView.spacing = 4

        // avatar
        let accountView = createAccountView()
        stackView.addArrangedSubview(accountView)

        // legal hold
        switch viewModel.selfUserLegalHoldSubject.legalHoldStatus {
        case .disabled:
            break
        case .pending:
            let pendingRequestView = createPendingLegalHoldRequestView()
            stackView.addArrangedSubview(pendingRequestView)
        case .enabled:
            let legalHoldView = createLegalHoldView()
            stackView.addArrangedSubview(legalHoldView)
        }

        // verification status
        if viewModel.selfUserStatus.isE2EICertified {
            let imageView = UIImageView(image: .init(resource: .certificateValid))
            imageView.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(imageView)
        }
        if viewModel.selfUserStatus.isProteusVerified {
            let imageView = UIImageView(image: .init(resource: .verifiedShield))
            imageView.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(imageView)
        }

        navigationItem.leftBarButtonItem = .init(customView: stackView)
    }

    private func createAccountView() -> UIView {
        guard let session = ZMUserSession.shared() else { return .init() }

        let user = ZMUser.selfUser(inUserSession: session)

        let accountView = AccountViewBuilder(account: viewModel.account, user: user, displayContext: .conversationListHeader).build()
        accountView.unreadCountStyle = .current
        accountView.autoUpdateSelection = false

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentSettings))
        accountView.addGestureRecognizer(tapGestureRecognizer)
        accountView.accessibilityTraits = .button
        accountView.accessibilityIdentifier = "bottomBarSettingsButton"
        accountView.accessibilityHint = L10n.Accessibility.ConversationsList.AccountButton.hint

        if let selfUser = ZMUser.selfUser(),
           selfUser.clientsRequiringUserAttention.count > 0 {
            accountView.accessibilityLabel = L10n.Localizable.Self.NewDevice.Voiceover.label
        }

        return accountView.wrapInAvatarSizeContainer()
    }

    func setupRightNavigationBarButtons() {
        let spacer = UIBarButtonItem(systemItem: .fixedSpace)
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter

        // New Conversation Button
        let newConversationImage = UIImage(resource: .ConversationList.Header.newConversation)
        let newConversationAction = UIAction(image: newConversationImage) { [weak self] _ in
            self?.presentNewConversationViewController()
        }
        navigationItem.rightBarButtonItems = [.init(customView: UIButton(primaryAction: newConversationAction)), spacer]

        let defaultFilterImage = UIImage(resource: .ConversationList.Header.filterConversations)
        let filledFilterImage = UIImage(resource: .ConversationList.Header.filterConversationsFilled)

        var selectedFilterImage: UIImage

        switch listContentController.listViewModel.selectedFilter {
        case .favorites, .groups, .oneToOneConversations:
            selectedFilterImage = filledFilterImage
        case .none:
            selectedFilterImage = defaultFilterImage
        }

        // Define the menu actions with initial states
        let allConversationsAction = createFilterAction(
            title: FilterMenuLocale.AllConversations.title,
            filter: nil,
            isSelected: listContentController.listViewModel.selectedFilter == nil
        )

        let favoritesAction = createFilterAction(
            title: FilterMenuLocale.Favorites.title,
            filter: .favorites,
            isSelected: listContentController.listViewModel.selectedFilter == .favorites
        )
        let groupsAction = createFilterAction(
            title: FilterMenuLocale.Groups.title,
            filter: .groups,
            isSelected: listContentController.listViewModel.selectedFilter == .groups
        )
        let oneToOneConversationsAction = createFilterAction(
            title: FilterMenuLocale.OneOnOneConversations.title,
            filter: .oneToOneConversations,
            isSelected: listContentController.listViewModel.selectedFilter == .oneToOneConversations
        )

        // Create the menu
        let filterMenu = UIMenu(
            children: [
                allConversationsAction,
                favoritesAction,
                groupsAction,
                oneToOneConversationsAction
            ]
        )

        // Create the filter button and assign the menu
        let filterButton = UIButton(type: .system)
        filterButton.setImage(selectedFilterImage, for: .normal)
        filterButton.showsMenuAsPrimaryAction = true
        filterButton.accessibilityLabel = L10n.Accessibility.ConversationsList.FilterButton.description
        filterButton.menu = filterMenu

        navigationItem.rightBarButtonItems?.append(UIBarButtonItem(customView: filterButton))

        // Trigger a layout update to ensure the correct positioning
        // of the add conversation button and filter button
        // when the filter button is tapped.
        self.view.setNeedsLayout()
    }

    /// Creates a `UIAction` for a filter button with the specified title, filter type, and selection state.
    ///
    /// This method generates an action that updates the filter applied to the content list.
    /// It configures the action's image and title based on the filter type and whether it is selected.
    /// When the action is triggered, it updates the filter, adjusts the navigation bar buttons,
    /// reloads the list sections, and triggers a layout update to ensure correct positioning of the buttons.
    ///
    /// - Parameters:
    ///   - title: The title of the filter action.
    ///   - filter: The filter type to be applied when the action is triggered.
    ///   - isSelected: A boolean indicating whether the filter is currently selected.
    /// - Returns: A `UIAction` configured with the provided title, filter type, and selection state.
    ///
    /// - Note: It also customizes the action's image and title appearance based on the selection state.
    private func createFilterAction(
        title: String,
        filter: ConversationFilterType?,
        isSelected: Bool
    ) -> UIAction {
        let imageName = FilterImageName.filterImageName(for: filter, isSelected: isSelected).rawValue
        let actionImage = FilterButtonStyleHelper.makeActionImage(named: imageName, isSelected: isSelected)
        let attributedTitle = FilterButtonStyleHelper.makeAttributedTitle(for: title, isSelected: isSelected)

        let action = UIAction(title: title, image: actionImage) { [weak self] _ in
            self?.applyFilter(filter)
        }

        action.setValue(attributedTitle, forKey: "attributedTitle")
        action.accessibilityLabel = accessibilityLabelForFilterAction(for: filter, isSelected: isSelected)

        return action
    }

    func accessibilityLabelForFilterAction(
        for filter: ConversationFilterType?,
        isSelected: Bool
    ) -> String {

        typealias accessibilityLocale = L10n.Accessibility.ConversationsList.FilterMenuOptions

        switch filter {
        case .favorites:
            return isSelected ? accessibilityLocale.Favorites.Selected.description : accessibilityLocale.Favorites.description

        case .groups:
            return isSelected ? accessibilityLocale.Groups.Selected.description : accessibilityLocale.Groups.description

        case .oneToOneConversations:
            return isSelected ? accessibilityLocale.OneOnOne.Selected.description : accessibilityLocale.OneOnOne.description

        case .none:
            return isSelected ? accessibilityLocale.AllConversations.Selected.description : accessibilityLocale.AllConversations.description

        }
    }

    /// Equally distributes the space on the left and on the right side of the filter bar button item.
    func adjustRightBarButtonItemsSpace() {
        guard
            let rightBarButtonItems = navigationItem.rightBarButtonItems,
            rightBarButtonItems.count == 3, // new conversation, spacer, filter
            let newConversationButton = rightBarButtonItems[0].customView,
            let filterConversationsButton = rightBarButtonItems[2].customView,
            let titleViewLabel,
            let window = viewIfLoaded?.window
        else { return }

        let filterConversationsButtonWidth = filterConversationsButton.frame.size.width
        let titleLabelMaxX = titleViewLabel.convert(titleViewLabel.frame, to: window).maxX
        let newConversationButtonMinX = newConversationButton.convert(newConversationButton.frame, to: window).minX
        let spacerWidth = (newConversationButtonMinX - titleLabelMaxX - filterConversationsButtonWidth) / 2
        rightBarButtonItems[1].width = spacerWidth < 29 ? spacerWidth : 29
    }

    @objc
    func presentSettings() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let settingsViewController = createSettingsViewController(selfUser: selfUser)
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: settingsViewController)

        if wr_splitViewController?.layoutSize == .compact {
            present(keyboardAvoidingViewController, animated: true)
        } else {
            keyboardAvoidingViewController.modalPresentationStyle = .formSheet
            keyboardAvoidingViewController.view.backgroundColor = .black
            present(keyboardAvoidingViewController, animated: true)
        }
    }

    func createSettingsViewController(selfUser: ZMUser) -> UIViewController {
        selfProfileViewControllerBuilder
            .build()
            .wrapInNavigationController(navigationControllerClass: NavigationController.self)
    }

    // MARK: - Legal Hold

    private func createLegalHoldView() -> UIView {
        let imageView = UIImageView()

        imageView.setTemplateIcon(.legalholdactive, size: .tiny)
        imageView.tintColor = SemanticColors.Icon.foregroundDefaultRed
        imageView.isUserInteractionEnabled = true

        let imageViewContainer = UIView()
        imageViewContainer.setLegalHoldAccessibility()

        imageViewContainer.addSubview(imageView)

        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageViewContainer.widthAnchor.constraint(equalToConstant: CGFloat.ConversationListHeader.iconWidth),
            imageViewContainer.widthAnchor.constraint(equalTo: imageViewContainer.heightAnchor),

            imageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor)])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentLegalHoldInfo))
        imageViewContainer.addGestureRecognizer(tapGestureRecognizer)

        return imageViewContainer
    }

    func createPendingLegalHoldRequestView() -> UIView {
        let button = IconButton(style: .circular)
        button.setBackgroundImageColor(SemanticColors.Icon.backgroundLegalHold.withAlphaComponent(0.8), for: .normal)

        button.setIcon(.clock, size: 12, for: .normal)
        button.setIconColor(.white, for: .normal)
        button.setIconColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)

        button.setLegalHoldAccessibility()
        button.accessibilityValue = L10n.Localizable.LegalholdRequest.Button.accessibility

        button.addTarget(self, action: #selector(presentLegalHoldRequest), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])

        return button
    }

    @objc
    func presentLegalHoldInfo() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        LegalHoldDetailsViewController.present(in: self, user: selfUser, userSession: viewModel.userSession)
    }

    @objc
    func presentLegalHoldRequest() {
        guard case .pending = viewModel.selfUserLegalHoldSubject.legalHoldStatus else {
            return
        }

        ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }
}

// MARK: - wrapInAvatarSizeContainer

extension UIView {

    func wrapInAvatarSizeContainer() -> UIView {
        let container = UIView()
        container.addSubview(self)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),
            container.heightAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),

            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        return container
    }
}
