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
import Contacts

/// Wraps the system address book to return `ZMAddressBookContact` when iterating, filtering out those
/// without a valid email
protocol AddressBookAccessor {

    /// Number of contacts in the address book
    var numberOfContacts: UInt {get}

    /// Enumerates the contacts whitout performing any normalization or validation, invoking the block for each contact.
    /// If the block returns false, it will stop enumerating them.
    func enumerateRawContacts(block: @escaping (ContactRecord) -> (Bool))

    /// Returns contacts matching search query
    func rawContacts(matchingQuery: String) -> [ContactRecord]

    /// Gets a specific address book user by the local address book indentifier
    func contact(identifier: String) -> ContactRecord?
}

extension AddressBookAccessor {

    /// Enumerates the contacts, normalized and validated, invoking the block for each contact.
    /// Non valid contacts (no email) will be excluded from the enumeration.
    /// If the block returns false, it will stop enumerating them.
    func enumerateValidContacts(block: @escaping (ZMAddressBookContact) -> (Bool)) {
        self.enumerateRawContacts {
            guard let parsed = ZMAddressBookContact(contact: $0) else {
                return true
            }
            return block(parsed)
        }
    }

    /// Returns valid contacts matching the search query, with normalized email
    func contacts(matchingQuery: String) -> [ZMAddressBookContact] {
        return self.rawContacts(matchingQuery: matchingQuery)
            .compactMap { ZMAddressBookContact(contact: $0) }
    }

    /// Encodes an arbitraty part the address book asynchronously. Will invoke the completion handler when done.
    /// - parameter groupQueue: group queue to enter while executing, and where to invoke callback
    /// - parameter completion: closure invoked when the address book encoding ended. It will receive nil parameter
    ///     if there are no contacts to upload
    /// - parameter maxNumberOfContacts: do not include more than this number of contacts
    /// - parameter startingContactIndex: include contacts starting from this index in the address book
    func encodeWithCompletionHandler(_ groupQueue: ZMSGroupQueue,
                                     startingContactIndex: UInt,
                                     maxNumberOfContacts: UInt,
                                     completion: @escaping (EncodedAddressBookChunk?) -> Void
        ) {
        // here we are explicitly capturing self, this is executed on a queue that is
        // never blocked indefinitely as this is the only function using it
        groupQueue.dispatchGroup.async(on: addressBookProcessingQueue) {

            let range: Range<UInt> = startingContactIndex..<(startingContactIndex + maxNumberOfContacts)
            let cards = self.generateContactCards(range: range)

            guard cards.count > 0 || startingContactIndex > 0 else {
                // this should happen if I have zero contacts
                groupQueue.performGroupedBlock({
                    completion(nil)
                })
                return
            }

            let cardsRange = startingContactIndex..<(startingContactIndex + UInt(cards.count))
            let encodedAB = EncodedAddressBookChunk(numberOfTotalContacts: self.numberOfContacts,
                                                    otherContactsHashes: cards,
                                                    includedContacts: cardsRange)
            groupQueue.performGroupedBlock({
                completion(encodedAB)
            })
        }
    }

    /// Generate contact cards for the given range of contacts
    fileprivate func generateContactCards(range: Range<UInt>) -> [String: [String]] {
        var cards = [String: [String]]()

        self.contacts(range: range).enumerated().forEach { offset, contact in
            cards[contact.localIdentifier ?? "\(offset)"] = contact.emailAddresses.map { $0.base64EncodedSHADigest }
        }
        return cards
    }

    /// Returns contacts in a specific range
    func contacts(range: Range<UInt>) -> [ZMAddressBookContact] {
        var contacts = [ZMAddressBookContact]()

        let maxElements = Int(range.upperBound - range.lowerBound)
        contacts.reserveCapacity(maxElements)

        var skipped: UInt = 0
        self.enumerateValidContacts { contact -> (Bool) in
            if skipped < range.lowerBound {
                skipped += 1
                return true
            }
            contacts.append(contact)
            return contacts.count < maxElements
        }

        return contacts
    }

