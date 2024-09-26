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
import WireAccountImage
import WireCommonComponents
import WireDataModel
import WireDesign
import WireMainNavigation
import WireReusableUIComponents
import WireSyncEngine

extension ConversationListViewController {

    func conversationListViewControllerViewModel(
        _ viewModel: ViewModel,
        didUpdate selfUserStatus: UserStatus
    ) {
        accountImageView?.availability = selfUserStatus.availability.map()
    }

    func conversationListViewControllerViewModel(
        _ viewModel: ViewModel,
        didUpdate accountImage: (image: UIImage, isTeamAccount: Bool)
    ) {

        accountImageView?.accountImage = accountImage.image

        if accountImage.isTeamAccount, let teamName = viewModel.account.teamName ?? viewModel.userSession.selfUser.teamName {
            accountImageView?.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam.accessibilityValue(teamName)
            accountImageView?.accessibilityIdentifier = "\(teamName) team"
        } else if let userName = viewModel.userSession.selfUser.name {
            accountImageView?.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam.accessibilityValue(userName)
            accountImageView?.accessibilityIdentifier = .none
        } else {
            accountImageView?.accessibilityValue = .none
            accountImageView?.accessibilityIdentifier = .none
        }
    }

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_ viewModel: ViewModel) {
        setupLeftNavigationBarButtons()
    }

    // MARK: - Navigation Bar Items

    private func setupAccountImageView() -> AccountImageView {

        let accountImageView = AccountImageView()
        accountImageView.accountImage = viewModel.accountImage.image
        accountImageView.availability = viewModel.selfUserStatus.availability.map()
        accountImageView.accessibilityTraits = .button
        accountImageView.accessibilityIdentifier = "bottomBarSettingsButton" // TODO: fix, can't be correct
        accountImageView.accessibilityHint = L10n.Accessibility.ConversationsList.AccountButton.hint
        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentProfile))
        accountImageView.addGestureRecognizer(tapGestureRecognizer)

        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        return accountImageView
    }

    func setupLeftNavigationBarButtons() {

        // in the design the left bar button items are very close to each other,
        // so we'll use a stack view instead
        let stackView = UIStackView()
        stackView.spacing = 4

        // avatar
        let accountImageView = setupAccountImageView()
        stackView.addArrangedSubview(accountImageView)
        self.accountImageView = accountImageView

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

        navigationItem.leftBarButtonItems = [.init(customView: stackView)]
    }

    func setupLeftNavigationBarButtons_SplitView() {
        navigationItem.leftBarButtonItems = []
    }

    func setupTitleView() {
        switch splitViewInterface {
        case .expanded:
            navigationItem.title = L10n.Localizable.ConversationList.Filter.AllConversations.title
        case .collapsed:
            navigationItem.title = L10n.Localizable.List.title
        }
    }

    func setupRightNavigationBarButtons() {

        let spacer = UIBarButtonItem(systemItem: .fixedSpace)
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter

        // New Conversation Button
        let newConversationImage = UIImage(resource: .ConversationList.Header.newConversation)
        let newConversationAction = UIAction(image: newConversationImage) { [weak self] _ in
            Task {
                await self?.mainCoordinator.showNewConversation()
            }
        }
        // TODO: accessibility
        navigationItem.rightBarButtonItems = [.init(customView: UIButton(primaryAction: newConversationAction)), spacer]

        let defaultFilterImage = UIImage(resource: .ConversationList.Header.filterConversations)
        let filledFilterImage = UIImage(resource: .ConversationList.Header.filterConversationsFilled)

        var selectedFilterImage: UIImage

        switch listContentController.listViewModel.selectedFilter {
        case .favorites, .groups, .oneOnOne:
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
            filter: .oneOnOne,
            isSelected: listContentController.listViewModel.selectedFilter == .oneOnOne
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
        view.setNeedsLayout()
    }

    func setupRightNavigationBarButtons_SplitView() {

        let newConversationBarButton = IconButton()
        newConversationBarButton.setIcon(.plus, size: .tiny, for: .normal)
        newConversationBarButton.accessibilityIdentifier = "???????????" // TODO: accessibilityIdentifier
        newConversationBarButton.accessibilityLabel = "" // TODO: accessibilityLabel
        newConversationBarButton.addAction(.init { [weak self] _ in
            Task {
                await self?.mainCoordinator.showNewConversation()
            }
        }, for: .primaryActionTriggered)
        newConversationBarButton.backgroundColor = SemanticColors.Button.backgroundBarItem
        newConversationBarButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        newConversationBarButton.layer.borderWidth = 1
        newConversationBarButton.setBorderColor(SemanticColors.Button.borderBarItem.resolvedColor(with: traitCollection), for: .normal)
        newConversationBarButton.layer.cornerRadius = 12
        newConversationBarButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        newConversationBarButton.bounds.size = newConversationBarButton.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: newConversationBarButton)]
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
        filter: ConversationFilter?,
        isSelected: Bool
    ) -> UIAction {
        let imageName = FilterImageName.filterImageName(for: filter, isSelected: isSelected).rawValue
        let actionImage = FilterButtonStyleHelper.makeActionImage(named: imageName, isSelected: isSelected)
        let attributedTitle = FilterButtonStyleHelper.makeAttributedTitle(for: title, isSelected: isSelected)

        let action = UIAction(title: title, image: actionImage) { [weak self] _ in
            if let filter {
                self?.applyFilter(filter)
            } else {
                self?.clearFilter()
            }
        }

        action.setValue(attributedTitle, forKey: "attributedTitle")
        action.accessibilityLabel = accessibilityLabelForFilterAction(for: filter, isSelected: isSelected)

        return action
    }

    func accessibilityLabelForFilterAction(
        for filter: ConversationFilter?,
        isSelected: Bool
    ) -> String {

        typealias accessibilityLocale = L10n.Accessibility.ConversationsList.FilterMenuOptions

        switch filter {
        case .favorites:
            return isSelected ? accessibilityLocale.Favorites.Selected.description : accessibilityLocale.Favorites.description

        case .groups:
            return isSelected ? accessibilityLocale.Groups.Selected.description : accessibilityLocale.Groups.description

        case .oneOnOne:
            return isSelected ? accessibilityLocale.OneOnOne.Selected.description : accessibilityLocale.OneOnOne.description

        case .none:
            return isSelected ? accessibilityLocale.AllConversations.Selected.description : accessibilityLocale.AllConversations.description

        }
    }

    /// Equally distributes the space on the left and on the right side of the filter bar button item.
    func adjustRightBarButtonItemsSpace() {
        // TODO: fix
//        guard
//            let rightBarButtonItems = navigationItem.rightBarButtonItems,
//            rightBarButtonItems.count == 3, // new conversation, spacer, filter
//            let newConversationButton = rightBarButtonItems[0].customView,
//            let filterConversationsButton = rightBarButtonItems[2].customView,
//            let titleViewLabel,
//            let window = viewIfLoaded?.window
//        else { return }
//
//        let filterConversationsButtonWidth = filterConversationsButton.frame.size.width
//        let titleLabelMaxX = titleViewLabel.convert(titleViewLabel.frame, to: window).maxX
//        let newConversationButtonMinX = newConversationButton.convert(newConversationButton.frame, to: window).minX
//        let spacerWidth = (newConversationButtonMinX - titleLabelMaxX - filterConversationsButtonWidth) / 2
//        rightBarButtonItems[1].width = spacerWidth < 29 ? spacerWidth : 29
    }

    @objc
    private func presentProfile() {
        Task {
            await mainCoordinator.showSelfProfile()
        }
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

        LegalHoldDetailsViewController.present(
            in: self,
            user: selfUser,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator
        )
    }

    @objc
    func presentLegalHoldRequest() {
        guard case .pending = viewModel.selfUserLegalHoldSubject.legalHoldStatus else {
            return
        }

        ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }
}
