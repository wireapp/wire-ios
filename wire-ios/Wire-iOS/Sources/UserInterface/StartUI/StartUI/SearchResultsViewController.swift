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
import WireLogging
import WireSyncEngine

enum SearchGroup: Int {
    case people
    case apps
    case bots
}

extension SearchGroup {

    var accessible: Bool {
        switch self {
        case .people:
            return true
        case .apps, .bots:
            guard let user = SelfUser.provider?.providedSelfUser else {
                assertionFailure("expected available 'user'!")
                return false
            }
            return user.canCreateService
        }
    }

    #if ADD_SERVICE_DISABLED
        // remove service from the tab
        static func all(for messageProtocol: MessageProtocol) -> [SearchGroup] { [.people] }
    #else
        static func all(for messageProtocol: MessageProtocol) -> [SearchGroup] {
            switch messageProtocol {
            case .mls:
                [.people, .apps]
                    .filter(\.accessible)
            case .proteus:
                [.people, .bots]
                    .filter(\.accessible)
            case .mixed:
                [.people]
            }
        }
    #endif

    var name: String {
        switch self {
        case .people:
            L10n.Localizable.Peoplepicker.Header.people
        case .apps, .bots:
            L10n.Localizable.Peoplepicker.Header.apps
        }
    }
}

enum SearchResultsViewControllerMode: Int {
    case search
    case selection
    case list
}

enum SearchResultsViewControllerSection: Int {
    case unknown
    case topPeople
    case contacts
    case teamMembers
    case conversations
    case directory
    case apps
    case bots
    case federation
    case inviteTeamMember
}

extension UIViewController {
    final class ControllerHierarchyIterator: IteratorProtocol {
        private var current: UIViewController

        init(controller: UIViewController) {
            self.current = controller
        }

        func next() -> UIViewController? {
            var candidate: UIViewController? = .none
            if let controller = current.navigationController {
                candidate = controller
            } else if let controller = current.presentingViewController {
                candidate = controller
            } else if let controller = current.parent {
                candidate = controller
            }
            if let candidate {
                current = candidate
            }
            return candidate
        }
    }

    func isContainedInPopover() -> Bool {
        var hierarchy = ControllerHierarchyIterator(controller: self)

        return hierarchy.any {
            if let arrowDirection = $0.popoverPresentationController?.arrowDirection,
               arrowDirection != .unknown {
                true
            } else {
                false
            }
        }
    }
}

final class SearchResultsViewController: UIViewController {

    lazy var searchResultsView: SearchResultsView = {
        let view = SearchResultsView()
        view.parentViewController = self

        return view
    }()

    private let userSelection: UserSelection
    private let userSession: UserSession
    private let searchUsersUseCase: SearchUsersUseCaseProtocol
    private var pendingSearchTask: Task<Void, Never>?

    let sectionController: SectionCollectionViewController = .init()
    let contactsSection: ContactsSectionController = .init()
    let teamMemberAndContactsSection: ContactsSectionController = .init()
    let directorySection: DirectorySectionController
    let conversationsSection: GroupConversationsSectionController = .init()
    let federationSection = FederationSectionController()

    private(set) lazy var topPeopleSection = {
        let zmUserSession = userSession as? ZMUserSession
        let directory = zmUserSession?.topConversationsDirectory
        return TopPeopleSectionController(topConversationsDirectory: directory, userSession: userSession)
    }()

    let appsSection: SearchAppsSectionController
    let botsSection: SearchAppsSectionController

    let inviteTeamMemberSection: InviteTeamMemberSection

    var isAddingParticipants: Bool
    let isFederationEnabled: Bool
    private var viewModel: SearchResultsViewModel
    var searchGroup: SearchGroup = .people {
        didSet {
            viewModel.searchGroup = searchGroup
            updateVisibleSections()
        }
    }

    var filterConversation: ZMConversation?
    let shouldIncludeGuests: Bool

    weak var delegate: SearchResultsViewControllerDelegate?

