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

import AddressBook
import Foundation
@testable import WireSyncEngine

// MARK: - AddressBookTests

final class AddressBookTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        addressBook = MockAddressBook()
        super.setUp()
    }

    override func tearDown() {
        addressBook = nil
        super.tearDown()
    }

    // MARK: Fileprivate

    fileprivate var addressBook: MockAddressBook!
}

// MARK: - Access to AB

extension AddressBookTests {
    func testThatItReturnsAllContactsWhenTheyHaveValidEmailAndPhoneNumbers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com", "janet@example.com"],
                phoneNumbers: ["+15550100"]
            ),
            MockAddressBookContact(
                firstName: "สยาม",
                emailAddresses: ["siam@example.com"],
                phoneNumbers: ["+15550101", "+15550102"]
            ),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 2)
        for i in 0 ..< addressBook.contacts.count {
            XCTAssertEqual(contacts[i].emailAddresses, addressBook.contacts[i].rawEmails)
            XCTAssertEqual(contacts[i].phoneNumbers, addressBook.contacts[i].rawPhoneNumbers)
        }
    }

    func testThatItReturnsAllContactsWhenTheyHaveValidEmailOrPhoneNumbers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: ["olaf@example.com"], phoneNumbers: []),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550101"]),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 2)
        for i in 0 ..< addressBook.contacts.count {
            XCTAssertEqual(contacts[i].emailAddresses, addressBook.contacts[i].rawEmails)
            XCTAssertEqual(contacts[i].phoneNumbers, addressBook.contacts[i].rawPhoneNumbers)
        }
    }

    func testThatItFilterlContactsThatHaveNoEmailNorPhone() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550100"]
            ),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: []),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].emailAddresses, addressBook.contacts[0].rawEmails)
    }
}

// MARK: - Validation/normalization

extension AddressBookTests {
    func testThatItFilterlContactsThatHaveAnInvalidPhoneAndNoEmail() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: [], phoneNumbers: ["aabbccdd"]),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 0)
    }

    func testThatIgnoresInvalidPhones() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["janet@example.com"],
                phoneNumbers: ["aabbccdd"]
            ),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].emailAddresses, addressBook.contacts[0].rawEmails)
        XCTAssertEqual(contacts[0].phoneNumbers, [])
    }

    func testThatItFilterlContactsThatHaveNoPhoneAndInvalidEmail() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: ["janet"], phoneNumbers: []),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 0)
    }

    func testThatIgnoresInvalidEmails() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: ["janet"], phoneNumbers: ["+15550103"]),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].emailAddresses, [])
        XCTAssertEqual(contacts[0].phoneNumbers, addressBook.contacts[0].rawPhoneNumbers)
    }

    func testThatItNormalizesPhoneNumbers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: [], phoneNumbers: ["+1 (555) 0103"]),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].phoneNumbers, ["+15550103"])
    }

    func testThatItNormalizesEmails() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["Olaf Karlsson <janet+1@example.com>"],
                phoneNumbers: []
            ),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].emailAddresses, ["janet+1@example.com"])
    }

    func testThatItDoesNotIgnoresPhonesWithPlusZero() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(firstName: "Olaf", emailAddresses: [], phoneNumbers: ["+012345678"]),
        ]

        // when
        let contacts = Array(addressBook.contacts(range: 0 ..< 100))

        // then
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts[0].phoneNumbers, ["+012345678"])
    }
}

// MARK: - Encoding

