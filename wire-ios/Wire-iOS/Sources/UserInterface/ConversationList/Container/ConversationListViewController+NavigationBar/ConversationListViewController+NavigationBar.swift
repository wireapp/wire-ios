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
import WireAccountImageUI
import WireCommonComponents
import WireDataModel
import WireDesign
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine

extension ConversationListViewController: ConversationListContainerViewModelDelegate {

    func conversationListViewControllerViewModel(
        _ viewModel: ViewModel,
        didUpdate selfUserStatus: UserStatus
    ) {
        if mainSplitViewState == .collapsed {
            setupLeftNavigationBarButtonItems()
        }
    }

    func conversationListViewControllerViewModel(
        _ viewModel: ViewModel,
        didUpdate accountImage: UIImage
    ) {

        accountImageView?.accountImage = accountImage

        // TODO: [WPB-11606] fix accessibilityIdentifier if needed
        if let userName = viewModel.userSession.selfUser.name {
            accountImageView?.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam.accessibilityValue(userName)
            accountImageView?.accessibilityIdentifier = .none
        } else {
            accountImageView?.accessibilityValue = .none
            accountImageView?.accessibilityIdentifier = .none
        }
    }

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_ viewModel: ViewModel) {
        if mainSplitViewState == .collapsed {
            setupLeftNavigationBarButtonItems()
        }
    }

    // MARK: - Navigation Bar Items

    private func setupAccountImageView() -> AccountImageView {

        let accountImageView = AccountImageView()
        accountImageView.accountImage = viewModel.accountImage
        accountImageView.availability = viewModel.selfUserStatus.availability.mapToAccountImageAvailability()
        accountImageView.accessibilityTraits = .button
        accountImageView.accessibilityHint = L10n.Accessibility.ConversationsList.AccountButton.hint
        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let design = AccountImageViewDesign()
        accountImageView.imageBorderWidth = design.borderWidth
        accountImageView.imageBorderColor = design.borderColor
        accountImageView.availableColor = design.availabilityIndicator.availableColor
        accountImageView.busyColor = design.availabilityIndicator.busyColor
        accountImageView.awayColor = design.availabilityIndicator.awayColor
        accountImageView.availabilityIndicatorBackgroundColor = design.availabilityIndicator.backgroundViewColor

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentProfile))
        accountImageView.addGestureRecognizer(tapGestureRecognizer)

        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        return accountImageView
    }

    func setupLeftNavigationBarButtonItems() {

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

    func setupLeftNavigationBarButtonItems_SplitView() {
        navigationItem.leftBarButtonItems = []
    }

    func setupTitleView() {
        switch mainSplitViewState {
        case .expanded:
            switch conversationFilter {
            case .none:
                navigationItem.title = L10n.Localizable.ConversationList.Filter.AllConversations.title
            case .favorites:
                navigationItem.title = L10n.Localizable.ConversationList.Filter.Favorites.title
            case .groups:
                navigationItem.title = L10n.Localizable.ConversationList.Filter.Groups.title
            case .oneOnOne:
                navigationItem.title = L10n.Localizable.ConversationList.Filter.OneOnOneConversations.title
            }
        case .collapsed:
            navigationItem.title = L10n.Localizable.List.title
        }
    }

    func setupRightNavigationBarButtonItems() {

        let spacer = UIBarButtonItem(systemItem: .fixedSpace)
        spacer.width = 18
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter

        // New Conversation Button
        let symbolConfiguration = UIImage.SymbolConfiguration(weight: .semibold)
        let newConversationImage = UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfiguration)!
        let newConversationAction = UIAction(image: newConversationImage) { [weak self] _ in
            Task {
                await self?.mainCoordinator.showConnect()
            }
        }
        let newConversationButton = UIButton(primaryAction: newConversationAction)
        let startConversationItem = UIBarButtonItem(customView: newConversationButton)
        // TODO: [WPB-11606] fix accessibility
        // startConversationItem.accessibilityIdentifier =
        // startConversationItem.accessibilityLabel =
        navigationItem.rightBarButtonItems = [startConversationItem, spacer]

        let defaultFilterImage = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: symbolConfiguration)!
        let filledFilterImage = UIImage(systemName: "line.3.horizontal.decrease.circle.fill", withConfiguration: symbolConfiguration)!

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

    func setupRightNavigationBarButtonItems_SplitView() {

        let newConversationBarButton = IconButton()
        newConversationBarButton.setIcon(.plus, size: .tiny, for: .normal)
        // TODO: [WPB-11606] fix accessibility
        // newConversationBarButton.accessibilityIdentifier =
        // newConversationBarButton.accessibilityLabel =
        newConversationBarButton.addAction(.init { [weak self] _ in
            Task {
                await self?.mainCoordinator.showCreateGroupConversation()
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
        let action = UIAction(title: title, image: actionImage) { [weak self] _ in
            Task {
                await self?.mainCoordinator.showConversationList(conversationFilter: filter)
            }
        }
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
