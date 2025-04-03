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
import WireAPI
import WireDataModel

struct VerifyUserUseCase {
    
    private let accountManager: AccountManager
    private let cookieStorage: any CookieStorageProtocol
    
    init(
        accountManager: AccountManager,
        cookieStorage: any CookieStorageProtocol
    ) {
        self.accountManager = accountManager
        self.cookieStorage = cookieStorage
    }
    
    func invoke(userID: UUID) async throws {
        guard accountManager.account(with: userID) != nil else {
            throw Failure.unknownUser
        }
        
        let cookies = try await cookieStorage.fetchCookies()
        var hasExpirationDate = false

        for cookie in cookies where cookie.name == Constants.cookieName {
            hasExpirationDate = cookie.expiresDate != nil
        }

        guard hasExpirationDate else {
            throw Failure.userUnauthenticated
        }
    }
    
    enum Constants {
        static let cookieName = "zuid"
    }
    
    enum Failure: Error {
        case unknownUser
        case userUnauthenticated
    }
    
}
