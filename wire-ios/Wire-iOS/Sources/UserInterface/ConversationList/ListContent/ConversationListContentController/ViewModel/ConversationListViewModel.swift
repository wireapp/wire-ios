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

import Combine
import DifferenceKit
import Foundation
import WireDataModel
import WireMainNavigationUI
import WireRequestStrategy
import WireSyncEngine
import WireSystem

final class ConversationListViewModel: NSObject {

    typealias SectionIdentifier = String

    var selectedFilter: ConversationFilter? {
        didSet {
            reloadConversationList()
        }
    }

    var appliedSearchText = "" {
        didSet { reloadConversationList() }
    }

    struct Section: DifferentiableSection {

        enum Kind: Equatable, Hashable {

            /// for incoming requests
            case contactRequests

            /// for self pending requests / conversations
            case conversations

            /// one to one conversations
            case contacts

            /// group conversations
            case groups

            /// channel conversations
            case channels

            /// favorites
            case favorites

            /// conversations in folders
            case folder(label: LabelType)

            func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }

            var identifier: SectionIdentifier {
                switch self {
                case .contactRequests:
                    "contactRequests"
                case .conversations:
                    "conversations"
                case .contacts:
                    "contacts"
                case .groups:
                    "groups"
                case .channels:
                    "channels"
                case .favorites:
                    "favorites"
                case let .folder(label: label):
                    label.remoteIdentifier?.transportString() ?? "folder"
                }
            }

            static func == (
                lhs: ConversationListViewModel.Section.Kind,
                rhs: ConversationListViewModel.Section.Kind
            ) -> Bool {
                switch (lhs, rhs) {
                case (.conversations, .conversations):
                    true
                case (.contactRequests, .contactRequests):
                    true
                case (.contacts, .contacts):
                    true
                case (.groups, .groups):
                    true
                case (.channels, .channels):
                    true
                case (.favorites, .favorites):
                    true
                case let (.folder(lhsLabel), .folder(rhsLabel)):
                    lhsLabel === rhsLabel
                default:
                    false
                }
            }
        }

        var kind: Kind
        var items: [SectionItem]

        var elements: [SectionItem] {
            items
        }

        /// ref to AggregateArray, we return the first found item's index
        ///
        /// - Parameter item: item to search
        /// - Returns: the index of the item
        func index(for item: ConversationListItem) -> Int? {
            items.firstIndex(of: SectionItem(item: item, kind: kind))
        }

        func isContentEqual(to source: ConversationListViewModel.Section) -> Bool {
            kind == source.kind
        }

        var differenceIdentifier: String {
            kind.identifier
        }

        init(source: ConversationListViewModel.Section, elements: some Collection<SectionItem>) {
            self.kind = source.kind
            self.items = Array(elements)
        }