extension AddressBookTests {
    func testThatItEncodesUsers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
            MockAddressBookContact(firstName: "Hadiya", emailAddresses: [], phoneNumbers: ["+15550102"]),
        ]
        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook
            .encodeWithCompletionHandler(queue, startingContactIndex: 0, maxNumberOfContacts: 100) { chunk in

                // then
                if let chunk {
                    XCTAssertEqual(chunk.numberOfTotalContacts, 3)
                    XCTAssertEqual(chunk.includedContacts, UInt(0) ..< UInt(3))
                    let expected = [
                        self.addressBook.contacts[0].localIdentifier: [
                            "BSdmiT9F5EtQrsfcGm+VC7Ofb0ZRREtCGCFw4TCimqk=",
                            "f9KRVqKI/n1886fb6FnP4oIORkG5S2HO0BoCYOxLFaA=",
                        ],
                        self.addressBook.contacts[1].localIdentifier: ["YCzX+75BaI4tkCJLysNi2y8f8uK6dIfYWFyc4ibLbQA="],
                        self.addressBook.contacts[2].localIdentifier: ["iJXG3rJ3vc8rrh7EgHzbWPZsWOHFJ7mYv/MD6DlY154="],
                    ]
                    checkEqual(lhs: chunk.otherContactsHashes, rhs: expected)
                } else {
                    XCTFail()
                }
                expectation.fulfill()
            }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItCallsCompletionHandlerWithNilIfNoContacts() {
        // given
        addressBook.contacts = []
        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook
            .encodeWithCompletionHandler(queue, startingContactIndex: 0, maxNumberOfContacts: 100) { chunk in

                // then
                XCTAssertNil(chunk)
                expectation.fulfill()
            }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItEncodesOnlyAMaximumNumberOfUsers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
            MockAddressBookContact(firstName: "Hadiya", emailAddresses: [], phoneNumbers: ["+15550102"]),
        ]
        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook.encodeWithCompletionHandler(queue, startingContactIndex: 0, maxNumberOfContacts: 2) { chunk in

            // then
            if let chunk {
                XCTAssertEqual(chunk.numberOfTotalContacts, 3)
                XCTAssertEqual(chunk.includedContacts, UInt(0) ..< UInt(2))
                let expected = [
                    self.addressBook.contacts[0].localIdentifier: [
                        "BSdmiT9F5EtQrsfcGm+VC7Ofb0ZRREtCGCFw4TCimqk=",
                        "f9KRVqKI/n1886fb6FnP4oIORkG5S2HO0BoCYOxLFaA=",
                    ],
                    self.addressBook.contacts[1].localIdentifier: ["YCzX+75BaI4tkCJLysNi2y8f8uK6dIfYWFyc4ibLbQA="],
                ]
                checkEqual(lhs: chunk.otherContactsHashes, rhs: expected)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItEncodesOnlyTheRequestedUsers() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
            MockAddressBookContact(firstName: "Hadiya", emailAddresses: [], phoneNumbers: ["+15550102"]),
            MockAddressBookContact(firstName: " أميرة", emailAddresses: ["a@example.com"], phoneNumbers: []),
        ]

        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook.encodeWithCompletionHandler(queue, startingContactIndex: 1, maxNumberOfContacts: 2) { chunk in

            // then
            if let chunk {
                XCTAssertEqual(chunk.numberOfTotalContacts, 4)
                XCTAssertEqual(chunk.includedContacts, UInt(1) ..< UInt(3))
                let expected = [
                    self.addressBook.contacts[1].localIdentifier: ["YCzX+75BaI4tkCJLysNi2y8f8uK6dIfYWFyc4ibLbQA="],
                    self.addressBook.contacts[2].localIdentifier: ["iJXG3rJ3vc8rrh7EgHzbWPZsWOHFJ7mYv/MD6DlY154="],
                ]
                checkEqual(lhs: chunk.otherContactsHashes, rhs: expected)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItEncodesAsManyContactsAsItCanIfAskedToEncodeTooMany() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: " أميرة", emailAddresses: ["a@example.com"], phoneNumbers: []),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
            MockAddressBookContact(firstName: "Hadiya", emailAddresses: [], phoneNumbers: ["+15550102"]),
        ]

        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook.encodeWithCompletionHandler(queue, startingContactIndex: 2, maxNumberOfContacts: 20) { chunk in

            // then
            if let chunk {
                XCTAssertEqual(chunk.numberOfTotalContacts, 4)
                XCTAssertEqual(chunk.includedContacts, UInt(2) ..< UInt(4))
                let expected = [
                    self.addressBook.contacts[2].localIdentifier: ["YCzX+75BaI4tkCJLysNi2y8f8uK6dIfYWFyc4ibLbQA="],
                    self.addressBook.contacts[3].localIdentifier: ["iJXG3rJ3vc8rrh7EgHzbWPZsWOHFJ7mYv/MD6DlY154="],
                ]
                checkEqual(lhs: chunk.otherContactsHashes, rhs: expected)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItEncodesNoContactIfAskedToEncodePastTheLastContact() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: " أميرة", emailAddresses: ["a@example.com"], phoneNumbers: []),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
        ]

        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation = expectation(description: "Callback invoked")

        // when
        addressBook
            .encodeWithCompletionHandler(queue, startingContactIndex: 20, maxNumberOfContacts: 20) { chunk in

                // then
                if let chunk {
                    XCTAssertEqual(chunk.numberOfTotalContacts, 3)
                    XCTAssertEqual(chunk.includedContacts, UInt(20) ..< UInt(20))
                    XCTAssertEqual(chunk.otherContactsHashes.count, 0)
                } else {
                    XCTFail()
                }
                expectation.fulfill()
            }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }

    func testThatItEncodesTheSameAddressBookInTheSameWay() {
        // given
        addressBook.contacts = [
            MockAddressBookContact(
                firstName: "Olaf",
                emailAddresses: ["olaf@example.com"],
                phoneNumbers: ["+15550101"]
            ),
            MockAddressBookContact(firstName: "สยาม", emailAddresses: [], phoneNumbers: ["+15550100"]),
            MockAddressBookContact(firstName: "Hadiya", emailAddresses: [], phoneNumbers: ["+15550102"]),
        ]
        let queue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        queue.createDispatchGroups()
        let expectation1 = expectation(description: "Callback invoked once")

        var chunk1: [String: [String]]?
        var chunk2: [String: [String]]?

        // when
        addressBook
            .encodeWithCompletionHandler(queue, startingContactIndex: 0, maxNumberOfContacts: 100) { chunk in

                chunk1 = chunk?.otherContactsHashes
                expectation1.fulfill()
            }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }

        let expectation2 = expectation(description: "Callback invoked twice")
        addressBook
            .encodeWithCompletionHandler(queue, startingContactIndex: 0, maxNumberOfContacts: 100) { chunk in

                chunk2 = chunk?.otherContactsHashes
                expectation2.fulfill()
            }

        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }

        // then
        checkEqual(lhs: chunk1, rhs: chunk2)
    }
}

// MARK: - Helpers

private func checkEqual(
    lhs: [String: [String]]?,
    rhs: [String: [String]]?,
    line: UInt = #line,
    file: StaticString = #file
) {
    guard let lhs, let rhs else {
        XCTFail("Value is nil", file: file, line: line)
        return
    }

    let keys1 = Set(lhs.keys)
    let keys2 = Set(rhs.keys)
    guard keys1 == keys2 else {
        XCTAssertEqual(keys1, keys2, file: file, line: line)
        return
    }

    for key in keys1 {
        let array1 = lhs[key]!
        let array2 = rhs[key]!
        zip(array1, array2).forEach { XCTAssertEqual($0.0, $0.1, file: file, line: line) }
    }
}
