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

import Foundation
import Testing
import WireDataModel

@testable import WireDomain

@Suite(.serialized)
final class AccountManagerTests {

    let root: URL
    let url: URL

    init() {
        self.root = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        .first!
        .appendingPathComponent("AccountManagerTests")
        self.url = root.appendingPathComponent("Accounts")
    }

    deinit {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func makeSUT() throws -> AccountManager {
        try AccountManager(
            currentAppVersion: "1.0.0",
            directory: url,
            defaults: .temporary()
        )
    }

    @Test("When first initializing there are no accounts")
    func whenFirstInitializingThereAreNoAccounts() throws {
        // Given
        let sut = try makeSUT()

        // Then
        #expect(sut.selectedAccount == nil)
        #expect(sut.hasAccounts == false)
    }

    @Test("It can add and remove an account")
    func itCanAddAndRemoveAnAccount() throws {
        // Given
        let sut = try makeSUT()
        let account = Account(userName: "Alice", userIdentifier: UUID())

        // When
        sut.addOrUpdate(account)

        // Then
        #expect(sut.selectedAccount == nil)
        #expect(sut.accounts == [account])

        // When
        sut.remove(account)

        // Then
        #expect(sut.selectedAccount == nil)
        #expect(sut.accounts == [])
    }

    @Test("It can select an account")
    func itCanSelectAnAccount() throws {
        // Given
        let sut = try makeSUT()
        let account = Account(userName: "Alice", userIdentifier: UUID())

        // When
        sut.addOrUpdate(account)
        sut.select(account)

        // Then
        #expect(sut.selectedAccount == account)
        #expect(sut.accounts == [account])
    }

    @Test("It can add and select an account")
    func itCanAddAndSelectAnAccount() throws {
        // Given
        let sut = try makeSUT()
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())

        // When
        sut.addAndSelect(account1)

        // Then
        #expect(sut.selectedAccount == account1)
        #expect(sut.accounts == [account1])

        // When
        sut.addAndSelect(account2)

        // Then
        #expect(sut.selectedAccount == account2)
        #expect(sut.accounts == [account1, account2])
    }

    @Test("It can delete an account manager")
    func itCanDeleteAnAccountManager() throws {
        // Given
        do {
            let sut = try makeSUT()
            let account1 = Account(userName: "Alice", userIdentifier: UUID())
            let account2 = Account(userName: "Bob", userIdentifier: UUID(), teamName: "Wire")

            // When
            sut.addOrUpdate(account1)
            sut.addOrUpdate(account2)
            sut.select(account2)

            // Then
            #expect(sut.selectedAccount == account2)
            #expect(sut.accounts == [account1, account2])
        }

        // When
        AccountManager.delete(at: root)

        // Then
        do {
            let sut = try makeSUT()
            #expect(sut.selectedAccount == nil)
            #expect(sut.hasAccounts == false)
        }
    }

    @Test("It removes the selected account when it is removed")
    func itRemovesTheSelectedAccountWhenItIsRemoved() throws {
        // Given
        let sut = try makeSUT()
        let account = Account(userName: "Alice", userIdentifier: UUID())

        // When
        sut.addOrUpdate(account)
        sut.select(account)

        // Then
        #expect(sut.selectedAccount == account)
        #expect(sut.accounts == [account])

        // When
        sut.remove(account)

        // Then
        #expect(sut.selectedAccount == nil)
        #expect(sut.hasAccounts == false)
    }

    @Test("It updates exisiting account properties from store")
    func itUpdatesExisitingAccountPropertiesFromStore() throws {
        // Given
        let sut = try makeSUT()
        let accountID = UUID()
        sut.addAndSelect(Account(userName: "Alice", userIdentifier: accountID))
        let account = try #require(sut.selectedAccount)

        // When
        let updatedAccount = Account(userName: "Bob", userIdentifier: accountID, teamName: "Wire")
        sut.addAndSelect(updatedAccount)

        // Then
        #expect(sut.selectedAccount === account)
        #expect(account.userIdentifier == accountID)
        #expect(account.userName == "Bob")
        #expect(account.teamName == "Wire")
    }

    @Test("It sorts accounts without team before accounts with team")
    func testThatItSortsAccountsWithoutTeamBeforeAccountsWithTeam() throws {
        // Given
        let sut = try makeSUT()
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Alice", userIdentifier: UUID(), teamName: "Wire")

        // When
        sut.addOrUpdate(account2)
        sut.addOrUpdate(account1)

        // Then
        #expect(sut.sortedAccounts() == [account1, account2])
    }

    @Test("It sorts team accounts alphabetically")
    func itSortsTeamAccountsAlphabetically() throws {
        // Given
        let sut = try makeSUT()
        let account1 = Account(userName: "Alice", userIdentifier: UUID(), teamName: "Wire")
        let account2 = Account(userName: "Bob", userIdentifier: UUID(), teamName: "Wire")

        // When
        sut.addOrUpdate(account2)
        sut.addOrUpdate(account1)

        // Then
        #expect(sut.sortedAccounts() == [account1, account2])
    }

    @Test("It sorts accounts alphabetically")
    func itSortsAccountsAlphabetically() throws {
        // Given
        let sut = try makeSUT()
        let account1 = Account(userName: "Alice", userIdentifier: UUID())
        let account2 = Account(userName: "Bob", userIdentifier: UUID())
        let account3 = Account(userName: "Alice", userIdentifier: UUID(), teamName: "Wire")
        let account4 = Account(userName: "Bob", userIdentifier: UUID(), teamName: "Wire")

        // When
        sut.addOrUpdate(account4)
        sut.addOrUpdate(account2)

        // Then
        #expect(sut.sortedAccounts() == [account2, account4])

        // When
        sut.addOrUpdate(account3)

        // Then
        #expect(sut.sortedAccounts() == [account2, account3, account4])

        // When
        sut.addOrUpdate(account1)

        // Then
        #expect(sut.sortedAccounts() == [account1, account2, account3, account4])
    }

}
