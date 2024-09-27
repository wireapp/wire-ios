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

import Foundation
import WireDataModel
import WireSyncEngine

// MARK: - ContactsDataSourceDelegate

protocol ContactsDataSourceDelegate: AnyObject {
    func dataSource(_ dataSource: ContactsDataSource, cellFor user: UserType, at indexPath: IndexPath)
        -> UITableViewCell
    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType])
}

// MARK: - ContactsDataSource

final class ContactsDataSource: NSObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        self.searchDirectory = ZMUserSession.shared().map(SearchDirectory.init)
        performSearch()
    }

    deinit {
        searchDirectory?.tearDown()
    }

    // MARK: Internal

    static let MinimumNumberOfContactsToDisplaySections: UInt = 15

    weak var delegate: ContactsDataSourceDelegate?

    private(set) var searchDirectory: SearchDirectory?

    // MARK: - Getters / Setters

    var ungroupedSearchResults = [UserType]() {
        didSet {
            recalculateSections()
        }
    }

    var searchQuery = "" {
        didSet {
            performSearch()
        }
    }

    var shouldShowSectionIndex: Bool {
        ungroupedSearchResults.count >= type(of: self).MinimumNumberOfContactsToDisplaySections
    }

    func user(at indexPath: IndexPath) -> UserType {
        section(at: indexPath.section)[indexPath.row]
    }

    // MARK: Private

    private var sections = [[UserType]]()

    private var collation: UILocalizedIndexedCollation { .current() }

    // MARK: - Methods

    private func performSearch() {
        guard let searchDirectory else {
            return
        }

        let request = SearchRequest(query: searchQuery, searchOptions: [.contacts, .addressBook])
        let task = searchDirectory.perform(request)

        task.addResultHandler { [weak self] searchResult, _ in
            guard let self else {
                return
            }
            ungroupedSearchResults = searchResult.addressBook
            delegate?.dataSource(self, didReceiveSearchResult: searchResult.addressBook)
        }

        task.start()
    }

    private func section(at index: Int) -> [UserType] {
        sections[index]
    }

    private func recalculateSections() {
        let nameSelector = #selector(getter: UserType.name)

        guard shouldShowSectionIndex else {
            let sortedResults = collation.sortedArray(
                from: ungroupedSearchResults,
                collationStringSelector: nameSelector
            )
            sections = [sortedResults] as? [[UserType]] ?? []
            return
        }

        let numberOfSections = collation.sectionTitles.count
        let emptySections = Array(repeating: [UserType](), count: numberOfSections)

        let unsortedSections = ungroupedSearchResults.reduce(into: emptySections) { sections, user in
            let index = collation.section(for: user, collationStringSelector: nameSelector)
            sections[index].append(user)
        }

        let sortedSections = unsortedSections.map {
            collation.sortedArray(from: $0, collationStringSelector: nameSelector)
        }

        sections = sortedSections as? [[UserType]] ?? []
    }
}

// MARK: UITableViewDataSource

extension ContactsDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.section(at: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        delegate?.dataSource(self, cellFor: user(at: indexPath), at: indexPath) ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard shouldShowSectionIndex, !self.section(at: section).isEmpty else {
            return nil
        }
        return collation.sectionTitles[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        collation.sectionIndexTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        collation.section(forSectionIndexTitle: index)
    }
}

// MARK: UITableViewDelegate

extension ContactsDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
