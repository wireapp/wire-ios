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

import SwiftUI
import UIKit
import WireAccountImageUI
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFolderPickerUI
import WireLocators
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine
import WireUtilities

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
        didUpdate accountImage: WireAccountImageUI.AccountImageSource
    ) {

        accountImageView?.source = accountImage
        accountImageView?.accessibilityIdentifier = "account_profile_image_view"

        if let userName = viewModel.userSession.selfUser.name {
            accountImageView?.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam
                .accessibilityValue(userName)
        } else {
            accountImageView?.accessibilityValue = .none
        }
    }

    func conversationListViewControllerViewModelDidReloadContent(_ viewModel: ViewModel) {
        configureEmptyPlaceholder()
    }

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_ viewModel: ViewModel) {
        if mainSplitViewState == .collapsed {
            setupLeftNavigationBarButtonItems()
        }
    }

    func refreshAccountImageViewNotificationBadge() {
        accountImageView?.hideProfileNotificationsBadge = viewModel.hideProfileNotificationsBadge
    }

    // MARK: - Navigation Bar Items

    private func makeAccountImageView() -> AccountImageView {

        let accountImageView = AccountImageView()
        accountImageView.source = viewModel.accountImageSource
        accountImageView.availability = viewModel.selfUserStatus.availability.mapToAccountImageAvailability()
        accountImageView.hideProfileNotificationsBadge = viewModel.hideProfileNotificationsBadge
        accountImageView.isAccessibilityElement = true
        accountImageView.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam
            .accessibilityValue(viewModel.userSession.selfUser.name ?? "")
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
        let accountImageView = makeAccountImageView()
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
        navigationItem.title = switch (mainSplitViewState, conversationFilter) {
        case (.expanded, .none):
            L10n.Localizable.ConversationList.Filter.AllConversations.title
        case (.expanded, .favorites):
            L10n.Localizable.ConversationList.Filter.Favorites.title
        case (.expanded, .groups):
            L10n.Localizable.ConversationList.Filter.Groups.title
        case (.expanded, .channels):
            L10n.Localizable.ConversationList.Filter.Channels.title
        case (.expanded, .oneOnOne):
            L10n.Localizable.ConversationList.Filter.OneOnOneConversations.title
        case (.expanded, .unread):
            L10n.Localizable.ConversationList.Filter.Unread.title
        case (.expanded, .mentions):
            L10n.Localizable.ConversationList.Filter.Mentions.title
        case (.expanded, .replies):
            L10n.Localizable.ConversationList.Filter.Replies.title
        case (.expanded, .drafts):
            L10n.Localizable.ConversationList.Filter.Drafts.title
        case (.expanded, .folder):
            L10n.Localizable.ConversationList.Filter.Folders.title
        case (.collapsed, _):
            L10n.Localizable.List.title
        }
    }

    func setupRightNavigationBarButtonItems() {

        let spacer = UIBarButtonItem(systemItem: .fixedSpace)
        spacer.width = 18
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter

        // New Conversation Button
        let symbolConfiguration = UIImage.SymbolConfiguration(weight: .semibold)
        let newConversationImage = UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfiguration)!
        let newConversationAction = UIAction(image: newConversationImage) { [weak self] _ in self?.presentConnectUI() }
        let newConversationButton = UIButton(primaryAction: newConversationAction)
        let startConversationItem = UIBarButtonItem(customView: newConversationButton)
        startConversationItem.accessibilityIdentifier = Locators.ConversationsPage.createGroupOrSearchButton.rawValue
        startConversationItem.accessibilityLabel = L10n.Accessibility.ConversationList.StartConversationButton
            .description
        navigationItem.rightBarButtonItems = [startConversationItem, spacer]

        let defaultFilterImage = UIImage(
            systemName: "line.3.horizontal.decrease.circle",
            withConfiguration: symbolConfiguration
        )!
        let filledFilterImage = UIImage(
            systemName: "line.3.horizontal.decrease.circle.fill",
            withConfiguration: symbolConfiguration
        )!

        let selectedFilterImage: UIImage = switch listContentController.listViewModel.selectedFilter {
        case .favorites, .groups, .channels, .oneOnOne, .unread, .mentions, .replies, .drafts, .folder:
            filledFilterImage
        case .none:
            defaultFilterImage
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
        let channelsAction = createFilterAction(
            title: FilterMenuLocale.Channels.title,
            filter: .channels,
            isSelected: listContentController.listViewModel.selectedFilter == .channels
        )
        let oneToOneConversationsAction = createFilterAction(
            title: FilterMenuLocale.OneOnOneConversations.title,
            filter: .oneOnOne,
            isSelected: listContentController.listViewModel.selectedFilter == .oneOnOne
        )

        let foldersAction = createFolderFilterAction(
            isSelected: listContentController.listViewModel.selectedFilter?.folderData != nil
        )

        // Create menu children array
        var menuChildren = [
            allConversationsAction,
            favoritesAction
        ]

        // Add unread, mentions and replies filters if developer flag is enabled
        if DeveloperFlag.showUnreadConversationsFilter.isOn {
            let unreadAction = createFilterAction(
                title: L10n.Localizable.ConversationList.Filter.Unread.title,
                filter: .unread,
                isSelected: listContentController.listViewModel.selectedFilter == .unread
            )
            menuChildren.append(unreadAction)

            let mentionsAction = createFilterAction(
                title: L10n.Localizable.ConversationList.Filter.Mentions.title,
                filter: .mentions,
                isSelected: listContentController.listViewModel.selectedFilter == .mentions
            )
            menuChildren.append(mentionsAction)

            let repliesAction = createFilterAction(
                title: L10n.Localizable.ConversationList.Filter.Replies.title,
                filter: .replies,
                isSelected: listContentController.listViewModel.selectedFilter == .replies
            )
            menuChildren.append(repliesAction)

            let draftsAction = createFilterAction(
                title: L10n.Localizable.ConversationList.Filter.Drafts.title,
                filter: .drafts,
                isSelected: listContentController.listViewModel.selectedFilter == .drafts
            )
            menuChildren.append(draftsAction)
        }

        menuChildren.append(contentsOf: [
            groupsAction,
            channelsAction,
            oneToOneConversationsAction,
            foldersAction
        ])

        // Create the menu
        let filterMenu = UIMenu(children: menuChildren)

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
        newConversationBarButton.accessibilityIdentifier = "create_group_or_search_button"
        newConversationBarButton.accessibilityLabel = L10n.Accessibility.ConversationList.StartConversationButton
            .description
        newConversationBarButton.addTarget(
            self,
            action: #selector(presentCreateConversationUI),
            for: .primaryActionTriggered
        )
        newConversationBarButton.backgroundColor = SemanticColors.Button.backgroundBarItem
        newConversationBarButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        newConversationBarButton.layer.borderWidth = 1
        newConversationBarButton.setBorderColor(
            SemanticColors.Button.borderBarItem.resolvedColor(with: traitCollection),
            for: .normal
        )
        newConversationBarButton.layer.cornerRadius = 12
        newConversationBarButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        newConversationBarButton.bounds.size = newConversationBarButton.systemLayoutSizeFitting(CGSize(
            width: .max,
            height: 32
        ))

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
            return isSelected ? accessibilityLocale.Favorites.Selected.description : accessibilityLocale.Favorites
                .description

        case .groups:
            return isSelected ? accessibilityLocale.Groups.Selected.description : accessibilityLocale.Groups.description

        case .channels:
            return isSelected ? accessibilityLocale.Channels.Selected.description : accessibilityLocale.Channels
                .description

        case .oneOnOne:
            return isSelected ? accessibilityLocale.OneOnOne.Selected.description : accessibilityLocale.OneOnOne
                .description

        case .unread:
            return isSelected ? accessibilityLocale.Unread.Selected.description : accessibilityLocale.Unread
                .description

        case .mentions:
            return isSelected ? accessibilityLocale.Mentions.Selected.description : accessibilityLocale.Mentions
                .description

        case .replies:
            return isSelected ? accessibilityLocale.Replies.Selected.description : accessibilityLocale.Replies
                .description

        case .drafts:
            return isSelected ? accessibilityLocale.Drafts.Selected.description : accessibilityLocale.Drafts
                .description

        case .folder:
            return isSelected ? accessibilityLocale.Folders.Selected.description : accessibilityLocale.Folders
                .description

        case .none:
            return isSelected ? accessibilityLocale.AllConversations.Selected.description : accessibilityLocale
                .AllConversations.description
        }
    }

    @objc
    private func presentConnectUI() {
        Task {
            let rootViewController = await connectViewControllerBuilder.build()
            let connectUI = UINavigationController(rootViewController: rootViewController)
            connectUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(connectUI)
        }
    }

    @objc
    private func presentProfile() {
        // analytics
        let isNotificationsBadgeVisible = viewModel.hideProfileNotificationsBadge
        let analyticsEventTracker = viewModel.userSession.analyticsEventTracker
        #if false // [WPB-15245] This event has temporarily been disabled.
            analyticsEventTracker?.trackEvent(.UI.openSelfProfile(isMigrationDotActive: isNotificationsBadgeVisible))
        #endif

        // open profile
        Task {
            let rootViewController = selfProfileViewControllerBuilder.build(mainCoordinator: mainCoordinator)
            let selfProfileUI = UINavigationController(rootViewController: rootViewController)
            selfProfileUI.modalPresentationStyle = .formSheet
            selfProfileUI.presentationController?.delegate = rootViewController
            await mainCoordinator.presentViewController(selfProfileUI)
        }
    }

    @objc
    func presentCreateConversationUI() {
        Task {
            let rootViewController = await connectViewControllerBuilder.build()
            let connectUI = UINavigationController(rootViewController: rootViewController)
            connectUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(connectUI)
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
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor)
        ])

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
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileViewControllerBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
    }

    @objc
    func presentLegalHoldRequest() {
        guard case .pending = viewModel.selfUserLegalHoldSubject.legalHoldStatus else {
            return
        }

        ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }

    // MARK: Folder Picker

    private func createFolderFilterAction(isSelected: Bool) -> UIAction {
        let action = UIAction(
            title: L10n.Localizable.ConversationList.Filter.Folders.title,
            image: FilterButtonStyleHelper.makeActionImage(
                named: FilterImageName.folder.rawValue,
                isSelected: isSelected
            )
        ) { [weak mainCoordinator, weak self] _ in
            guard let self, let mainCoordinator else { return }

            Task { @MainActor [folderPickerViewControllerBuilder] in
                let viewController = folderPickerViewControllerBuilder.build(
                    mainCoordinator: mainCoordinator,
                    showCloseButton: true
                )
                if let sheet = viewController.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                }

                await mainCoordinator.presentViewController(viewController)
            }
        }

        action.accessibilityLabel = if isSelected {
            L10n.Accessibility.ConversationsList.FilterMenuOptions.Folders.Selected.description
        } else {
            L10n.Accessibility.ConversationsList.FilterMenuOptions.Folders.description
        }

        return action
    }
}
