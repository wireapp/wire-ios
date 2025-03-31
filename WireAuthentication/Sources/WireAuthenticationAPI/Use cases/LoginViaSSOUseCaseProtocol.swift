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

public protocol LoginViaSSOUseCaseProtocol: Sendable {

    func invoke(code: UUID?) async throws -> (userID: UUID, cookies: [HTTPCookie])

}

public enum LoginViaSSOUseCaseError: Error, Equatable {

    case noDefaultCodeAvailable
    case invalidCode
    case invalidURL
    case userCancelled
    case contextNotProvided
    case invalidContext
    case authenticationFailed(SAMLError)
    case invalidCallbackURL
    case callbackURLValidationFailed
    case missingCookies
    case unknown

}

public enum SAMLError: Error, Equatable {

    case serverErrorUnsupportedSAML
    case badSuccessRedirect
    case badFailureRedirect
    case badUsername
    case badUpstream
    case serverError
    case notFound
    case forbidden
    case noMatchingAuthReq
    case insufficientPermissions
    case unknown

}


public protocol LoginViaSSOUseCaseFactory {

    @MainActor
    func loginViaSSOUseCase(backendInfo: BackendInfo?) async throws -> any LoginViaSSOUseCaseProtocol

}
