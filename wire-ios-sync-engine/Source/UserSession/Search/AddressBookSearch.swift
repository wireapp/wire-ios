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

import Contacts
import Foundation

// MARK: - AddressBookSearch

/// Search for contacts in the address book
class AddressBookSearch {
    // MARK: Lifecycle

    init(addressBook: AddressBookAccessor? = nil) {
        self.addressBook = addressBook ?? AddressBook.factory()
    }

    // MARK: Private

    /// Maximum number of contacts to consider when matching/searching,
    /// for performance reasons
    private let maximumSearchRange: UInt = 3000

    /// Address book
    private let addressBook: AddressBookAccessor?
}

// MARK: - Search contacts

extension AddressBookSearch {
    /// Returns address book contacts matching the query, excluding the one with the given identifier
    func contactsMatchingQuery(_ query: String, identifiersToExclude: [String]) -> [ZMAddressBookContact] {
        let excluded = Set(identifiersToExclude)
        let addressBookMatches = addressBook?.contacts(matchingQuery: query.lowercased()) ?? []

        return addressBookMatches.filter { contact in
            guard let identifier = contact.localIdentifier else {
                return true
            }
            return !excluded.contains(identifier)
        }
    }
}
