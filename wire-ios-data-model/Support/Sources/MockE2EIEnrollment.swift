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
import WireCoreCrypto

class MockE2EIEnrollment: E2eiEnrollmentProtocol {
    // MARK: - directoryResponse

    var mockDirectoryResponse: ((Data) async throws -> AcmeDirectory)?

    // MARK: - newAccountRequest

    var mockNewAccountRequest: ((String) async throws -> Data)?

    // MARK: - newAccountResponse

    var mockNewAccountResponse: ((Data) async throws -> Void)?

    // MARK: - newOrderRequest

    var mockNewOrderRequest: ((String) async throws -> Data)?

    // MARK: - newOrderResponse

    var mockNewOrderResponse: ((Data) async throws -> NewAcmeOrder)?

    // MARK: - newAuthzRequest

    var mockNewAuthzRequest: ((String, String) async throws -> Data)?

    // MARK: - newAuthzResponse

    var mockNewAuthzResponse: ((Data) async throws -> NewAcmeAuthz)?

    // MARK: - createDpopToken

    var mockCreateDpopToken: ((UInt32, String) throws -> String)?

    // MARK: - getRefreshToken

    var mockGetRefreshToken: (() async throws -> String)?

    // MARK: - newDpopChallengeRequest

    var mockNewDpopChallengeRequest: ((String, String) async throws -> Data)?

    // MARK: - newOidcChallengeRequest

    var mockNewOidcChallengeRequest: ((String, String, String) async throws -> Data)?

    // MARK: - newDpopChallengeResponse

    var mockNewDpopChallengeResponse: ((Data) async throws -> Void)?

    // MARK: - newOidcChallengeResponse

    var mockNewOidcChallengeResponse: ((WireCoreCrypto.CoreCrypto, Data) async throws -> Void)?

    // MARK: - checkOrderRequest

    var mockCheckOrderRequest: ((String, String) async throws -> Data)?

    // MARK: - checkOrderResponse

    var mockCheckOrderResponse: ((Data) async throws -> String)?

    // MARK: - finalizeRequest

    var mockFinalizeRequest: ((String) async throws -> Data)?

    // MARK: - finalizeResponse

    var mockFinalizeResponse: ((Data) async throws -> String)?

    // MARK: - certificateRequest

    var mockCertificateRequest: ((String) async throws -> Data)?

    func directoryResponse(directory: Data) async throws -> AcmeDirectory {
        guard let mock = mockDirectoryResponse else {
            fatalError("no mock for `mockDirectoryResponse`")
        }

        return try await mock(directory)
    }

    func newAccountRequest(previousNonce: String) async throws -> Data {
        guard let mock = mockNewAccountRequest else {
            fatalError("no mock for `mockNewAccountRequest`")
        }

        return try await mock(previousNonce)
    }

    func newAccountResponse(account: Data) async throws {
        guard let mock = mockNewAccountResponse else {
            fatalError("no mock for `mockNewAccountResponse`")
        }

        return try await mock(account)
    }

    func newOrderRequest(previousNonce: String) async throws -> Data {
        guard let mock = mockNewOrderRequest else {
            fatalError("no mock for `mockNewOrderRequest`")
        }

        return try await mock(previousNonce)
    }

    func newOrderResponse(order: Data) async throws -> NewAcmeOrder {
        guard let mock = mockNewOrderResponse else {
            fatalError("no mock for `mockNewOrderResponse`")
        }

        return try await mock(order)
    }

    func newAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        guard let mock = mockNewAuthzRequest else {
            fatalError("no mock for `mockNewAuthzRequest`")
        }

        return try await mock(url, previousNonce)
    }

    func newAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        guard let mock = mockNewAuthzResponse else {
            fatalError("no mock for `mockNewAuthzResponse`")
        }

        return try await mock(authz)
    }

    func createDpopToken(expirySecs: UInt32, backendNonce: String) throws -> String {
        guard let mock = mockCreateDpopToken else {
            fatalError("no mock for `mockCreateDpopToken`")
        }

        return try mock(expirySecs, backendNonce)
    }

    func getRefreshToken() async throws -> String {
        guard let mock = mockGetRefreshToken else {
            fatalError("no mock for `mockGetRefreshToken`")
        }

        return try await mock()
    }

    func newDpopChallengeRequest(accessToken: String, previousNonce: String) async throws -> Data {
        guard let mock = mockNewDpopChallengeRequest else {
            fatalError("no mock for `mockNewDpopChallengeRequest`")
        }

        return try await mock(accessToken, previousNonce)
    }

    func newOidcChallengeRequest(idToken: String, refreshToken: String, previousNonce: String) async throws -> Data {
        guard let mock = mockNewOidcChallengeRequest else {
            fatalError("no mock for `mockNewOidcChallengeRequest`")
        }

        return try await mock(idToken, refreshToken, previousNonce)
    }

    func newDpopChallengeResponse(challenge: Data) async throws {
        guard let mock = mockNewDpopChallengeResponse else {
            fatalError("no mock for `mockNewDpopChallengeResponse`")
        }

        return try await mock(challenge)
    }

    func newOidcChallengeResponse(cc: WireCoreCrypto.CoreCrypto, challenge: Data) async throws {
        guard let mock = mockNewOidcChallengeResponse else {
            fatalError("no mock for `mockNewOidcChallengeResponse`")
        }

        return try await mock(cc, challenge)
    }

    func checkOrderRequest(orderUrl: String, previousNonce: String) async throws -> Data {
        guard let mock = mockCheckOrderRequest else {
            fatalError("no mock for `mockCheckOrderRequest`")
        }

        return try await mock(orderUrl, previousNonce)
    }

    func checkOrderResponse(order: Data) async throws -> String {
        guard let mock = mockCheckOrderResponse else {
            fatalError("no mock for `mockCheckOrderResponse`")
        }

        return try await mock(order)
    }

    func finalizeRequest(previousNonce: String) async throws -> Data {
        guard let mock = mockFinalizeRequest else {
            fatalError("no mock for `mockFinalizeRequest`")
        }

        return try await mock(previousNonce)
    }

    func finalizeResponse(finalize: Data) async throws -> String {
        guard let mock = mockFinalizeResponse else {
            fatalError("no mock for `mockFinalizeResponse`")
        }

        return try await mock(finalize)
    }

    func certificateRequest(previousNonce: String) async throws -> Data {
        guard let mock = mockCertificateRequest else {
            fatalError("no mock for `mockCertificateRequest`")
        }

        return try await mock(previousNonce)
    }
}