    var mode: SearchResultsViewControllerMode = .search {
        didSet {
            viewModel.mode = mode
            updateVisibleSections()
        }
    }

    init?(
        userSelection: UserSelection,
        userSession: UserSession,
        isAddingParticipants: Bool = false,
        shouldIncludeGuests: Bool,
        isFederationEnabled: Bool
    ) {
        guard let searchUsersUseCase = userSession.makeSearchUsersUseCase() else { return nil }

        self.userSelection = userSelection
        self.userSession = userSession
        self.isAddingParticipants = isAddingParticipants
        self.mode = .list
        self.shouldIncludeGuests = shouldIncludeGuests
        self.isFederationEnabled = isFederationEnabled
        self.searchUsersUseCase = searchUsersUseCase
        self.viewModel = SearchResultsViewModel(
            isAddingParticipants: isAddingParticipants,
            hasTeam: userSession.selfUser.membership?.team != nil,
            shouldIncludeGuests: shouldIncludeGuests
        )

        let team = userSession.selfUser.membership?.team
        let teamName = team?.name

        contactsSection.selection = userSelection
        contactsSection.title = L10n.Localizable.Peoplepicker.Header.contactsPersonal
        contactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.selection = userSelection
        teamMemberAndContactsSection.title = L10n.Localizable.Peoplepicker.Header.contacts
        self.appsSection = SearchAppsSectionController(canSelfUserManageTeam: userSession.selfUser.canManageTeam)
        self.botsSection = SearchAppsSectionController(canSelfUserManageTeam: userSession.selfUser.canManageTeam)
        conversationsSection.title = team != nil ? L10n.Localizable.Peoplepicker.Header
            .teamConversations(teamName ?? "") : L10n.Localizable.Peoplepicker.Header.conversations
        self.inviteTeamMemberSection = InviteTeamMemberSection(team: team)
        self.directorySection = DirectorySectionController(userSession: userSession)

        super.init(nibName: nil, bundle: nil)

        contactsSection.delegate = self
        teamMemberAndContactsSection.delegate = self
        directorySection.delegate = self
        topPeopleSection.delegate = self
        conversationsSection.delegate = self
        appsSection.delegate = self
        botsSection.delegate = self
        inviteTeamMemberSection.delegate = self
        federationSection.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = searchResultsView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sectionController.collectionView?.reloadData()
        sectionController.collectionView?.collectionViewLayout.invalidateLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sectionController.collectionView = searchResultsView.collectionView

        updateVisibleSections()

        searchResultsView.emptyResultContainer.isHidden = !isResultEmpty
    }

    private func performSearch(
        query: String,
        options: SearchOptions
    ) {
        pendingSearchTask?.cancel()
        searchResultsView.emptyResultContainer.isHidden = true

        pendingSearchTask = Task {
            var options = options
            options.updateForSelfUserTeamRole(selfUser: userSession.selfUser)

            let result = await searchUsersUseCase.invoke(
                query: query,
                options: options,
                messageProtocol: filterConversation?.messageProtocol
            )

            handleSearchResult(result: result)
        }
    }

    func searchForUsers(withQuery query: String) {
        var options: SearchOptions = [
            .conversations,
            .contacts,
            .teamMembers,
            .directory
        ]

        if isFederationEnabled {
            options.formUnion(.federated)
        }

        performSearch(query: query, options: options)
    }

    func searchForLocalUsers(withQuery query: String) {
        performSearch(query: query, options: [.contacts, .teamMembers])
    }

    func searchForApps(withQuery query: String) {
        performSearch(query: query, options: [.apps])
    }

    func searchForBots(withQuery query: String) {
        performSearch(query: query, options: [.bots])
    }

    func searchContactList() {
        searchForLocalUsers(withQuery: "")
    }

    var isResultEmpty: Bool = true {
        didSet {
            searchResultsView.emptyResultContainer.isHidden = !isResultEmpty
        }
    }

    func handleSearchResult(result: SearchResult) {
        updateSections(withSearchResult: result)
        isResultEmpty = sectionController.visibleSections.isEmpty
    }