        init(
            kind: Kind,
            conversationDirectory: ConversationDirectoryType,
            selectedFilter: ConversationFilter? = nil
        ) {
            self.items = ConversationListViewModel.newList(
                for: kind,
                conversationDirectory: conversationDirectory,
                selectedFilter: selectedFilter
            )
            self.kind = kind
        }
    }

    static let contactRequestsItem: ConversationListConnectRequestsItem = .init()

    /// current selected ZMConversaton or ConversationListConnectRequestsItem object
    private(set) var selectedItem: ConversationListItem?

    weak var delegate: ConversationListViewModelDelegate?

    // Local copies of the lists.
    private var sections: [Section] = []

    var isEmptyList: Bool {
        let totalItems = sections.map(\.items.count).reduce(0, +)
        return totalItems == 0
    }

    private typealias DiffKitSection = ArraySection<Int, SectionItem>

    /// make items has different hash in different sections
    struct SectionItem: Hashable, Differentiable {
        let item: ConversationListItem
        let isFavorite: Bool

        fileprivate init(item: ConversationListItem, kind: Section.Kind) {
            self.item = item
            self.isFavorite = kind == .favorites
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isFavorite)

            let hashableItem: NSObject = item
            hasher.combine(hashableItem)
        }

        static func == (lhs: SectionItem, rhs: SectionItem) -> Bool {
            lhs.isFavorite == rhs.isFavorite &&
                lhs.item == rhs.item
        }
    }

    private var conversationDirectoryToken: Any?
    private var tokens = Set<AnyCancellable>()

    let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession

        super.init()

        setupObservers()
        updateAllSections()
    }

    private func setupObservers() {
        conversationDirectoryToken = userSession.conversationDirectory.addObserver(self)

        // TODO: [WPB-15469] Remove casting and see if there is a better way to call `refreshAllLists`.
        guard let user = userSession.selfUser as? ZMUser else { return }

        user.publisher(for: \.teamIdentifier)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak userSession] _ in
                guard let userSession, !userSession.isTornDown else { return }

                userSession.conversationDirectory.refetchAllLists(in: userSession.contextProvider.viewContext)
            }.store(in: &tokens)
    }

    private func kind(of sectionIndex: Int) -> Section.Kind? {
        guard sections.indices.contains(sectionIndex) else { return nil }

        return sections[sectionIndex].kind
    }

    var sectionCount: Int {
        sections.count
    }

    func numberOfItems(inSection sectionIndex: Int) -> Int {
        guard sections.indices.contains(sectionIndex) else { return 0 }

        return sections[sectionIndex].elements.count
    }

    func section(at sectionIndex: Int) -> [ConversationListItem]? {
        if sectionIndex >= sectionCount {
            return nil
        }

        return sections[sectionIndex].elements.map(\.item)
    }

    func item(for indexPath: IndexPath) -> ConversationListItem? {
        guard let items = section(at: indexPath.section),
              items.indices.contains(indexPath.item) else { return nil }

        return items[indexPath.item]
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: Question: we may have multiple items in folders now. return array of IndexPaths?
    func indexPath(for item: ConversationListItem?) -> IndexPath? {
        guard let item else { return nil }

        for (sectionIndex, section) in sections.enumerated() {
            if let index = section.index(for: item) {
                return IndexPath(item: index, section: sectionIndex)
            }
        }

        return nil
    }

    private static func newList(
        for kind: Section.Kind,
        conversationDirectory: ConversationDirectoryType,
        selectedFilter: ConversationFilter? = nil
    ) -> [SectionItem] {
        let conversationListType: ConversationListType
        switch kind {
        case .contactRequests:
            conversationListType = .pending
            return conversationDirectory.conversations(by: conversationListType).isEmpty ? [] : [SectionItem(
                item: contactRequestsItem,
                kind: kind
            )]
        case .conversations:
            // Check if we have a special filter active
            switch selectedFilter {
            case .unread:
                conversationListType = .unread
            case .mentions:
                conversationListType = .mentions
            case .replies:
                conversationListType = .replies
            case .drafts:
                conversationListType = .drafts
            case .none, .favorites, .groups, .channels, .oneOnOne, .folder:
                conversationListType = .unarchived
            }
        case .contacts:
            conversationListType = .contacts
        case .groups:
            conversationListType = .groups
        case .channels:
            conversationListType = .channels
        case .favorites:
            conversationListType = .favorites
        case let .folder(label: label):
            conversationListType = .folder(label)
        }

        return conversationDirectory.conversations(by: conversationListType).filter { !$0.hasIncompleteMetadata }
            .map { SectionItem(
                item: $0,
                kind: kind
            ) }

    }

    func reloadConversationList() {
        updateAllSections()
        delegate?.listViewModelShouldBeReloaded()
    }

    private func updateAllSections() {
        sections = createSections()
    }

    /// Create the section structure
    func createSections() -> [Section] {
        let conversationDirectory = userSession.conversationDirectory

        // Filter sections based on the selected filter
        let kinds: [Section.Kind] = switch selectedFilter {
        case .groups:
            [.groups]
        case .channels:
            [.channels]
        case .favorites:
            [.favorites]
        case .oneOnOne:
            [.contactRequests, .contacts]
        case let .folder(id, _):
            if let folder = conversationDirectory.nonDeletedFolders.first(where: { $0.remoteIdentifier == id }) {
                [.folder(label: folder)]
            } else {
                []
            }
        case .unread, .mentions, .replies, .drafts:
            // These filters have their own conversation lists in the data layer
            [.conversations]
        case .none:
            [.contactRequests, .conversations]
        }

        let sections = kinds.map { kind in
            Section(
                kind: kind,
                conversationDirectory: conversationDirectory,
                selectedFilter: selectedFilter
            )
        }

        let filterUseCase = FilterConversationsUseCase(conversationContainers: sections)
        return filterUseCase.invoke(query: appliedSearchText)
    }

    private func sectionNumber(for kind: Section.Kind) -> Int? {
        for (index, section) in sections.enumerated() where section.kind == kind {
            return index
        }

        return nil
    }

    private func update(for kind: Section.Kind? = nil) {
        let conversationDirectory = userSession.conversationDirectory

        var newValue: [Section]
        if let kind,
           let sectionNumber = sectionNumber(for: kind) {
            newValue = sections
            let newList = ConversationListViewModel.newList(
                for: kind,
                conversationDirectory: conversationDirectory,
                selectedFilter: selectedFilter
            )

            newValue[sectionNumber].items = newList

            // Refresh the section header(since it may be hidden if the section is empty) when a section becomes
            // empty/from empty to non-empty
            if sections[sectionNumber].items.isEmpty || newList.isEmpty {
                sections = newValue
                delegate?.listViewModel(self, didUpdateSectionForReload: sectionNumber, animated: true)
                return
            }
        } else {
            newValue = createSections()
        }

        let changeset = StagedChangeset(source: sections, target: newValue)
        if changeset.isEmpty {
            sections = newValue
        } else {
            delegate?.reload(using: changeset, interrupt: { _ in
                false
            }, setData: { data in
                if let data {
                    self.sections = data
                }
            })
        }
    }

    @discardableResult
    func select(itemToSelect: ConversationListItem?) -> Bool {
        guard let itemToSelect else {
            internalSelect(itemToSelect: nil)
            return false
        }

        if indexPath(for: itemToSelect) == nil {
            guard let conversation = itemToSelect as? ZMConversation else { return false }

            userSession.enqueue {
                conversation.isArchived = false
            } completionHandler: {
                self.internalSelect(itemToSelect: itemToSelect)
            }
        } else {
            internalSelect(itemToSelect: itemToSelect)
        }

        return true
    }

    private func internalSelect(itemToSelect: ConversationListItem?) {
        selectedItem = itemToSelect

        if let itemToSelect {
            delegate?.listViewModel(self, didSelectItem: itemToSelect)
        }
    }
}

