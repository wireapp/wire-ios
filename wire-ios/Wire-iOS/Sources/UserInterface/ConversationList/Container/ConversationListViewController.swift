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
import WireSyncEngine

final class ConversationListViewController: UIViewController {

    // MARK: - Properties

    let viewModel: ViewModel

    private var viewDidAppearCalled = false
    private static let contentControllerBottomInset: CGFloat = 16

    private var filterContainerView: UIView!
    private var filterLabel: UILabel!
    private var removeButton: UIButton!

    var selectedFilterLabel: String {
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter
        switch listContentController.listViewModel.selectedFilter {
        case .allConversations:
            return ""
        case .favorites:
            return FilterMenuLocale.Favorites.title
        case .groups:
            return FilterMenuLocale.Groups.title
        case .oneToOneConversations:
            return FilterMenuLocale.OneOnOneConversations.title
        }
    }

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    private var startCallToken: Any?

    weak var pushPermissionDeniedViewController: PermissionDeniedViewController?

    private let noConversationLabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()

    private var stackView: UIStackView!

    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundConversationListTableViewCell
        return view
    }()

    let listContentController: ConversationListContentController

    weak var titleViewLabel: UILabel?
    let networkStatusViewController = NetworkStatusViewController()
    let onboardingHint = ConversationListOnboardingHint()
    let selfProfileViewControllerBuilder: ViewControllerBuilder

    // MARK: - Init

    convenience init(
        account: Account,
        selfUser: SelfUserType,
        userSession: UserSession,
        isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
        selfProfileViewControllerBuilder: ViewControllerBuilder
    ) {
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase
        )
        self.init(
            viewModel: viewModel,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder
        )
    }

    required init(
        viewModel: ViewModel,
        selfProfileViewControllerBuilder: ViewControllerBuilder
    ) {
        self.viewModel = viewModel
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder

        let bottomInset = ConversationListViewController.contentControllerBottomInset
        listContentController = .init(userSession: viewModel.userSession)
        listContentController.collectionView.contentInset = .init(top: 0, left: 0, bottom: bottomInset, right: 0)

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        view.backgroundColor = SemanticColors.View.backgroundConversationList

        viewModel.viewController = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStackView()
        setupListContentController()
        setupNoConversationLabel()
        setupOnboardingHint()
        setupNetworkStatusBar()
        setupFilterContainerView()

        stackView.addArrangedSubview(contentContainer)

        createViewConstraints()

        setupTitleView()
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()

        // Update the UI as needed
        hideNoContactLabel(animated: false)

        setupObservers()

        listContentController.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1), animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.savePendingLastRead()
        viewModel.requestMarketingConsentIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isIPadRegular() {
            Settings.shared[.lastViewedScreen] = SettingsLastScreen.list
        }

        shouldAnimateNetworkStatusView = true

        ZClientViewController.shared?.notifyUserOfDisabledAppLockIfNeeded()

        viewModel.updateE2EICertifiedStatus()

        onboardingHint.arrowPointToView = tabBarController?.tabBar

        if !viewDidAppearCalled {
            viewDidAppearCalled = true

            ZClientViewController.shared?.showDataUsagePermissionDialogIfNeeded()
            ZClientViewController.shared?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustRightBarButtonItemsSpace()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    // MARK: - Setup UI

    private func setupObservers() {
        viewModel.setupObservers()
    }

    /// Sets up a vertical stack view containing all subviews
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupFilterContainerView() {
        filterContainerView = .init()
        stackView.addArrangedSubview(filterContainerView)

        let filterContainerStackView = UIStackView()
        filterContainerStackView.axis = .horizontal
        filterContainerStackView.alignment = .center
        filterContainerStackView.spacing = 4
        filterContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        filterContainerStackView.backgroundColor = SemanticColors.View.backgroundDefault
        filterContainerView.addSubview(filterContainerStackView)
        NSLayoutConstraint.activate([
            filterContainerStackView.topAnchor.constraint(equalToSystemSpacingBelow: filterContainerView.topAnchor, multiplier: 1),
            filterContainerView.bottomAnchor.constraint(equalToSystemSpacingBelow: filterContainerStackView.bottomAnchor, multiplier: 1),
            filterContainerStackView.centerXAnchor.constraint(equalTo: filterContainerView.centerXAnchor),
            filterContainerStackView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: filterContainerView.leadingAnchor, multiplier: 1),
            filterContainerView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: filterContainerStackView.trailingAnchor, multiplier: 1)
        ])

        filterLabel = UILabel()
        filterLabel.font = UIFont.font(for: .h5)
        filterLabel.textColor = SemanticColors.Label.baseSecondaryText
        filterLabel.text = "Filtered by \(selectedFilterLabel)"

        removeButton = UIButton(type: .system)
        removeButton.setTitle("Remove", for: .normal)
        removeButton.titleLabel?.font = UIFont.font(for: .h5)
        removeButton.setTitleColor(UIColor.accent(), for: .normal)
        removeButton.addTarget(self, action: #selector(removeFilter), for: .touchUpInside)

        filterContainerStackView.addArrangedSubview(filterLabel)
        filterContainerStackView.addArrangedSubview(removeButton)

        // Initially hide the filter container view
        filterContainerView.isHidden = true
    }

    @objc
    func removeFilter() {
        applyFilter(.allConversations)
    }

    private func setupListContentController() {
        listContentController.contentDelegate = viewModel
        add(listContentController, to: contentContainer)
    }

    private func setupNoConversationLabel() {
        contentContainer.addSubview(noConversationLabel)
    }

    private func setupOnboardingHint() {
        contentContainer.addSubview(onboardingHint)
    }

    private func setupNetworkStatusBar() {
        networkStatusViewController.delegate = self
        add(networkStatusViewController, to: contentContainer)
    }

    private func createViewConstraints() {
        guard let conversationList = listContentController.view else { return }

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        conversationList.translatesAutoresizingMaskIntoConstraints = false
        noConversationLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingHint.translatesAutoresizingMaskIntoConstraints = false
        networkStatusViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            networkStatusViewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            networkStatusViewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            networkStatusViewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            conversationList.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            conversationList.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            conversationList.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            conversationList.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            onboardingHint.bottomAnchor.constraint(equalTo: conversationList.bottomAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: contentContainer.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: contentContainer.rightAnchor),

            noConversationLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240)
        ])
    }

    // MARK: - No Contact Label Management

    /// Show or hide the "No Contact" label and onboarding hint based on whether there are archived conversations.
    /// - Parameter animated: Boolean to indicate if the change should be animated
    func showNoContactLabel(animated: Bool = true) {
        let closure = {
            let hasArchivedConversations = self.viewModel.hasArchivedConversations
            self.noConversationLabel.alpha = hasArchivedConversations ? 1.0 : 0.0
            self.onboardingHint.alpha = hasArchivedConversations ? 0.0 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: closure)
        } else {
            closure()
        }
    }

    /// Hide the "No Contact" label and onboarding hint.
    /// - Parameter animated: Boolean to indicate if the change should be animated
    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.noConversationLabel.alpha = 0
            self.onboardingHint.alpha = 0
        }
    }

    // MARK: - Filter Management

    /// Method to apply the selected filter and update the UI accordingly
    /// - Parameter filter: The selected filter type to be applied
    func applyFilter(_ filter: ConversationFilterType) {
        self.listContentController.listViewModel.selectedFilter = filter
        self.setupRightNavigationBarButtons()

        if filter == .allConversations {
            filterContainerView.isHidden = true
        } else {
            filterLabel.text = "Filtered by \(selectedFilterLabel)"
            filterContainerView.isHidden = false
        }

        // Trigger a layout update to ensure the correct positioning
        // of the add conversation button and filter button
        // when the filter button is tapped.
        view.setNeedsLayout()
    }

    // MARK: - Selection Management

    /// Scroll to the current selection
    /// - Parameter animated: Perform animation or not
    func scrollToCurrentSelection(animated: Bool) {
        listContentController.scrollToCurrentSelection(animated: animated)
    }

    /// Select a conversation in the list content controller
    /// - Parameters:
    ///   - conversation: The conversation to select
    ///   - message: The message to scroll to
    ///   - focus: Boolean to indicate if the view should focus
    ///   - animated: Boolean to indicate if the change should be animated
    ///   - completion: Completion handler to be called after the selection
    /// - Returns: Boolean indicating if the selection was successful
    func selectOnListContentController(
        _ conversation: ZMConversation!,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool {
        listContentController.select(
            conversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated,
            completion: completion
        )
    }

    // MARK: - Presentation

    /// Present the new conversation view controller
    func presentNewConversationViewController() {
        let viewController = StartUIViewController(userSession: viewModel.userSession)
        viewController.delegate = viewModel
        viewController.view.backgroundColor = SemanticColors.View.backgroundDefault

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.transitioningDelegate = self
        navigationController.modalPresentationStyle = .currentContext

        tabBarController?.present(navigationController, animated: true) {
            viewController.showKeyboardIfNeeded()
        }
    }

    /// Show the newsletter subscription dialog if needed
    /// - Parameter completionHandler: The completion handler to be called after the dialog is shown
    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler) {
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(
            presentViewController: self,
            completionHandler: completionHandler
        )
    }

    /// Select the inbox and focus on the view
    /// - Parameter focus: Boolean to indicate if the view should focus
    func selectInboxAndFocusOnView(focus: Bool) {
        listContentController.selectInboxAndFocus(onView: focus)
    }
}

// MARK: - ViewModel Delegate

extension ConversationListViewController: ConversationListContainerViewModelDelegate {

    func conversationListViewControllerViewModel(_ viewModel: ViewModel, didUpdate selfUserStatus: UserStatus) {
        setupTitleView()
        setupLeftNavigationBarButtons()
    }
}

// MARK: - ConversationListViewController + ArchivedListViewControllerDelegate

extension ConversationListViewController: ArchivedListViewControllerDelegate {

    func archivedListViewController(
        _ viewController: ArchivedListViewController,
        didSelectConversation conversation: ZMConversation
    ) {
        _ = selectOnListContentController(
            conversation,
            scrollTo: nil,
            focusOnView: true,
            animated: true
        ) { [weak self] in
            self?.tabBarController?.selectedIndex = MainTabBarControllerTab.conversations.rawValue
        }
    }
}

// MARK: - Helpers

private extension NSAttributedString {

    static var attributedTextForNoConversationLabel: NSAttributedString? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)

        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: SemanticColors.Label.textDefault,
            NSAttributedString.Key.font: UIFont.font(for: .h3),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        paragraphStyle.paragraphSpacing = 4

        let titleString = L10n.Localizable.ConversationList.Empty.AllArchived.message
        return NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)
    }
}