    func updateVisibleSections() {
        viewModel.isAddingParticipants = isAddingParticipants
        viewModel.hasTeam = userSession.selfUser.membership?.team != nil
        sectionController.sections = viewModel.visibleSections.map(sectionController(for:))
    }

    func updateSections(withSearchResult searchResult: SearchResult) {
        let content = viewModel.sectionContent(
            from: searchResult,
            excludingParticipantsOf: filterConversation
        )

        contactsSection.contacts = content.contacts
        teamMemberAndContactsSection.contacts = content.teamMembersAndContacts
        directorySection.suggestions = content.directory
        conversationsSection.groupConversations = content.conversations
        appsSection.apps = content.apps
        botsSection.apps = content.bots
        federationSection.users = content.federation

        sectionController.collectionView?.reloadData()
    }

    func emptyStateInput(for query: String) -> SearchResultsEmptyStateInput {
        viewModel.emptyStateInput(for: query)
    }

    private func sectionController(
        for section: SearchResultsViewControllerSection
    ) -> CollectionViewSectionController {
        switch section {
        case .topPeople:
            topPeopleSection
        case .contacts:
            contactsSection
        case .teamMembers:
            teamMemberAndContactsSection
        case .conversations:
            conversationsSection
        case .directory:
            directorySection
        case .apps:
            appsSection
        case .bots:
            botsSection
        case .federation:
            federationSection
        case .inviteTeamMember:
            inviteTeamMemberSection
        case .unknown:
            fatal("unknown search results section")
        }
    }

    func sectionFor(controller: CollectionViewSectionController) -> SearchResultsViewControllerSection {
        if controller === topPeopleSection {
            .topPeople
        } else if controller === contactsSection {
            .contacts
        } else if controller === teamMemberAndContactsSection {
            .teamMembers
        } else if  controller === conversationsSection {
            .conversations
        } else if controller === directorySection {
            .directory
        } else if controller === appsSection {
            .apps
        } else if controller === botsSection {
            .bots
        } else if controller === federationSection {
            .federation
        } else if controller === inviteTeamMemberSection {
            .inviteTeamMember
        } else {
            .unknown
        }
    }

}

extension SearchResultsViewController: SearchSectionControllerDelegate {

    func searchSectionController(
        _ searchSectionController: CollectionViewSectionController,
        didSelectUser user: UserType,
        at indexPath: IndexPath
    ) {
        if let user = user as? ZMUser, user.type == .regular {
            delegate?.searchResultsViewController(
                self,
                didTapOnUser: user,
                indexPath: indexPath,
                section: sectionFor(controller: searchSectionController)
            )
        } else if let user = user as? ZMUser, user.type == .app {
            delegate?.searchResultsViewController(self, didTapOnApp: user)
        } else if user.isAppOrBot {
            delegate?.searchResultsViewController(self, didTapOnBot: user)
        } else if let searchUser = user as? ZMSearchUser {
            delegate?.searchResultsViewController(
                self,
                didTapOnUser: searchUser,
                indexPath: indexPath,
                section: sectionFor(controller: searchSectionController)
            )
        }
    }

    func searchSectionController(
        _ searchSectionController: CollectionViewSectionController,
        didSelectConversation conversation: ZMConversation,
        at indexPath: IndexPath
    ) {
        delegate?.searchResultsViewController(self, didTapOnConversation: conversation)
    }

    func searchSectionController(
        _ searchSectionController: CollectionViewSectionController,
        wantsToDisplayError error: LocalizedError
    ) {
        presentLocalizedErrorAlert(error)
    }

}

extension SearchResultsViewController: InviteTeamMemberSectionDelegate {
    func inviteSectionDidRequestTeamManagement() {
        URL.manageTeam(source: .onboarding).open(from: self)
    }
}

extension SearchResultsViewController: SearchAppsSectionDelegate {
    func addBotsSectionDidRequestOpenBotsAdmin() {
        URL.manageTeam(source: .settings).open(from: self)
    }
}
