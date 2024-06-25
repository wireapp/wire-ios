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
import WireSyncEngine

enum SearchGroup: Int {
    case people
    case services
}

extension SearchGroup {

    var accessible: Bool {
        switch self {
        case .people:
            return true
        case .services:
            guard let user = SelfUser.provider?.providedSelfUser else {
                assertionFailure("expected available 'user'!")
                return false
            }
            return user.canCreateService
        }
    }

#if ADD_SERVICE_DISABLED
    // remove service from the tab
    static let all: [SearchGroup] = [.people]
#else
    static var all: [SearchGroup] {
        return [.people, .services].filter { $0.accessible }
    }
#endif

    var name: String {
        switch self {
        case .people:
            return L10n.Localizable.Peoplepicker.Header.people
        case .services:
            return L10n.Localizable.Peoplepicker.Header.services
        }
    }
}

protocol SearchResultsViewControllerDelegate: AnyObject {

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: UserType, indexPath: IndexPath, section: SearchResultsViewControllerSection)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: UserType, indexPath: IndexPath)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser user: ServiceUser)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, wantsToPerformAction action: SearchResultsViewControllerAction)
}

enum SearchResultsViewControllerAction: Int {
    case createGroup
    case createGuestRoom
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
    case services
    case federation
}

extension UIViewController {
    final class ControllerHierarchyIterator: IteratorProtocol {
        private var current: UIViewController

        init(controller: UIViewController) {
            current = controller
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
                return true
            } else {
                return false
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

    private lazy var searchDirectory: SearchDirectory? = {
        guard let session = userSession as? ZMUserSession else {
            return nil
        }

        return SearchDirectory(userSession: session)
    }()

    let userSelection: UserSelection
    let userSession: UserSession

    let sectionController: SectionCollectionViewController = SectionCollectionViewController()
    let contactsSection: ContactsSectionController = ContactsSectionController()
    let teamMemberAndContactsSection: ContactsSectionController = ContactsSectionController()
    let directorySection = DirectorySectionController()
    let conversationsSection: GroupConversationsSectionController = GroupConversationsSectionController()
    let federationSection = FederationSectionController()

    lazy var topPeopleSection: TopPeopleSectionController = {
        let zmUserSession = (userSession as? ZMUserSession)

        return TopPeopleSectionController(
            topConversationsDirectory: zmUserSession?.topConversationsDirectory,
            userSession: userSession
        )
    }()

    let servicesSection: SearchServicesSectionController
    let inviteTeamMemberSection: InviteTeamMemberSection
    let createGroupSection = CreateGroupSection()

    var pendingSearchTask: SearchTask?
    var isAddingParticipants: Bool
    let isFederationEnabled: Bool
    var searchGroup: SearchGroup = .people {
        didSet {
            updateVisibleSections()
        }
    }

    var filterConversation: ZMConversation?
    let shouldIncludeGuests: Bool

    weak var delegate: SearchResultsViewControllerDelegate?

    var mode: SearchResultsViewControllerMode = .search {
        didSet {
            updateVisibleSections()
        }
    }

    deinit {
        searchDirectory?.tearDown()
    }

    init(
        userSelection: UserSelection,
        userSession: UserSession,
        isAddingParticipants: Bool = false,
        shouldIncludeGuests: Bool,
        isFederationEnabled: Bool
    ) {
        self.userSelection = userSelection
        self.userSession = userSession
        self.isAddingParticipants = isAddingParticipants
        self.mode = .list
        self.shouldIncludeGuests = shouldIncludeGuests
        self.isFederationEnabled = isFederationEnabled

        let team = userSession.selfUser.membership?.team
        let teamName = team?.name

        contactsSection.selection = userSelection
        contactsSection.title = L10n.Localizable.Peoplepicker.Header.contactsPersonal
        contactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.selection = userSelection
        teamMemberAndContactsSection.title = L10n.Localizable.Peoplepicker.Header.contacts
        servicesSection = SearchServicesSectionController(canSelfUserManageTeam: userSession.selfUser.canManageTeam)
        conversationsSection.title = team != nil ? L10n.Localizable.Peoplepicker.Header.teamConversations(teamName ?? "") : L10n.Localizable.Peoplepicker.Header.conversations
        inviteTeamMemberSection = InviteTeamMemberSection(team: team)

        super.init(nibName: nil, bundle: nil)

        contactsSection.delegate = self
        teamMemberAndContactsSection.delegate = self
        directorySection.delegate = self
        topPeopleSection.delegate = self
        conversationsSection.delegate = self
        servicesSection.delegate = self
        createGroupSection.delegate = self
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
        searchDirectory?.updateIncompleteMetadataIfNeeded()
    }

    @objc
    func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }

    private func performSearch(query: String, options: SearchOptions) {
        let selfUser = userSession.selfUser

        pendingSearchTask?.cancel()
        searchResultsView.emptyResultContainer.isHidden = true

        var options = options
        options.updateForSelfUserTeamRole(selfUser: selfUser)

        let request = SearchRequest(
            query: query.trim(),
            searchOptions: options,
            team: selfUser.membership?.team
        )

        if let task = searchDirectory?.perform(request) {
            task.addResultHandler { [weak self] result, isCompleted in
                self?.handleSearchResult(result: result, isCompleted: isCompleted)
            }
            task.start()

            pendingSearchTask = task
        }
    }

    func searchForUsers(withQuery query: String) {
        var options: SearchOptions = [.conversations,
                                      .contacts,
                                      .teamMembers,
                                      .directory]

        if isFederationEnabled {
            options.formUnion(.federated)
        }

        performSearch(query: query, options: options)
    }

