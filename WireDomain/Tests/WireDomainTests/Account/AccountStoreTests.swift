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

import Foundation
import Testing
import WireDataModel
@testable import WireNetwork

@testable import WireDomain

@Suite(.serialized)
final class AccountStoreTests {

    let url: URL

    init() {
        self.url = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        .first!
        .appendingPathComponent("AccountStoreTests")
    }

    deinit {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test("It creates an empty store")
    func itCreatesAnEmptyStore() throws {
        // Given
        let sut = try AccountStore(directory: url)

        // Then
        #expect(sut.fetchAllAccounts().isEmpty)
    }

    @Test("It can store and retrieve accounts")
    func itCanStoreAndRetrieveAnAccount() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let account = Account(userName: "Alice", userIdentifier: UUID())

        // When
        #expect(sut.storeAccount(account) == true)

        // Then
        #expect(sut.fetchAllAccounts() == [account])
    }

    @Test("It can remove an account")
    func itCanRemoveAnAccount() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let account = Account(userName: "Alice", userIdentifier: UUID())

        #expect(sut.storeAccount(account) == true)
        #expect(sut.fetchAllAccounts() == [account])

        // When
        #expect(sut.deleteAccount(account) == true)

        // Then
        #expect(sut.fetchAllAccounts().isEmpty)
    }

    @Test("It can delete an account store")
    func itCanDeleteAnAccountStore() throws {
        // Given
        do {
            let sut = try AccountStore(directory: url)
            let account = Account(userName: "Alice", userIdentifier: UUID())

            #expect(sut.storeAccount(account) == true)
            #expect(sut.fetchAllAccounts() == [account])
        }

        // When
        #expect(AccountStore.delete(directory: url) == true)

        // Then
        do {
            let store = try AccountStore(directory: url)
            #expect(store.fetchAllAccounts().isEmpty)
        }
    }

    @Test("It returns false when trying to delete a non existent account store")
    func itReturnsFalseWhenTryingToDeleteANonExistentAccountStore() throws {
        // Then
        #expect(AccountStore.delete(directory: url) == false)
    }

    @Test("It can store multiple accounts")
    func itCanStoreMultipleAccounts() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())

        // When
        #expect(sut.storeAccount(account1) == true)
        #expect(sut.storeAccount(account2) == true)

        // Then
        #expect(sut.fetchAllAccounts() == [account1, account2])
    }

    @Test("It only removes specified accounts")
    func itOnlyRemovesSpecifiedAccounts() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())

        #expect(sut.storeAccount(account1) == true)
        #expect(sut.storeAccount(account2) == true)

        let stored = sut.fetchAllAccounts()
        #expect(stored == [account1, account2])

        // When
        #expect(sut.deleteAccount(account2) == true)

        // Then
        #expect(sut.fetchAllAccounts() == [account1])

        // When
        #expect(sut.deleteAccount(account1) == true)

        // Then
        #expect(sut.fetchAllAccounts().isEmpty)
    }

    @Test("It returns false if the account to be removed is not contained in the store")
    func itReturnsFalseIfTheAccountToBeRemovedIsNotContainedInTheStore() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())

        // When
        #expect(sut.storeAccount(account1) == true)
        #expect(sut.fetchAllAccounts() == [account1])

        // Then
        #expect(sut.deleteAccount(account2) == false)
    }

    @Test("It updates an existing account")
    func itUpdatesAnExistingAccount() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let uuid = UUID()

        do {
            let account = Account(userName: "Alice", userIdentifier: uuid)
            #expect(sut.storeAccount(account) == true)
            #expect(sut.fetchAllAccounts() == [account])
        }

        // When
        let name = "Bob"
        let team = "Wire"

        do {
            let account = Account(userName: name, userIdentifier: uuid, teamName: team)
            #expect(sut.storeAccount(account) == true)
        }

        // Then
        let account = try #require(sut.fetchAccount(with: uuid))
        #expect(account.userName == name)
        #expect(account.teamName == team)
        #expect(account.imageData == nil)
        #expect(account.teamImageData == nil)
    }

    @Test("It updates an existing account with images")
    func itUpdatesAnExistingAccountWithImages() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let uuid = UUID()

        do {
            let account = Account(userName: "Alice", userIdentifier: uuid)
            #expect(sut.storeAccount(account) == true)
            #expect(sut.fetchAllAccounts() == [account])
        }

        // When
        let name = "Bob"
        let team = "Wire"
        let image = Data.random(byteCount: 8)

        do {
            let account = Account(
                userName: name,
                userIdentifier: uuid,
                teamName: team,
                imageData: image,
                teamImageData: image
            )
            #expect(sut.storeAccount(account) == true)
        }

        // Then
        let account = try #require(sut.fetchAccount(with: uuid))
        #expect(account.userName == name)
        #expect(account.teamName == team)
        #expect(account.imageData == image)
        #expect(account.teamImageData == image)
    }

    @Test("It can load an account by UUID")
    func itCanLoadAnAccountByUUID() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let uuid = UUID()

        // When
        let account = Account(userName: "Alice", userIdentifier: uuid)
        #expect(sut.storeAccount(account) == true)
        #expect(sut.fetchAccount(with: uuid) == account)
    }

    @Test("It does not return an account for a UUID if there is none")
    func itDoesNotReturnAnAccountForAUUIDIfThereIsNone() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let uuid = UUID()

        // When
        let account = Account(userName: "Alice", userIdentifier: uuid)
        #expect(sut.storeAccount(account) == true)
        #expect(sut.fetchAccount(with: UUID()) == nil)
    }

    @Test("A second store at the same location shows the same accounts")
    func aSecondAccountAtTheSameLocationShowsTheSameAccounts() throws {
        // Given
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())

        // When
        do {
            let sut = try AccountStore(directory: url)
            #expect(sut.storeAccount(account1) == true)
            #expect(sut.storeAccount(account2) == true)
        }

        // Then
        do {
            let sut = try AccountStore(directory: url)
            #expect(sut.fetchAllAccounts() == [account1, account2])
        }
    }

    @Test("It only reads files named by UUIDs")
    func itOnlyReadsFilesNamedByUUIDs() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let validAccount = Account(userName: "Alice", userIdentifier: UUID())

        let accountJSON = Data("""
        {
            "name": "Bob",
            "identifier": "\(UUID())",
            "team": "Wire",
            "image": "",
            "unreadConversationCount": 1
        }
        """.utf8)
        try accountJSON.write(to: url.appendingPathComponent("invalid_account"))

        // Then
        #expect(sut.fetchAllAccounts().isEmpty)

        // When
        sut.storeAccount(validAccount)

        // Then
        #expect(sut.fetchAllAccounts() == [validAccount])
    }

    @Test("It decodes account on disk without login credentials")
    func itDecodesAccountOnDiskWithoutLoginCredentials() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let accountID = UUID(uuidString: "012B6D4F-590B-4355-AC8A-8A531F9F30EE")!

        let accountJSON = Data("""
        {
            "name": "Alice",
            "identifier": "\(accountID)",
            "team": "Wire",
            "image": "",
            "unreadConversationCount": 1
        }
        """.utf8)

        try accountJSON.write(to: url.appendingPathComponent(accountID.uuidString))

        // When
        let account = sut.fetchAccount(with: accountID)

        // Then
        let expectedAccount = Account(
            userName: "Alice",
            userIdentifier: accountID,
            teamName: "Wire",
            imageData: Data(),
            teamImageData: nil,
            unreadConversationCount: 1,
            loginCredentials: nil
        )
        #expect(account == expectedAccount)
    }

    @Test("It decodes account on disk with login credentials")
    func itDecodesAccountOnDiskWithLoginCredentials() throws {
        // Given
        let sut = try AccountStore(directory: url)
        let accountID = UUID(uuidString: "012B6D4F-590B-4355-AC8A-8A531F9F30EE")!

        let accountJSON = Data("""
        {
            "name": "Alice",
            "identifier": "\(accountID)",
            "team": "Wire",
            "image": "",
            "unreadConversationCount": 0,
            "loginCredentials": {
                "emailAddress": "alice@example.com",
                "hasPassword": true,
                "usesCompanyLogin": false
            }
        }
        """.utf8)

        try accountJSON.write(to: url.appendingPathComponent(accountID.uuidString))

        // When
        let account = sut.fetchAccount(with: accountID)

        // Then
        let expectedCredentials = LoginCredentials(
            emailAddress: "alice@example.com",
            usesCompanyLogin: false
        )
        let expectedAccount = Account(
            userName: "Alice",
            userIdentifier: accountID,
            teamName: "Wire",
            imageData: Data(),
            teamImageData: nil,
            unreadConversationCount: 0,
            loginCredentials: expectedCredentials
        )
        #expect(account == expectedAccount)
    }

}
