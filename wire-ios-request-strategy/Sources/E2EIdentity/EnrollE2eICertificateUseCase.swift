//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol EnrollE2eICertificateUseCaseInterface {

    func invoke(idToken: String, e2eiClientId: E2eIClientID, userName: String, handle: String) async throws -> String

}

/// This class provides an interface to issue an E2EI certificate.
public final class EnrollE2eICertificateUseCase: EnrollE2eICertificateUseCaseInterface {

    var e2eiRepository: E2eIRepositoryInterface

    public init(e2eiRepository: E2eIRepositoryInterface) {
        self.e2eiRepository = e2eiRepository
    }

    public func invoke(idToken: String, e2eiClientId: E2eIClientID, userName: String, handle: String) async throws -> String {

        let enrollment = try await e2eiRepository.createEnrollment(e2eiClientId: e2eiClientId, userName: userName, handle: handle)

        let acmeNonce = try await enrollment.getACMENonce()
        let newAccountNonce = try await enrollment.createNewAccount(prevNonce: acmeNonce)
        let newOrder = try await enrollment.createNewOrder(prevNonce: newAccountNonce)
        let authzResponse = try await enrollment.createAuthz(prevNonce: newOrder.nonce,
                                                             authzEndpoint: newOrder.acmeOrder.authorizations[0])

        /// TODO: this method will be finished with the following PRs
        return authzResponse.nonce
    }

}