    func searchForLocalUsers(withQuery query: String) {
        performSearch(query: query, options: [.contacts, .teamMembers])
    }

    func searchForServices(withQuery query: String) {
        performSearch(query: query, options: [.services])
    }

    func searchContactList() {
        searchForLocalUsers(withQuery: "")
    }

    var isResultEmpty: Bool = true {
        didSet {
            searchResultsView.emptyResultContainer.isHidden = !isResultEmpty
        }
    }

    func handleSearchResult(result: SearchResult, isCompleted: Bool) {
        self.updateSections(withSearchResult: result)

        if isCompleted {
            isResultEmpty = sectionController.visibleSections.isEmpty
        }
    }

    func updateVisibleSections() {
        var sections: [CollectionViewSectionController]
        let team = userSession.selfUser.membership?.team

        switch(self.searchGroup, isAddingParticipants) {
        case (.services, _):
            sections = [servicesSection]
        case (.people, true):
            switch (mode, team != nil) {
            case (.search, false):
                sections = [contactsSection]
            case (.search, true):
                sections = [teamMemberAndContactsSection]
            case (.selection, false):
                sections = [contactsSection]
            case (.selection, true):
                sections = [teamMemberAndContactsSection]
            case (.list, false):
                sections = [contactsSection]
            case (.list, true):
                sections = [teamMemberAndContactsSection]
            }
        case (.people, false):
            switch (mode, team != nil) {
            case (.search, false):
                sections = [contactsSection, conversationsSection, directorySection, federationSection]
            case (.search, true):
                sections = [teamMemberAndContactsSection, conversationsSection, directorySection, federationSection]
            case (.selection, false):
                sections = [contactsSection]
            case (.selection, true):
                sections = [teamMemberAndContactsSection]
            case (.list, false):
                sections = [createGroupSection, topPeopleSection, contactsSection]
            case (.list, true):
                sections = [createGroupSection, inviteTeamMemberSection, teamMemberAndContactsSection]
            }
        }

        sectionController.sections = sections
    }

    func updateSections(withSearchResult searchResult: SearchResult) {

        var contacts = searchResult.contacts
        var teamContacts = searchResult.teamMembers

        if let filteredParticpants = filterConversation?.localParticipants {
            contacts = contacts.filter({
                guard let user = $0.user else {
                    return true
                }
                return !filteredParticpants.contains(user)
            })
            teamContacts = teamContacts.filter({
                guard let user = $0.user else {
                    return true
                }
                return !filteredParticpants.contains(user)
            })
        }

        contactsSection.contacts = contacts

        // Access mode is not set, or the guests are allowed.
        if shouldIncludeGuests {
            teamMemberAndContactsSection.contacts = Set(teamContacts + contacts).sorted {
                let name0 = $0.name ?? ""
                let name1 = $1.name ?? ""

                if name0 == name1 {
                    let pseudo0 = $0.handle ?? ""
                    let pseudo1 = $1.handle ?? ""
                    return pseudo0.compare(pseudo1) == .orderedAscending
                }
                return name0.compare(name1) == .orderedAscending
            }
        } else {
            teamMemberAndContactsSection.contacts = teamContacts
        }

        directorySection.suggestions = searchResult.directory.filter { !$0.isFederated }
        conversationsSection.groupConversations = searchResult.conversations
        servicesSection.services = searchResult.services
        federationSection.users = searchResult.directory.filter { $0.isFederated }

        sectionController.collectionView?.reloadData()
    }

    func sectionFor(controller: CollectionViewSectionController) -> SearchResultsViewControllerSection {
        if controller === topPeopleSection {
            return .topPeople
        } else if controller === contactsSection {
            return .contacts
        } else if controller === teamMemberAndContactsSection {
            return .teamMembers
        } else if  controller === conversationsSection {
            return .conversations
        } else if controller === directorySection {
            return .directory
        } else if controller === servicesSection {
            return .services
        } else if controller === federationSection {
            return .federation
        } else {
            return .unknown
        }
    }

}

extension SearchResultsViewController: SearchSectionControllerDelegate {

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectUser user: UserType, at indexPath: IndexPath) {
        if let user = user as? ZMUser {
            delegate?.searchResultsViewController(self, didTapOnUser: user, indexPath: indexPath, section: sectionFor(controller: searchSectionController))
        } else if let service = user as? ServiceUser, service.isServiceUser {
            delegate?.searchResultsViewController(self, didTapOnSeviceUser: service)
        } else if let searchUser = user as? ZMSearchUser {
            delegate?.searchResultsViewController(self, didTapOnUser: searchUser, indexPath: indexPath, section: sectionFor(controller: searchSectionController))
        }
    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectConversation conversation: ZMConversation, at indexPath: IndexPath) {
        delegate?.searchResultsViewController(self, didTapOnConversation: conversation)
    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectRow row: CreateGroupSection.Row, at indexPath: IndexPath) {
        switch row {
        case .createGroup:
            delegate?.searchResultsViewController(self, wantsToPerformAction: .createGroup)
        case .createGuestRoom:
            delegate?.searchResultsViewController(self, wantsToPerformAction: .createGuestRoom)
        }

    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, wantsToDisplayError error: LocalizedError) {
        presentLocalizedErrorAlert(error)
    }

}

extension SearchResultsViewController: InviteTeamMemberSectionDelegate {
    func inviteSectionDidRequestTeamManagement() {
        URL.manageTeam(source: .onboarding).openInApp(above: self)
    }
}

extension SearchResultsViewController: SearchServicesSectionDelegate {
    func addServicesSectionDidRequestOpenServicesAdmin() {
        URL.manageTeam(source: .settings).openInApp(above: self)
    }
}
