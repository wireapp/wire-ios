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
import WireCoreCrypto
@testable import WireRequestStrategy

class MockWireE2eIdentity: WireE2eIdentityProtocol {

    // MARK: - directoryResponse

    var mockDirectoryResponse: (([UInt8]) throws -> AcmeDirectory)?

    func directoryResponse(directory: [UInt8]) throws -> AcmeDirectory {
        guard let mock = mockDirectoryResponse else {
            fatalError("no mock for `mockDirectoryResponse`")
        }

        return try mock(directory)
    }

    // MARK: - newAccountRequest

    var mockNewAccountRequest: ((String) throws -> [UInt8])?

    func newAccountRequest(previousNonce: String) throws -> [UInt8] {
        guard let mock = mockNewAccountRequest else {
            fatalError("no mock for `mockNewAccountRequest`")
        }

        return try mock(previousNonce)
    }

    // MARK: - newAccountResponse

    var mockNewAccountResponse: (([UInt8]) throws -> Void)?

    func newAccountResponse(account: [UInt8]) throws {
        guard let mock = mockNewAccountResponse else {
            fatalError("no mock for `mockNewAccountResponse`")
        }

        return try mock(account)
    }

    // MARK: - newOrderRequest

    var mockNewOrderRequest: ((String) throws -> [UInt8])?

    func newOrderRequest(previousNonce: String) throws -> [UInt8] {
        guard let mock = mockNewOrderRequest else {
            fatalError("no mock for `mockNewOrderRequest`")
        }

        return try mock(previousNonce)
    }

    // MARK: - newOrderResponse

    var mockNewOrderResponse: (([UInt8]) throws -> NewAcmeOrder)?

    func newOrderResponse(order: [UInt8]) throws -> NewAcmeOrder {
        guard let mock = mockNewOrderResponse else {
            fatalError("no mock for `mockNewOrderResponse`")
        }

        return try mock(order)
    }

    // MARK: - newAuthzRequest

    var mockNewAuthzRequest: ((String, String) throws -> [UInt8])?

    func newAuthzRequest(url: String, previousNonce: String) throws -> [UInt8] {
        guard let mock = mockNewAuthzRequest else {
            fatalError("no mock for `mockNewAuthzRequest`")
        }

        return try mock(url, previousNonce)
    }

    // MARK: - newAuthzResponse

    var mockNewAuthzResponse: (([UInt8]) throws -> NewAcmeAuthz)?

    func newAuthzResponse(authz: [UInt8]) throws -> NewAcmeAuthz {
        guard let mock = mockNewAuthzResponse else {
            fatalError("no mock for `mockNewAuthzResponse`")
        }

        return try mock(authz)
    }

    // MARK: - createDpopToken

    var mockCreateDpopToken: ((UInt32, String) throws -> String)?

    func createDpopToken(expirySecs: UInt32, backendNonce: String) throws -> String {
        guard let mock = mockCreateDpopToken else {
            fatalError("no mock for `mockCreateDpopToken`")
        }

        return try mock(expirySecs, backendNonce)
    }

    // MARK: - newDpopChallengeRequest

    var mockNewDpopChallengeRequest: ((String, String) throws -> [UInt8])?

    func newDpopChallengeRequest(accessToken: String, previousNonce: String) throws -> [UInt8] {
        guard let mock = mockNewDpopChallengeRequest else {
            fatalError("no mock for `mockNewDpopChallengeRequest`")
        }

        return try mock(accessToken, previousNonce)
    }

    // MARK: - newOidcChallengeRequest

    var mockNewOidcChallengeRequest: ((String, String) throws -> [UInt8])?

    func newOidcChallengeRequest(idToken: String, previousNonce: String) throws -> [UInt8] {
        guard let mock = mockNewOidcChallengeRequest else {
            fatalError("no mock for `mockNewOidcChallengeRequest`")
        }

        return try mock(idToken, previousNonce)
    }

    // MARK: - newChallengeResponse

    var mockNewChallengeResponse: (([UInt8]) throws -> Void)?

    func newChallengeResponse(challenge: [UInt8]) throws {
        guard let mock = mockNewChallengeResponse else {
            fatalError("no mock for `mockNewChallengeResponse`")
        }

        return try mock(challenge)
    }

    // MARK: - checkOrderRequest

    var mockCheckOrderRequest: ((String, String) throws -> [UInt8])?

    func checkOrderRequest(orderUrl: String, previousNonce: String) throws -> [UInt8] {
        guard let mock = mockCheckOrderRequest else {
            fatalError("no mock for `mockCheckOrderRequest`")
        }

        return try mock(orderUrl, previousNonce)
    }

    // MARK: - checkOrderResponse

    var mockCheckOrderResponse: (([UInt8]) throws -> String)?

    func checkOrderResponse(order: [UInt8]) throws -> String {
        guard let mock = mockCheckOrderResponse else {
            fatalError("no mock for `mockCheckOrderResponse`")
        }

        return try mock(order)
    }

    // MARK: - finalizeRequest

    var mockFinalizeRequest: ((String) throws -> [UInt8])?

    func finalizeRequest(previousNonce: String) throws -> [UInt8] {
        guard let mock = mockFinalizeRequest else {
            fatalError("no mock for `mockFinalizeRequest`")
        }

        return try mock(previousNonce)
    }

    // MARK: - finalizeResponse

    var mockFinalizeResponse: (([UInt8]) throws -> String)?

    func finalizeResponse(finalize: [UInt8]) throws -> String {
        guard let mock = mockFinalizeResponse else {
            fatalError("no mock for `mockFinalizeResponse`")
        }

        return try mock(finalize)
    }

    // MARK: - certificateRequest

    var mockCertificateRequest: ((String) throws -> [UInt8])?

    func certificateRequest(previousNonce: String) throws -> [UInt8] {
        guard let mock = mockCertificateRequest else {
            fatalError("no mock for `mockCertificateRequest`")
        }

        return try mock(previousNonce)
    }

}