// MARK: - ZMUserObserving

private let log = ZMSLog(tag: "ConversationListViewModel")

// MARK: - ConversationDirectoryObserver

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(
        conversationDirectory: ConversationDirectoryType,
        changeInfo: ConversationDirectoryChangeInfo
    ) {

        if changeInfo.reloaded {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.
            update()
        } else {
            // swiftlint:disable todo_requires_jira_link
            // TODO: When 2 sections are visible and a conversation belongs to both, the lower section's update
            // animation is missing since it started after the top section update animation started. To fix this
            // we should calculate the change set in one batch.
            // TODO: wait for SE update for returning multiple items in changeInfo.updatedLists
            // swiftlint:enable todo_requires_jira_link
            for updatedList in changeInfo.updatedLists {
                if let kind = kind(of: updatedList) {
                    update(for: kind)
                }
            }
        }
    }

    private func kind(of conversationListType: ConversationListType) -> Section.Kind? {

        switch conversationListType {
        case .unarchived:
            .conversations
        case .contacts:
            .contacts
        case .pending:
            .contactRequests
        case .groups:
            .groups
        case .channels:
            .channels
        case .favorites:
            .favorites
        case .unread:
            .conversations
        case .mentions:
            .conversations
        case .replies:
            .conversations
        case .drafts:
            .conversations
        case let .folder(label):
            .folder(label: label)
        case .archived:
            nil
        }

    }
}

// MARK: - Section + MutableConversationContainer

extension ConversationListViewModel.Section: MutableConversationContainer {

    var conversations: [ZMFilterableConversationAdapter] {
        get {
            items
                .compactMap { $0.item as? ZMConversation }
                .map(ZMFilterableConversationAdapter.init(conversation:))
        }
        set {
            items = newValue.map { ConversationListViewModel.SectionItem(item: $0.conversation, kind: kind) }
        }
    }
}
