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

// sourcery: AutoMockable
protocol AuthenticationServiceProtocol {
    func authenticated() async throws -> AuthenticatedSessionProtocol
}

struct AuthenticationService: AuthenticationServiceProtocol {
    private let cookieStorageProvider: CookieStorageProvider
    private let authenticatedSessionProvider: AuthenticatedSessionProvider

    private enum Constants {
        static let cookieName = "zuid"
    }

    enum Failure: Error {
        case unauthenticated
    }

    init(
        cookieStorageProvider: CookieStorageProvider,
        authenticatedSessionProvider: AuthenticatedSessionProvider
    ) {
        self.cookieStorageProvider = cookieStorageProvider
        self.authenticatedSessionProvider = authenticatedSessionProvider
    }

    /// Checks whether user is authenticated.
    /// - returns: An`AuthenticatedSession` when user is authenticated.
    func authenticated() async throws -> AuthenticatedSessionProtocol {
        let cookieStorage = cookieStorageProvider.cookieStorage
        let cookies = try await cookieStorage.fetchCookies()
        var hasExpirationDate = false

        for cookie in cookies where cookie.name == Constants.cookieName {
            hasExpirationDate = cookie.expiresDate != nil
        }

        let isAuthenticated = hasExpirationDate

        guard isAuthenticated else {
            throw Failure.unauthenticated
        }

        return authenticatedSessionProvider.authenticatedSession
    }

}
