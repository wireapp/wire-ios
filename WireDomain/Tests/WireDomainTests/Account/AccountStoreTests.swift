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
// swiftlint:disable line_length

import Foundation
import Testing
import WireDataModel
@testable import WireAPI

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
        let sut = try AccountStore(root: url)

        // Then
        #expect(sut.fetchAllAccounts().isEmpty)
    }

    @Test("It can store and retrieve accounts")
    func itCanStoreAndRetrieveAnAccount() throws {
        // Given
        let sut = try AccountStore(root: url)
        let account = Account(userName: "Alice", userIdentifier: UUID())

        // When
        #expect(sut.storeAccount(account) == true)

        // Then
        #expect(sut.fetchAllAccounts() == [account])
    }

    @Test("It can remove an account")
    func itCanRemoveAnAccount() throws {
        // Given
        let sut = try AccountStore(root: url)
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
            let sut = try AccountStore(root: url)
            let account = Account(userName: "Alice", userIdentifier: UUID())

            #expect(sut.storeAccount(account) == true)
            #expect(sut.fetchAllAccounts() == [account])
        }

        // When
        #expect(AccountStore.delete(at: url) == true)

        // Then
        do {
            let store = try AccountStore(root: url)
            #expect(store.fetchAllAccounts().isEmpty)
        }
    }

    @Test("It returns false when trying to delete a non existent account store")
    func itReturnsFalseWhenTryingToDeleteANonExistentAccountStore() throws {
        // Then
        #expect(AccountStore.delete(at: url) == false)
    }

    @Test("It can store multiple accounts")
    func itCanStoreMultipleAccounts() throws {
        // Given
        let sut = try AccountStore(root: url)
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
        let sut = try AccountStore(root: url)
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
        let sut = try AccountStore(root: url)
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
        let sut = try AccountStore(root: url)
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
        let sut = try AccountStore(root: url)
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
        let sut = try AccountStore(root: url)
        let uuid = UUID()

        // When
        let account = Account(userName: "Alice", userIdentifier: uuid)
        #expect(sut.storeAccount(account) == true)
        #expect(sut.fetchAccount(with: uuid) == account)
    }

    @Test("It does not return an account for a UUID if there is none")
    func itDoesNotReturnAnAccountForAUUIDIfThereIsNone() throws {
        // Given
        let sut = try AccountStore(root: url)
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
            let sut = try AccountStore(root: url)
            #expect(sut.storeAccount(account1) == true)
            #expect(sut.storeAccount(account2) == true)
        }

        // Then
        do {
            let sut = try AccountStore(root: url)
            #expect(sut.fetchAllAccounts() == [account1, account2])
        }
    }

    @Test("It only reads files named by UUIDs")
    func itOnlyReadsFilesNamedByUUIDs() throws {
        // Given
        let sut = try AccountStore(root: url)
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
        try accountJSON.write(to: url.appendingPathComponent("Accounts/invalid_account"))

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
        let sut = try AccountStore(root: url)
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

        try accountJSON.write(to: url.appendingPathComponent("Accounts/" + accountID.uuidString))

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
        let sut = try AccountStore(root: url)
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

        try accountJSON.write(to: url.appendingPathComponent("Accounts/" + accountID.uuidString))

        // When
        let account = sut.fetchAccount(with: accountID)

        // Then
        let expectedCredentials = LoginCredentials(
            emailAddress: "alice@example.com",
            hasPassword: true,
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

    @Test("Store and fetch Backend environment")
    func storeAndFetchBackendEnvironment() throws {
        let sut = try AccountStore(root: url)
        let accountId = UUID()
        let environment = makeBackendEnvironment()

        sut.storeBackendEnvironment(environment, for: accountId)
        let fetched = try sut.fetchBackendEnvironment(accountId: accountId)

        #expect(fetched == environment)
        #expect(fetched?.pinnedKeys.count == 1)
        #expect(fetched?.proxySettings != nil)
    }

    @Test
    func storeAndFetchBackendEnvironment_noPinnedKey() throws {
        let sut = try AccountStore(root: url)
        let accountId = UUID()
        let environment = makeBackendEnvironment(withPinnedKey: false)

        sut.storeBackendEnvironment(environment, for: accountId)
        let fetched = try sut.fetchBackendEnvironment(accountId: accountId)

        #expect(fetched == environment)
        #expect(fetched?.pinnedKeys.isEmpty == true)
        #expect(fetched?.proxySettings != nil)
    }

    @Test
    func storeAndFetchBackendEnvironment_noPinnedKey_noProxySettings() throws {
        let sut = try AccountStore(root: url)
        let accountId = UUID()
        let environment = makeBackendEnvironment(
            proxyIncluded: false, withPinnedKey: false
        )

        sut.storeBackendEnvironment(environment, for: accountId)
        let fetched = try sut.fetchBackendEnvironment(accountId: accountId)

        #expect(fetched == environment)
        #expect(fetched?.pinnedKeys.isEmpty == true)
        #expect(fetched?.proxySettings == nil)
    }

    @Test
    func storeAndFetchBackendEnvironment_unauthenticatedProxySettings() throws {
        let sut = try AccountStore(root: url)
        let accountId = UUID()
        let environment = makeBackendEnvironment(proxyAuthenticated: false)

        sut.storeBackendEnvironment(environment, for: accountId)
        let fetched = try sut.fetchBackendEnvironment(accountId: accountId)

        #expect(fetched == environment)
        #expect(fetched?.pinnedKeys.count == 1)
        #expect(fetched?.proxySettings == .unauthenticated(host: "Host.com", port: 9999))
    }

    @Test
    func fetchMissingBackendEnvironmentReturnsNil() throws {
        let sut = try AccountStore(root: url)
        let accountId = UUID()

        let fetched = try sut.fetchBackendEnvironment(accountId: accountId)

        #expect(fetched == nil)
    }

    @Test
    func deleteBackendEnvironment() throws {
        let sut = try AccountStore(root: url)
        let environment = makeBackendEnvironment()
        let validAccount = Account(userName: "Alice", userIdentifier: UUID())

        sut.storeBackendEnvironment(environment, for: validAccount.userIdentifier)
        sut.deleteBackendEnvironment(account: validAccount)

        let fetched = try sut.fetchBackendEnvironment(accountId: validAccount.userIdentifier)

        #expect(fetched == nil)

    }

    private func makeBackendEnvironment(
        proxyIncluded: Bool = true,
        proxyAuthenticated: Bool = true,
        withPinnedKey: Bool = true
    ) -> BackendEnvironment2 {
        let key =
            """
            MIIE/jCCA+agAwIBAgIQBmeNK7xaqmvwoGsKbGiEuzANBgkqhkiG9w0BAQsFADBNMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5EaWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTcxMjEyMDAwMDAwWhcNMTkwMjAxMTIwMDAwWjBKMQswCQYDVQQGEwJDSDEMMAoGA1UEBxMDWnVnMRgwFgYDVQQKEw9XaXJlIFN3aXNzIEdtYkgxEzARBgNVBAMMCioud2lyZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCt5jMFa6+dUph+A01fd1WNSeohW2XhepCcJxjqb+xYzXlNMrRuj0UqczE0A+0PMHpWJG+lmwoR59fymLXklyzi5mK5nzUhJXVurG2myMnnpiN6Z730NxrlyTfmlOFi4rqNny8bqkmJj2ZFj2cZp2J3ipYvu7AB6gifHaY4zsd6kIKHY05d34SNDiwGx+Bv6RatxVCYHO8sc9QOjKSb+b4G8vZ4nWeM82Iz8ah5duYhbVYzeJ+5xgmgP2D5Xk18d8A2tW7bDhhwsNp3QLzk1vxTWyAU2SuA6rOF3/XEeiTW47KOh4tMgcdiSvK9sESZ2Xq/5/YnUQzT4WP2+x4jZNitAgMBAAGjggHbMIIB1zAfBgNVHSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQU/0iA8JzB4tDtwNB/3NyYfCtfTZwwHwYDVR0RBBgwFoIKKi53aXJlLmNvbYIId2lyZS5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBrBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc3NjYS1zaGEyLWc2LmNybDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NzY2Etc2hhMi1nNi5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBAgIwfAYIKwYBBQUHAQEEcDBuMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wRgYIKwYBBQUHMAKGOmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJTZWN1cmVTZXJ2ZXJDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAc6v6cf/EQmmeGU2nC87F6QgEIAIL3svgabImao3f01QFVxC0XX2Cf9+wofijspqq5Uj80nb04o5HNnZWX1agJmqp8jTYH2hw4+uiwFCld0QEptHMrCwEAyyouf0/cl2dfRv2V8m29W6Qb4+7pc1rEbFLl3fywmjgzpGkr1+cKE7pwkpgKqhulKkE4CDXant0Slj7cvDisSPy/kInJ5uHI29Z/SBCpACyHah6lkdIQyTo4uem1XH6i5UP9sTvCAZl0acHcPsvcJ50LeJvJC7sPNXr60xZYLIK5LIVrSSRhxtOB1WPMbzIQc5bF2LcSjXJNvXA5+RCO79om91mlheqPQ==
            """

        guard let keyData = Data(base64Encoded: key),
              let pinnedKey = try? PinnedKey(key: keyData, hosts: [
                  .endsWith("prod-nginz-https.wire.com"),
                  .equals("clientblacklist.wire.com")
              ])
        else {
            fatalError()
        }

        var proxy: WireAPI.ProxySettings? = nil
        if proxyIncluded {
            proxy = proxyAuthenticated ? .authenticated(
                host: "Host.com",
                port: 9999,
                username: "username",
                password: "pass"
            ) :
                .unauthenticated(host: "Host.com", port: 9999)
        }

        return BackendEnvironment2(
            title: "Staging",
            endpoints: BackendEnvironment2
                .Endpoints(
                    restAPIURL: URL(string: "example.com")!,
                    websocketURL: URL(string: "example.com")!,
                    blacklistURL: URL(string: "example.com")!,
                    teamsURL: URL(string: "example.com")!,
                    accountsURL: URL(string: "example.com")!,
                    websiteURL: URL(string: "example.com")!,
                    countlyURL: URL(string: "example.com")!
                ),
            pinnedKeys: withPinnedKey ? [pinnedKey] : [],
            proxySettings: proxy,
            metadata: BackendEnvironment2
                .ResolvedBackendMetadata(
                    apiVersion: .v8,
                    domain: "example.com",
                    isFederationEnabled: false
                )
        )
    }
}

// swiftlint:enable line_length
