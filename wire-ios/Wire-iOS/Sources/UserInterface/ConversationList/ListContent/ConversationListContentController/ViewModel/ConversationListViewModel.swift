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

import DifferenceKit
import Foundation
import WireDataModel
import WireRequestStrategy
import WireSyncEngine
import WireSystem

// MARK: - ConversationListViewModel

final class ConversationListViewModel: NSObject {
    // MARK: Lifecycle

    init(
        userSession: UserSession,
        isFolderStatePersistenceEnabled: Bool
    ) {
        self.userSession = userSession
        self.isFolderStatePersistenceEnabled = isFolderStatePersistenceEnabled

        super.init()

        setupObservers()
        updateAllSections()
    }

    // MARK: Internal

    typealias SectionIdentifier = String

    /// make items has different hash in different sections
    struct SectionItem: Hashable, Differentiable {
        // MARK: Lifecycle

        fileprivate init(item: ConversationListItem, kind: Section.Kind) {
            self.item = item
            self.isFavorite = kind == .favorites
        }

        // MARK: Internal

        let item: ConversationListItem
        let isFavorite: Bool

        static func == (lhs: SectionItem, rhs: SectionItem) -> Bool {
            lhs.isFavorite == rhs.isFavorite &&
                lhs.item == rhs.item
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isFavorite)

