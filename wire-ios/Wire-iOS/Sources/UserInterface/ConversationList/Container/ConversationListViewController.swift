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
import WireConversationListUI
import WireDataModel
import WireDesign
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine

final class ConversationListViewController: UIViewController {

    // MARK: - Properties

    let viewModel: ViewModel
    let mainCoordinator: AnyMainCoordinator
    let connectViewControllerBuilder: any ConnectViewControllerBuilderProtocol
    let selfProfileViewControllerBuilder: any SelfProfileViewControllerBuilderProtocol
    let createGroupConversationUIBuilder: any CreateGroupConversationViewControllerBuilderProtocol
    let conversationListCoordinator: any ConversationListCoordinatorProtocol
    weak var zClientViewController: ZClientViewController?

    private var viewDidAppearCalled = false
    private static let contentControllerBottomInset: CGFloat = 16

    private lazy var filterContainerView = UIView()

    private lazy var filterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.font(for: .h5)
        label.textColor = SemanticColors.Label.baseSecondaryText
        // TODO: [WPB-7301] The strings "Selected by groups", "Selected by favorites" etc. should probably be separate localized strings, without concatenation.
        label.text = L10n.Localizable.ConversationList.FilterLabel.text(selectedFilterLabel)
        return label
    }()

    private lazy var removeButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Localizable.ConversationList.Filter.RemoveButton.title, for: .normal)
        button.titleLabel?.font = UIFont.font(for: .h5)
        button.setTitleColor(UIColor.accent(), for: .normal)
        button.accessibilityLabel = L10n.Accessibility.ConversationsList.FilterView.RemoveButton.descritpion
        let action = UIAction { [weak self] _ in
            Task {
                await self?.mainCoordinator.showConversationList(conversationFilter: .none)
            }
        }
        button.addAction(action, for: .touchUpInside)
        return button
    }()

    var selectedFilterLabel: String {
        typealias FilterMenuLocale = L10n.Localizable.ConversationList.Filter
        switch listContentController.listViewModel.selectedFilter {
        case .favorites:
            return FilterMenuLocale.Favorites.title
        case .groups:
            return FilterMenuLocale.Groups.title
        case .oneOnOne:
            return FilterMenuLocale.OneOnOneConversations.title
        case .none:
            return ""
        }
    }

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    weak var pushPermissionDeniedViewController: PermissionDeniedViewController?

    private let noConversationLabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        label.numberOfLines = 0
        return label
    }()

    /// Arranges the filterContainerView (if visible) and the contentContainer below each other.
    private var stackView: UIStackView!

    let contentContainer = UIView()

    let listContentController: ConversationListContentController

    weak var accountImageView: AccountImageView?

    let networkStatusViewController = NetworkStatusViewController()
    private var emptyPlaceholderView: EmptyPlaceholderView!
    var mainSplitViewState: MainSplitViewState = .expanded {
        didSet {
            setupTitleView()
            updateNavigationItem()
            applyColorTheme()
            updateFilterContainerView()
        }
    }

    // MARK: - Init

    convenience init(
        account: Account,
        selfUserLegalHoldSubject: any SelfUserLegalHoldable,
        userSession: UserSession,
        zClientViewController: ZClientViewController,
        mainCoordinator: AnyMainCoordinator,
        isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
        connectViewControllerBuilder: some ConnectViewControllerBuilderProtocol,
        selfProfileViewControllerBuilder: some SelfProfileViewControllerBuilderProtocol,
        createGroupConversationViewControllerBuilder: some CreateGroupConversationViewControllerBuilderProtocol
    ) {
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUserLegalHoldSubject,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase,
            mainCoordinator: mainCoordinator,
            getUserAccountImageUseCase: GetUserAccountImageUseCase()
        )
        self.init(
            viewModel: viewModel,
            zClientViewController: zClientViewController,
            mainCoordinator: mainCoordinator,
            connectViewControllerBuilder: connectViewControllerBuilder,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder,
            createGroupConversationViewControllerBuilder: createGroupConversationViewControllerBuilder
        )
    }

    required init(
        viewModel: ViewModel,
        zClientViewController: ZClientViewController,
        mainCoordinator: AnyMainCoordinator,
        connectViewControllerBuilder: some ConnectViewControllerBuilderProtocol,
        selfProfileViewControllerBuilder: some SelfProfileViewControllerBuilderProtocol,
        createGroupConversationViewControllerBuilder: some CreateGroupConversationViewControllerBuilderProtocol
    ) {
        self.viewModel = viewModel
        self.mainCoordinator = mainCoordinator
        self.zClientViewController = zClientViewController
        self.connectViewControllerBuilder = connectViewControllerBuilder
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder
        self.createGroupConversationUIBuilder = createGroupConversationViewControllerBuilder
        let conversationListCoordinator = ConversationListCoordinator(mainCoordinator: mainCoordinator)
        self.conversationListCoordinator = conversationListCoordinator

        let bottomInset = ConversationListViewController.contentControllerBottomInset
        listContentController = ConversationListContentController(
            userSession: viewModel.userSession,
            conversationListCoordinator: conversationListCoordinator,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileViewControllerBuilder,
            zClientViewController: zClientViewController
        )
        listContentController.collectionView.contentInset = .init(top: 0, left: 0, bottom: bottomInset, right: 0)

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        hideNoContactLabel(animated: false)
        viewModel.viewController = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStackView()
        setupListContentController()
        setupNoConversationLabel()
        setupEmptyPlaceholder()
        setupNetworkStatusBar()
        setupFilterContainerView()

        stackView.addArrangedSubview(contentContainer)

        createViewConstraints()

        setupTitleView()
        updateNavigationItem()

        setupObservers()

        listContentController.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1), animated: false)

        applyColorTheme()

        setupSearchController()

        setContentScrollView(listContentController.collectionView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
        viewModel.savePendingLastRead()
        configureEmptyPlaceholder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isIPadRegular() {
            Settings.shared[.lastViewedScreen] = SettingsLastScreen.list
        }

        shouldAnimateNetworkStatusView = true

        zClientViewController?.notifyUserOfDisabledAppLockIfNeeded()

        viewModel.updateE2EICertifiedStatus()

        if !viewDidAppearCalled {
            viewDidAppearCalled = true

            zClientViewController?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        configureEmptyPlaceholder()
        updateFilterContainerView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
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

    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = ColorTheme.Backgrounds.surface

        // Configure appearance for different states
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    func setupFilterContainerView() {
        stackView.addArrangedSubview(filterContainerView)

        let filterContainerStackView = UIStackView()
        filterContainerStackView.axis = .horizontal
        filterContainerStackView.alignment = .center
        filterContainerStackView.spacing = 4
        filterContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        filterContainerView.addSubview(filterContainerStackView)
        NSLayoutConstraint.activate([
            filterContainerStackView.topAnchor.constraint(equalTo: filterContainerView.topAnchor),
            filterContainerView.bottomAnchor.constraint(equalTo: filterContainerStackView.bottomAnchor),
            filterContainerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: filterContainerView.leadingAnchor, multiplier: 2),
            filterContainerView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: filterContainerStackView.trailingAnchor, multiplier: 2)
        ])

        filterContainerStackView.addArrangedSubview(filterLabel)
        filterContainerStackView.addArrangedSubview(removeButton)

        // Initially hide the filter container view
        filterContainerView.isHidden = true
    }

    func updateFilterContainerView() {
        filterContainerView.isHidden = mainSplitViewState == .expanded || isEmptyPlaceholderVisible || listContentController.listViewModel.selectedFilter == .none
        filterLabel.text = L10n.Localizable.ConversationList.FilterLabel.text(selectedFilterLabel)
    }

    private func setupListContentController() {
        listContentController.contentDelegate = viewModel
        addChild(listContentController)
        contentContainer.addSubview(listContentController.view)
        listContentController.didMove(toParent: self)
    }

    private func setupNoConversationLabel() {
        contentContainer.addSubview(noConversationLabel)
    }

    private func setupEmptyPlaceholder() {
        let connectWithPeopleAction = UIAction { [weak self] _ in
            self?.presentConnectUI()
        }
        emptyPlaceholderView = EmptyPlaceholderView(
            content: emptyPlaceholderForSelectedFilter,
            connectWithPeopleAction: connectWithPeopleAction)
        contentContainer.addSubview(emptyPlaceholderView)
    }

    func configureEmptyPlaceholder() {
        emptyPlaceholderView.configure(with: emptyPlaceholderForSelectedFilter)
        emptyPlaceholderView.isHidden = !isEmptyPlaceholderVisible
    }

    private func setupNetworkStatusBar() {
        networkStatusViewController.delegate = self
        addChild(networkStatusViewController)
        contentContainer.addSubview(networkStatusViewController.view)
        networkStatusViewController.didMove(toParent: self)
    }

    private func createViewConstraints() {
        guard let conversationList = listContentController.view else { return }

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        conversationList.translatesAutoresizingMaskIntoConstraints = false
        noConversationLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        networkStatusViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            networkStatusViewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            networkStatusViewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            networkStatusViewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            conversationList.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            conversationList.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            conversationList.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            conversationList.bottomAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.bottomAnchor),

            emptyPlaceholderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            emptyPlaceholderView.bottomAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.bottomAnchor),
            emptyPlaceholderView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            emptyPlaceholderView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            noConversationLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240)
        ])
    }

    func applyColorTheme() {
        view.backgroundColor = mainSplitViewState == .expanded
        ? ColorTheme.Backgrounds.backgroundVariant
        : ColorTheme.Backgrounds.surface
    }

    private func setupSearchController() {

        let searchController = UISearchController(searchResultsController: .none)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.isTranslucent = false
        searchController.searchResultsUpdater = self

        if !isEmptyPlaceholderVisible {
            navigationItem.searchController = searchController
        } else {
            navigationItem.searchController = nil
        }
        navigationItem.preferredSearchBarPlacement = .stacked
    }

    /// Adjusts the navigation item appearance based on the `splitViewControllerMode` value.
    /// For expanded layouts, the navigation bar should only show a title and a new-conversation-button.
    /// For collapsed layouts the navigation bar should additionally show an account image and a filter button item.
    private func updateNavigationItem() {

        switch mainSplitViewState {
        case .collapsed:
            setupLeftNavigationBarButtonItems()
            setupRightNavigationBarButtonItems()
        case .expanded:
            setupLeftNavigationBarButtonItems_SplitView()
            setupRightNavigationBarButtonItems_SplitView()
        }
    }

    // MARK: - No Contact Label Management

    /// Show or hide the "No Contact" label and onboarding hint based on whether there are archived conversations.
    /// - Parameter animated: Boolean to indicate if the change should be animated
    func showNoContactLabel(animated: Bool = true) {
        let closure = {
            let hasArchivedConversations = self.viewModel.hasArchivedConversations
            self.noConversationLabel.alpha = hasArchivedConversations ? 1.0 : 0.0
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
        }
    }

    // MARK: - Filter Management

    /// Method to apply the selected filter and update the UI accordingly
    /// - Parameter filter: The selected filter type to be applied
    func applyFilter(_ filter: ConversationFilter?) {
        listContentController.listViewModel.selectedFilter = filter
        setupTitleView()
        if mainSplitViewState == .collapsed {
            setupRightNavigationBarButtonItems()
        } else {
            setupRightNavigationBarButtonItems_SplitView()
        }
        setupSearchController()
        updateFilterContainerView()
        configureEmptyPlaceholder()
    }

    @objc
    func applySearchText() {
        let searchText = navigationItem
            .searchController?
            .searchBar
            .text?
            .trimmingCharacters(in: .whitespaces)
            .lowercased() ?? ""
        listContentController.listViewModel.appliedSearchText = searchText
    }

    // MARK: - Selection Management

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
        animated: Bool
    ) -> Bool {
        listContentController.select(
            conversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated
        )
    }

    // MARK: - Presentation

    private func presentConnectUI() {
        Task {
            let connectUI = connectViewControllerBuilder.build(mainCoordinator: mainCoordinator)
            connectUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(connectUI)
        }
    }

    /// Select the inbox and focus on the view
    /// - Parameter focus: Boolean to indicate if the view should focus
    func selectInboxAndFocusOnView(focus: Bool) {
        listContentController.selectInboxAndFocus(onView: focus)
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
        )
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
