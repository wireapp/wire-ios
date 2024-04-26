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

enum ConversationListState {
    case conversationList
    case archived
    case settings
    case peoplePicker
}

final class ConversationListViewController: UIViewController, ConversationListContainerViewModelDelegate {

    let viewModel: ViewModel

    /// internal View Model
    var state: ConversationListState = .conversationList

    /// private
    private var viewDidAppearCalled = false
    private static let contentControllerBottomInset: CGFloat = 16
    private let selfProfileViewControllerBuilder: ViewControllerBuilder
    let settingsViewControllerBuilder: ViewControllerBuilder

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    var startCallToken: Any?

    var pushPermissionDeniedViewController: PermissionDeniedViewController?

    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()

    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundConversationListTableViewCell
        return view
    }()

    let listContentController: ConversationListContentController
    let tabBar = ConversationListTabBar()
    let topBarViewController: ConversationListTopBarViewController
    let networkStatusViewController = NetworkStatusViewController()
    let onboardingHint = ConversationListOnboardingHint()

    convenience init(
        account: Account,
        selfUser: SelfUserType,
        userSession: UserSession,
        selfProfileViewControllerBuilder: ViewControllerBuilder,
        settingsViewControllerBuilder: ViewControllerBuilder
    ) {
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            userSession: userSession
        )
        self.init(
            viewModel: viewModel,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder,
            settingsViewControllerBuilder: settingsViewControllerBuilder
        )
        onboardingHint.arrowPointToView = tabBar
    }

    required init(
        viewModel: ViewModel,
        selfProfileViewControllerBuilder: ViewControllerBuilder,
        settingsViewControllerBuilder: ViewControllerBuilder
    ) {
        self.viewModel = viewModel
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder
        self.settingsViewControllerBuilder = settingsViewControllerBuilder

        topBarViewController = ConversationListTopBarViewController(
            account: viewModel.account,
            selfUser: viewModel.selfUser,
            userSession: viewModel.userSession,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder
        )

        let bottomInset = ConversationListViewController.contentControllerBottomInset
        listContentController = ConversationListContentController(userSession: viewModel.userSession)
        listContentController.collectionView.contentInset = .init(top: 0, left: 0, bottom: bottomInset, right: 0)

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        /// setup UI
        view.addSubview(contentContainer)
        view.backgroundColor = SemanticColors.View.backgroundConversationList

        setupTopBar()
        setupListContentController()
        setupTabBar()
        setupNoConversationLabel()
        setupOnboardingHint()
        setupNetworkStatusBar()

        createViewConstraints()

        viewModel.viewController = self
        topBarViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PassthroughTouchesView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update
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

        state = .conversationList

        closePushPermissionDialogIfNotNeeded()

        shouldAnimateNetworkStatusView = true

        ZClientViewController.shared?.notifyUserOfDisabledAppLockIfNeeded()

        if !viewDidAppearCalled {
            viewDidAppearCalled = true

            ZClientViewController.shared?.showDataUsagePermissionDialogIfNeeded()
            ZClientViewController.shared?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tabBar.subviews.forEach { barButton in
            if let label = barButton.subviews[1] as? UILabel {
                label.sizeToFit()
            }
        }
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    // MARK: - setup UI

    private func setupObservers() {
        viewModel.setupObservers()
    }

    private func setupTopBar() {
        add(topBarViewController, to: contentContainer)
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

    private func setupTabBar() {
        tabBar.delegate = self
        contentContainer.addSubview(tabBar)
        tabBar.unselectedItemTintColor = SemanticColors.Label.textTabBar
    }

    private func setupNetworkStatusBar() {
        networkStatusViewController.delegate = self
        add(networkStatusViewController, to: contentContainer)
    }

    private func createViewConstraints() {
        guard
            let topBarView = topBarViewController.view,
            let conversationList = listContentController.view
        else { return }

        [
            contentContainer,
            topBarView,
            conversationList,
            tabBar,
            noConversationLabel,
            onboardingHint,
            networkStatusViewController.view
        ].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        let constraints: [NSLayoutConstraint] = [
            contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),

            networkStatusViewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            networkStatusViewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            networkStatusViewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            topBarView.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            topBarView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            conversationList.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            conversationList.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            conversationList.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            conversationList.bottomAnchor.constraint(equalTo: tabBar.topAnchor),

            onboardingHint.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: contentContainer.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: contentContainer.rightAnchor),

            tabBar.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: contentContainer.safeBottomAnchor),

            noConversationLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func createArchivedListViewController() -> ArchivedListViewController {
        let archivedViewController = ArchivedListViewController(userSession: viewModel.userSession)
        archivedViewController.delegate = viewModel
        return archivedViewController
    }

    func showNoContactLabel(animated: Bool = true) {
        if state != .conversationList { return }

        let closure = {
            let hasArchivedConversations = self.viewModel.hasArchivedConversations
            self.noConversationLabel.alpha = hasArchivedConversations ? 1.0 : 0.0
            self.onboardingHint.alpha = hasArchivedConversations ? 0.0 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.20, animations: closure)
        } else {
            closure()
        }
    }

    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.20 : 0.0) {
            self.noConversationLabel.alpha = 0.0
            self.onboardingHint.alpha = 0.0
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        topBarViewController.scrollViewDidScroll(scrollView: scrollView)
    }

    /// Scroll to the current selection
    ///
    /// - Parameter animated: perform animation or not
    func scrollToCurrentSelection(animated: Bool) {
        listContentController.scrollToCurrentSelection(animated: animated)
    }

    func createPeoplePickerController() -> StartUIViewController {
        let startUIViewController = StartUIViewController(userSession: viewModel.userSession)
        startUIViewController.delegate = viewModel
        return startUIViewController
    }

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

    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler) {
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(presentViewController: self, completionHandler: completionHandler)
    }
}

// MARK: - UITabBarDelegate

extension ConversationListViewController: UITabBarDelegate {

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tabBar = tabBar as? ConversationListTabBar, let type = item.type else { return }

        switch type {
        case .startUI:
            setState(.peoplePicker, animated: true) {
                tabBar.selectedTab = .list
            }
        case .archive:
            setState(.archived, animated: true) {
                tabBar.selectedTab = .list
            }
        case .list:
            listContentController.listViewModel.folderEnabled = false
        case .settings:
            // presentSettings()
            assertionFailure("TODO [WPB-7306]: implement showing settings as tab")
        }
    }
}

extension UITabBarItem {

    var type: TabBarItemType? {
        .allCases.first { $0.rawValue == tag }
    }
}

private extension NSAttributedString {

    static var attributedTextForNoConversationLabel: NSAttributedString? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)

        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.smallMediumFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        paragraphStyle.paragraphSpacing = 4

        let titleString = L10n.Localizable.ConversationList.Empty.AllArchived.message

        let attributedString = NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)

        return attributedString
    }
}

extension UITabBar {
    // Workaround for new UITabBar behavior where on iPad,
    // the UITabBar shows the UITabBarItem icon next to the text
    override open var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UITraitCollection(traitsFrom: [super.traitCollection, UITraitCollection(horizontalSizeClass: .compact)])
        }
        return super.traitCollection
    }
}

// MARK: - ConversationListTopBarViewControllerDelegate

extension ConversationListViewController: ConversationListTopBarViewControllerDelegate {

    func conversationListTopBarViewControllerDidSelectNewConversation(_ viewController: ConversationListTopBarViewController) {
        setState(.peoplePicker, animated: true)
    }
}
