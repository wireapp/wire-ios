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

public protocol E2eIServiceInterface {

    func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory
    func getNewAccountRequest(nonce: String) async throws -> Data
    func setAccountResponse(accountData: Data) async throws
    func getNewOrderRequest(nonce: String) async throws -> Data
    func setOrderResponse(order: Data) async throws -> NewAcmeOrder
    func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data
    func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz
    func createDpopToken(nonce: String) async throws -> String
    func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data
    func getNewOidcChallengeRequest(idToken: String, nonce: String) async throws -> Data
    func setChallengeResponse(challenge: Data) async throws
    func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data
    func checkOrderResponse(order: Data) async throws -> String
    func finalizeRequest(nonce: String) async throws -> Data
    func finalizeResponse(finalize: Data) async throws -> String
    func certificateRequest(nonce: String) async throws -> Data

}

/// This class provides an interface for WireE2eIdentityProtocol (CoreCrypto) methods.
public final class E2eIService: E2eIServiceInterface {

    public let e2eIdentity: WireE2eIdentityProtocol
    public init(e2eIdentity: WireE2eIdentityProtocol) {
        self.e2eIdentity = e2eIdentity
    }

    private let defaultDPoPTokenExpiry: UInt32 = 30

    // MARK: - Methods

    public func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory {
        return try e2eIdentity.directoryResponse(directory: directoryData.bytes)
    }

    public func getNewAccountRequest(nonce: String) async throws -> Data {
        return try e2eIdentity.newAccountRequest(previousNonce: nonce).data
    }

    public func setAccountResponse(accountData: Data) async throws {
        try e2eIdentity.newAccountResponse(account: accountData.bytes)
    }

    public func getNewOrderRequest(nonce: String) async throws -> Data {
        return try e2eIdentity.newOrderRequest(previousNonce: nonce).data
    }

    public func setOrderResponse(order: Data) async throws -> NewAcmeOrder {
        return try e2eIdentity.newOrderResponse(order: order.bytes)
    }

    public func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        return try e2eIdentity.newAuthzRequest(url: url, previousNonce: previousNonce).data
    }

    public func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        return try e2eIdentity.newAuthzResponse(authz: authz.bytes)
    }

    public func createDpopToken(nonce: String) async throws -> String {
        return try e2eIdentity.createDpopToken(expirySecs: defaultDPoPTokenExpiry, backendNonce: nonce)
    }

    public func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data {
        return try e2eIdentity.newDpopChallengeRequest(accessToken: accessToken, previousNonce: nonce).data
    }

    public func getNewOidcChallengeRequest(idToken: String, nonce: String) async throws -> Data {
        return try e2eIdentity.newOidcChallengeRequest(idToken: idToken, previousNonce: nonce).data
    }

    public func setChallengeResponse(challenge: Data) async throws {
        return try e2eIdentity.newChallengeResponse(challenge: challenge.bytes)
    }

    public func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data {
        return try e2eIdentity.checkOrderRequest(orderUrl: orderUrl, previousNonce: nonce).data
    }

    public func checkOrderResponse(order: Data) async throws -> String {
        return try e2eIdentity.checkOrderResponse(order: order.bytes)
    }

    public func finalizeRequest(nonce: String) async throws -> Data {
        return try e2eIdentity.finalizeRequest(previousNonce: nonce).data
    }

    public func finalizeResponse(finalize: Data) async throws -> String {
        return try e2eIdentity.finalizeResponse(finalize: finalize.bytes)
    }

    public func certificateRequest(nonce: String) async throws -> Data {
        return try e2eIdentity.certificateRequest(previousNonce: nonce).data
    }

}