    /// Returns the first X raw contacts from the address book
    func firstRawContacts(number: Int) -> [ContactRecord] {
        var contacts = [ContactRecord]()
        contacts.reserveCapacity(number)
        var count = 0
        self.enumerateRawContacts { record in
            contacts.append(record)
            count += 1
            return count < number
        }
        return contacts
    }
}

// TODO: remove AddressBook framework support
/// Common base class between iOS 8 (AddressBook framework) and iOS 9+ (Contacts framework)
class AddressBook {

    typealias Normalizer = (String) -> (String?)
    typealias AccessCheck = () -> (Bool)

    /// Will return an instance of the address book accessor best suited for the
    /// current OS version. Will return `nil` if the user did not grant access to the AB
    static func factory() -> AddressBookAccessor? {
        guard self.accessGranted() else {
            return nil
        }

        return ContactAddressBook()
    }

    /// Uses the passed in closure, or the standard method if the closure is nil, to
    /// check if the AB access was granted. Returns whether it was granted.
    static func accessGranted(_ checkClosure: AccessCheck? = nil) -> Bool {
        if let closure = checkClosure {
            return closure()
        }
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
}

// MARK: - Encoded address book chunk
struct EncodedAddressBookChunk {

    /// Total number of contacts in the address book
    let numberOfTotalContacts: UInt

    /// Data to upload for contacts other that the self user
    /// maps from contact ID to hashes
    let otherContactsHashes: [String: [String]]

    /// Contacts included in this chunck, according to AB order
    let includedContacts: CountableRange<UInt>
}

// MARK: - Email validation

extension String {

    /// Returns a normalized email or nil
    var validatedEmail: String? {
        var email: Any? = self as Any?
        do {
            try ZMEmailAddressValidator.validateValue(&email)
            return email as? String
        } catch {
            return nil
        }
    }
}

// MARK: - Utilities

let addressBookContactsSearchLimit = 2000

extension String {

    /// Returns the base64 encoded string of the SHA hash of the string
    var base64EncodedSHADigest: String {
        Data(self.utf8).zmSHA256Digest().base64EncodedString(options: [])
    }
}

/// Private AB processing queue
let addressBookProcessingQueue = DispatchQueue(label: "Address book processing", attributes: [])

extension Sequence {

    /// Returns the elements of the sequence in the positions indicated by the range
    func elements(_ range: Range<UInt>) -> AnyIterator<Self.Iterator.Element> {

        var generator = self.makeIterator()
        var count: UInt = 0

        return AnyIterator {

            while count < range.lowerBound {
                if generator.next() != nil {
                    count += 1
                    continue
                } else {
                    return nil
                }
            }
            if count == range.upperBound {
                return nil
            }
            count += 1
            return generator.next()
        }
    }
}

// Generic contactto abstract actual address book framework details
protocol ContactRecord {

    var rawEmails: [String] { get }
    var firstName: String { get }
    var lastName: String { get }
    var middleName: String { get }
    var nickname: String { get }
    var organization: String { get }
    var localIdentifier: String { get }

}

extension ContactRecord {

    var displayName: String {
        return [self.firstName, self.middleName, self.lastName]
            .filter { $0 != "" }
            .joined(separator: " ")
    }
}

extension ZMAddressBookContact {

    convenience init?(contact: ContactRecord) {
        self.init()

        // names
        self.firstName = contact.firstName
        self.lastName = contact.lastName
        self.middleName = contact.middleName
        self.nickname = contact.nickname
        self.organization = contact.organization
        self.emailAddresses = contact.rawEmails.compactMap { $0.validatedEmail }
        self.localIdentifier = contact.localIdentifier

        // ignore contacts with no email
        guard self.emailAddresses.count > 0 else {
            return nil
        }
    }
}
