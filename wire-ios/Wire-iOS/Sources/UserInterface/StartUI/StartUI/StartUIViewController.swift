//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireCommonComponents
import WireDesign
import WireFoundation
import WireMainNavigationUI
import WireMessagingAssembly
import WireMessagingDomain
import WireMessagingUI
import WireReusableUIComponents
import WireSyncEngine
import WireUtilities

private let zmLog = ZMSLog(tag: "StartUIViewController")

final class StartUIViewController: UIViewController {

    // MARK: - Properties

    static let InitiallyShowsKeyboardConversationThreshold = 10

    weak var delegate: StartUIDelegate?

    let searchController = UISearchController(searchResultsController: nil)

    let groupSelector = SearchGroupSelector()

    lazy var conversationTypePicker: UIViewController = {
        let canCreateChannels = userSession.channelsFeature.canCreateChannels(
            role: userSession.selfUser.teamRole
        )

        let isTeamUser = userSession.selfUser.hasTeam

        let availableConversationTypes: Set<MultiParticipantConversationType> = if areChannelsSupported,
                                                                                   canCreateChannels {
            [.channel, .group]
        } else {
            [.group]
        }

        let view = ConversationTypePickerFactory().create(
            availableConversationTypes: availableConversationTypes,
            onConversationTypeSelected: { [weak self] selectedConversationType in
                guard let self else { return }
                switch selectedConversationType {
                case .group:
                    Task { @MainActor [weak self] in
                        self?.navigateToConversationCreation()
                    }
                case .channel:
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if canCreateChannels {
                            navigateToChannelCreation()
                        } else {
                            presentCreateTeamBanner()
                        }
                    }
                }
            }
        )
        let vc = UIHostingController(rootView: view)
        vc.sizingOptions = .intrinsicContentSize
        vc.view.backgroundColor = .clear
        return vc
    }()

    let searchResultsViewController: SearchResultsViewController

    let isAppsFeatureEnabled: Bool

    /// Teams cannot add old-style services (bots) anymore, but teams which have been using bots in the past, they should still be able to start 1:1 conversations with bots. (only if the team's default protocol is Proteus)
    let areLegacyBotsAvailable: Bool

    let userSession: UserSession

    let mainCoordinator: AnyMainCoordinator
    let createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol
    let channelConversationFormFactory: WireConversationChannelCreationFormViewControllerFactory
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol

    let isFederationEnabled: Bool

    let profilePresenter: ProfilePresenter
    private var emptyResultView: EmptySearchResultsView!

    private(set) var activityIndicator: BlockingActivityIndicator!

    let backgroundColor = SemanticColors.View.backgroundDefault

    var searchResults: SearchResultsViewController {
        searchResultsViewController
    }

    /// Whether there is a switch control for either listing/searching for users/people or apps/bots.
    ///
    /// The people/apps switch control will only be visible if
    /// - apps/bots are not disabled for this build (restricted clients),
    /// - the team's default protocol is Proteus the team has been using bots
    /// - the team's default protocol is MLS and the `apps` feature flag is enabled.
    var showsGroupSelector: Bool {
        guard SearchGroup.all.count > 1, userSession.selfUser.canSeeServices else { return false }

        switch userSession.defaultProtocol {
        case .mls:
            return isAppsFeatureEnabled
        case .proteus:
            return areLegacyBotsAvailable
        case .mixed:
            return false
        }
    }

    // MARK: - Init

    private var navigationBarTitle: String? {
        L10n.Localizable.Peoplepicker.NavigationHeader.title
    }

    init(
        areLegacyBotsAvailable: Bool,
        isAppsFeatureEnabled: Bool,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol,
        channelConversationFormFactory: WireConversationChannelCreationFormViewControllerFactory,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.areLegacyBotsAvailable = areLegacyBotsAvailable
        self.isAppsFeatureEnabled = isAppsFeatureEnabled
        self.isFederationEnabled = userSession.resolvedBackendMetadata.isFederationEnabled
        self.searchResultsViewController = SearchResultsViewController(
            userSelection: UserSelection(),
            userSession: userSession,
            isAddingParticipants: false,
            shouldIncludeGuests: true,
            isFederationEnabled: isFederationEnabled
        )
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.createGroupConversationUIBuilder = createGroupConversationUIBuilder
        self.channelConversationFormFactory = channelConversationFormFactory
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.profilePresenter = .init(
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
        super.init(nibName: nil, bundle: nil)

        configGroupSelector()
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        activityIndicator = .init(view: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = navigationBarTitle {
            setupNavigationBarTitle(title)
        }

        setupNavigationBarButtonItems()
    }

    override func accessibilityPerformEscape() -> Bool {
        _ = searchController.searchBar.resignFirstResponder()
        navigationController?.dismiss(animated: true)
        return true
    }

    // MARK: - Setup and configure views

    func setupViews() {
        configGroupSelector()
        configConversationTypePicker()
        emptyResultView = EmptySearchResultsView(
            isSelfUserAdmin: userSession.selfUser.canManageTeam,
            isFederationEnabled: isFederationEnabled
        )

        emptyResultView.delegate = self

        searchResultsViewController.mode = .list
        searchResultsViewController.searchResultsView.emptyResultView = emptyResultView
        searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        setupSearchController()

        if showsGroupSelector {
            view.addSubview(groupSelector)
        }
        view.addSubview(conversationTypePicker.view)

        searchResults.delegate = self
        addToSelf(searchResults)
        searchResults.searchResultsView.emptyResultView = emptyResultView
        searchResults.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        createConstraints()
        searchResults.searchContactList()

        view.accessibilityViewIsModal = true
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = L10n.Localizable.Peoplepicker.searchPlaceholder
        searchController.searchBar.accessibilityIdentifier = "textViewSearch"
        navigationItem.searchController = searchController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configGroupSelector() {
        groupSelector.translatesAutoresizingMaskIntoConstraints = false
        groupSelector.backgroundColor = backgroundColor
        groupSelector.onGroupSelected = { [weak self] group in
            if group == .services {
                self?.searchController.searchBar.text = ""
            }
            self?.searchResults.searchGroup = group
            self?.performSearch()
        }
    }

    private func configConversationTypePicker() {
        conversationTypePicker.view.translatesAutoresizingMaskIntoConstraints = false
        conversationTypePicker.view.backgroundColor = backgroundColor
        addChild(conversationTypePicker)
        conversationTypePicker.didMove(toParent: self)
    }

    // MARK: - Setup constraints

    private func createConstraints() {
        [groupSelector, searchResultsViewController.view]
            .forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        if showsGroupSelector {
            NSLayoutConstraint.activate([
                groupSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                groupSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                groupSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                conversationTypePicker.view.topAnchor.constraint(equalTo: groupSelector.bottomAnchor, constant: 24)
            ])
        } else {
            NSLayoutConstraint.activate([
                conversationTypePicker.view.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: 24
                )
            ])
        }

        NSLayoutConstraint.activate([
            conversationTypePicker.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            conversationTypePicker.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            searchResultsViewController.view.topAnchor.constraint(
                equalTo: conversationTypePicker.view.bottomAnchor,
                constant: 16
            ),
            searchResultsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func showKeyboardIfNeeded() {
        let conversationCount = userSession.conversationList().items.count
        if conversationCount > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            searchController.searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Instance methods

    @objc
    func performSearch() {
        let searchString = searchController.searchBar.text ?? ""
        zmLog.info("Search for \(searchString)")

        if groupSelector.group == .people {
            if searchString.isEmpty {
                searchResults.mode = .list
                searchResults.searchContactList()
            } else {
                searchResults.mode = .search
                searchResults.searchForUsers(withQuery: searchString)
            }
        } else {
            searchResults.searchForServices(withQuery: searchString)
        }
        emptyResultView.updateStatus(
            searchingForServices: groupSelector.group == .services,
            hasFilter: !searchString.isEmpty
        )
    }

    // MARK: - Navigation methods

    private func navigateToConversationCreation() {
        Task {
            let conversationCreationController = await createGroupConversationUIBuilder.build()
            navigationController?.pushViewController(conversationCreationController, animated: true)
        }
    }

    private func navigateToChannelCreation() {
        Task {
            let vc = await channelConversationFormFactory.create(userSession: userSession)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    /// Checks whether a channel can be created, conditions are:
    /// - conversation message protocol is MLS
    /// - conversation belongs to a team
    /// - MLS is enabled
    /// - API >= v8
    /// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/1712979983/Channels

    private var areChannelsSupported: Bool {
        guard let backendInfoApiVersion = userSession.resolvedBackendMetadata.apiVersion else {
            return false
        }
        guard userSession.isBackendMLSEnabled else {
            return false
        }
        guard backendInfoApiVersion >= .v8 else {
            return false
        }

        return true
    }

    private func presentCreateTeamBanner() {

        typealias Localizable = L10n.Localizable.Peoplepicker
        typealias Accessibility = L10n.Accessibility.Peoplepicker

        let configuration = ChannelBannerView.Configuration(
            title: Localizable.UpgradeBanner.headline,
            message: Localizable.UpgradeBanner.subheadline,
            mainButtonTitle: Localizable.UpgradeBanner.Button.title,
            mainButtonAction: { [weak self] in
                self?.dismiss(animated: true) { [weak self] in self?.presentPersonalToTeamMigration() }
            },
            closeButton: .init(
                accessibilityLabel: Accessibility.UpgradeBanner.CloseButton.label,
                action: { [weak self] in self?.dismiss(animated: true) }
            )
        )
        let banner = ChannelBannerView(configuration: configuration)
        // Dimmer that covers entire screen and intercepts taps
        let rootView = ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            banner
        }

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle   = .crossDissolve
        hostingController.overrideUserInterfaceStyle = .dark
        present(hostingController, animated: true)
    }

    private func presentPersonalToTeamMigration() {
        Task {
            let rootViewController = self.selfProfileUIBuilder.build(mainCoordinator: mainCoordinator)
            let navigationController = UINavigationController(rootViewController: rootViewController)
            navigationController.modalPresentationStyle = .formSheet
            navigationController.presentationController?.delegate = rootViewController
            await mainCoordinator.presentViewController(navigationController)
            if let selfProfileViewController = rootViewController as? SelfProfileViewController {
                selfProfileViewController.triggerCreateTeamFlow()
            }
        }
    }

}

// MARK: - UISearchResultsUpdating, UISearchBarDelegate

extension StartUIViewController: UISearchResultsUpdating, UISearchBarDelegate {

    func updateSearchResults(for searchController: UISearchController) {

        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(performSearch),
            object: nil
        )

        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        performSearch()
    }

}