            let hashableItem: NSObject = item
            hasher.combine(hashableItem)
        }
    }

    static let contactRequestsItem = ConversationListConnectRequestsItem()

    static var persistentURL: URL? {
        guard let persistentDirectory else { return nil }

        return URL.directoryURL(persistentDirectory)?
            .appendingPathComponent(ConversationListViewModel.persistentFilename)
    }

    // MARK: - state presistent

    let isFolderStatePersistenceEnabled: Bool

    /// current selected ZMConversaton or ConversationListConnectRequestsItem object
    private(set) var selectedItem: ConversationListItem? {
        didSet {
            /// expand the section if selcted item is update
            guard let indexPath = indexPath(for: selectedItem),
                  collapsed(at: indexPath.section) else { return }

            setCollapsed(sectionIndex: indexPath.section, collapsed: false, batchUpdate: false)
        }
    }

    weak var delegate: ConversationListViewModelDelegate? {
        didSet {
            delegateFolderEnableState(newState: state)
        }
    }

    var folderEnabled: Bool {
        get {
            state.folderEnabled
        }

        set {
            guard newValue != state.folderEnabled else { return }

            state.folderEnabled = newValue

            updateAllSections()
            delegate?.listViewModelShouldBeReloaded()
            delegateFolderEnableState(newState: state)
        }
    }

    var sectionCount: Int {
        sections.count
    }

    var jsonString: String? {
        state.jsonString
    }

    func sectionHeaderTitle(sectionIndex: Int) -> String? {
        kind(of: sectionIndex)?.localizedName
    }

    /// return true if seaction header is visible.
    /// For .contactRequests section it is always invisible
    /// When folderEnabled == true, returns false
    ///
    /// - Parameter sectionIndex: section number of collection view
    /// - Returns: if the section exists and visible, return true.
    func sectionHeaderVisible(section: Int) -> Bool {
        guard sections.indices.contains(section),
              kind(of: section) != .contactRequests,
              folderEnabled else { return false }

        return !sections[section].items.isEmpty
    }

    /// Section's canonical name
    ///
    /// - Parameter sectionIndex: section index of the collection view
    /// - Returns: canonical name
    func sectionCanonicalName(of sectionIndex: Int) -> String? {
        kind(of: sectionIndex)?.canonicalName
    }

    func obfuscatedSectionName(of sectionIndex: Int) -> String? {
        kind(of: sectionIndex)?.obfuscatedName
    }

    func numberOfItems(inSection sectionIndex: Int) -> Int {
        guard sections.indices.contains(sectionIndex),
              !collapsed(at: sectionIndex) else { return 0 }

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

    @discardableResult
    func select(itemToSelect: ConversationListItem?) -> Bool {
        guard let itemToSelect else {
            internalSelect(itemToSelect: nil)
            return false
        }

        if indexPath(for: itemToSelect) == nil {
            guard let conversation = itemToSelect as? ZMConversation else { return false }

            ZMUserSession.shared()?.enqueue({
                conversation.isArchived = false
            }, completionHandler: {
                self.internalSelect(itemToSelect: itemToSelect)
            })
        } else {
            internalSelect(itemToSelect: itemToSelect)
        }

        return true
    }

    // MARK: - folder badge

    func folderBadge(at sectionIndex: Int) -> Int {
        sections[sectionIndex].items.filter {
            let status = ($0.item as? ZMConversation)?.status
            return status?.messagesRequiringAttention.isEmpty == false &&
                status?.showingAllMessages == true
        }.count
    }

    // MARK: - collapse section

    func collapsed(at sectionIndex: Int) -> Bool {
        collapsed(at: sectionIndex, state: state)
    }

    /// set a collpase state of a section
    ///
    /// - Parameters:
    ///   - sectionIndex: section to update
    ///   - collapsed: collapsed or expanded
    ///   - batchUpdate: true for update with difference kit comparison, false for reload the section animated
    func setCollapsed(
        sectionIndex: Int,
        collapsed: Bool,
        batchUpdate: Bool = true
    ) {
        guard let conversationDirectory = userSession?.conversationDirectory else { return }
        guard let kind = kind(of: sectionIndex) else { return }
        guard self.collapsed(at: sectionIndex) != collapsed else { return }
        guard let sectionNumber = sectionNumber(for: kind) else { return }

        if collapsed {
            state.collapsed.insert(kind.identifier)
        } else {
            state.collapsed.remove(kind.identifier)
        }

        var newValue = sections
        newValue[sectionNumber] = Section(
            kind: kind,
            conversationDirectory: conversationDirectory,
            collapsed: collapsed
        )

        if batchUpdate {
            let changeset = StagedChangeset(source: sections, target: newValue)

            delegate?.reload(using: changeset, interrupt: { _ in
                false
            }, setData: { data in
                if let data {
                    self.sections = data
                }
            })
        } else {
            sections = newValue
            delegate?.listViewModel(self, didUpdateSectionForReload: sectionIndex, animated: true)
        }
    }

    // MARK: Fileprivate

    fileprivate struct Section: DifferentiableSection {
        // MARK: Lifecycle

        init(source: ConversationListViewModel.Section, elements: some Collection<SectionItem>) {
            self.kind = source.kind
            self.collapsed = source.collapsed
            self.items = Array(elements)
        }

        init(
            kind: Kind,
            conversationDirectory: ConversationDirectoryType,
            collapsed: Bool
        ) {
            self.items = ConversationListViewModel.newList(for: kind, conversationDirectory: conversationDirectory)
            self.kind = kind
            self.collapsed = collapsed
        }

        // MARK: Internal

        enum Kind: Equatable, Hashable {
            /// for incoming requests
            case contactRequests

            /// for self pending requests / conversations
            case conversations

            /// one to one conversations
            case contacts

            /// group conversations
            case groups

            /// favorites
            case favorites

            /// conversations in folders
            case folder(label: LabelType)

            // MARK: Internal

            var identifier: SectionIdentifier {
                switch self {
                case let .folder(label: label):
                    label.remoteIdentifier?.transportString() ?? "folder"
                default:
                    canonicalName
                }
            }

            var obfuscatedName: String {
                switch self {
                case .folder:
                    "user-defined-folder"

                default:
                    canonicalName
                }
            }

            var canonicalName: String {
                switch self {
                case .contactRequests:
                    "contactRequests"
                case .conversations:
                    "conversations"
                case .contacts:
                    "contacts"
                case .groups:
                    "groups"
                case .favorites:
                    "favorites"
                case let .folder(label: label):
                    label.name ?? "folder"
                }
            }

            var localizedName: String? {
                switch self {
                case .conversations:
                    nil
                case .contactRequests:
                    L10n.Localizable.List.Section.requests
                case .contacts:
                    L10n.Localizable.List.Section.contacts
                case .groups:
                    L10n.Localizable.List.Section.groups
                case .favorites:
                    L10n.Localizable.List.Section.favorites
                case let .folder(label: label):
                    label.name
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
                case (.favorites, .favorites):
                    true
                case let (.folder(lhsLabel), .folder(rhsLabel)):
                    lhsLabel === rhsLabel
                default:
                    false
                }
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(identifier)
            }
        }

        var kind: Kind
        var items: [SectionItem]
        var collapsed: Bool

        var elements: [SectionItem] {
            collapsed ? [] : items
        }

        var differenceIdentifier: String {
            kind.identifier
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
    }

    // MARK: Private

    private typealias DiffKitSection = ArraySection<Int, SectionItem>

    // TODO: [WPB-6647]: Remove this, it's not needed anymore with the navigation overhaul epic. (folder support is removed)
    private struct State: Codable, Equatable {
        // MARK: Lifecycle

        init() {
            self.collapsed = []
            self.folderEnabled = false
        }

        // MARK: Internal

        var collapsed: Set<SectionIdentifier>
        var folderEnabled: Bool

        var jsonString: String? {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            guard let jsonData = try? encoder.encode(self) else {
                return nil
            }

            return String(decoding: jsonData, as: UTF8.self)
        }
    }

    private static var persistentDirectory: String? {
        guard let userID = ZMUser.selfUser()?.remoteIdentifier else { return nil }

        return "UI_state/\(userID)"
    }

    private static var persistentFilename: String {
        let className = String(describing: self)
        return "\(className).json"
    }

    // Local copies of the lists.
    private var sections: [Section] = []

    /// for folder enabled and collapse presistent
    private lazy var _state: State = {
        guard isFolderStatePersistenceEnabled else { return .init() }

        guard let persistentPath = ConversationListViewModel.persistentURL,
              let jsonData = try? Data(contentsOf: persistentPath) else { return State()
        }

        do {
            return try JSONDecoder().decode(ConversationListViewModel.State.self, from: jsonData)
        } catch {
            log.error("restore state error: \(error)")
            return State()
        }
    }()

    private var conversationDirectoryToken: Any?

    private let userSession: UserSession?

    private var state: State {
        get {
            _state
        }

        set {
            /// simulate willSet

            /// assign
            if newValue != _state {
                _state = newValue
            }

            /// simulate didSet
            saveState(state: _state)
        }
    }

    private static func newList(
        for kind: Section.Kind,
        conversationDirectory: ConversationDirectoryType
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
            conversationListType = .unarchived

        case .contacts:
            conversationListType = .contacts

        case .groups:
            conversationListType = .groups

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

    private func delegateFolderEnableState(newState: State) {
        delegate?.listViewModel(self, didChangeFolderEnabled: folderEnabled)
    }

    private func setupObservers() {
        conversationDirectoryToken = userSession?.conversationDirectory.addObserver(self)
    }

    private func kind(of sectionIndex: Int) -> Section.Kind? {
        guard sections.indices.contains(sectionIndex) else { return nil }

        return sections[sectionIndex].kind
    }

    private func updateAllSections() {
        sections = createSections()
    }

    /// Create the section structure
    private func createSections() -> [Section] {
        guard let conversationDirectory = userSession?.conversationDirectory else { return [] }

        var kinds: [Section.Kind]
        if folderEnabled {
            kinds = [
                .contactRequests,
                .favorites,
                .groups,
                .contacts,
            ]

            let folders: [Section.Kind] = conversationDirectory.allFolders.map { .folder(label: $0) }
            kinds.append(contentsOf: folders)
        } else {
            kinds = [
                .contactRequests,
                .conversations,
            ]
        }

        return kinds.map { Section(
            kind: $0,
            conversationDirectory: conversationDirectory,
            collapsed: state.collapsed.contains($0.identifier)
        ) }
    }

    private func sectionNumber(for kind: Section.Kind) -> Int? {
        for (index, section) in sections.enumerated() where section.kind == kind {
            return index
        }

        return nil
    }

    private func update(for kind: Section.Kind? = nil) {
        guard let conversationDirectory = userSession?.conversationDirectory else { return }

        var newValue: [Section]
        if let kind,
           let sectionNumber = sectionNumber(for: kind) {
            newValue = sections
            let newList = ConversationListViewModel.newList(for: kind, conversationDirectory: conversationDirectory)

            newValue[sectionNumber].items = newList

            // Refresh the section header(since it may be hidden if the sectio is empty) when a section becomes
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

        if let kind,
           let sectionNumber = sectionNumber(for: kind) {
            delegate?.listViewModel(self, didUpdateSection: sectionNumber)
        } else {
            for index in sections.indices {
                delegate?.listViewModel(self, didUpdateSection: index)
            }
        }
    }

    private func internalSelect(itemToSelect: ConversationListItem?) {
        selectedItem = itemToSelect

        if let itemToSelect {
            delegate?.listViewModel(self, didSelectItem: itemToSelect)
        }
    }

    private func collapsed(at sectionIndex: Int, state: State) -> Bool {
        guard let kind = kind(of: sectionIndex) else { return false }

        return state.collapsed.contains(kind.identifier)
    }

    private func saveState(state: State) {
        guard isFolderStatePersistenceEnabled,
              let jsonString = state.jsonString,
              let persistentDirectory = ConversationListViewModel.persistentDirectory,
              let directoryURL = URL.directoryURL(persistentDirectory) else { return }

        try! FileManager.default.createAndProtectDirectory(at: directoryURL)

        do {
            try jsonString.write(
                to: directoryURL.appendingPathComponent(ConversationListViewModel.persistentFilename),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            log.error("error writing ConversationListViewModel to \(directoryURL): \(error)")
        }
    }
}

// MARK: - ZMUserObserving

private let log = ZMSLog(tag: "ConversationListViewModel")

// MARK: ConversationDirectoryObserver

extension ConversationListViewModel: ConversationDirectoryObserver {
    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo) {
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
        case .favorites:
            .favorites
        case let .folder(label):
            .folder(label: label)
        case .archived:
            nil
        }
    }
}
