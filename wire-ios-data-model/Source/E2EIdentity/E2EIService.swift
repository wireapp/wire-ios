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

import Combine
import Foundation
import WireCoreCrypto

// MARK: - E2EIServiceInterface

// sourcery: AutoMockable
public protocol E2EIServiceInterface {
    func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory
    func getNewAccountRequest(nonce: String) async throws -> Data
    func setAccountResponse(accountData: Data) async throws
    func getNewOrderRequest(nonce: String) async throws -> Data
    func setOrderResponse(order: Data) async throws -> NewAcmeOrder
    func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data
    func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz
    func getOAuthRefreshToken() async throws -> String
    func createDpopToken(nonce: String) async throws -> String
    func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data
    func getNewOidcChallengeRequest(idToken: String, refreshToken: String, nonce: String) async throws -> Data
    func setDPoPChallengeResponse(challenge: Data) async throws
    func setOIDCChallengeResponse(challenge: Data) async throws
    func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data
    func checkOrderResponse(order: Data) async throws -> String
    func finalizeRequest(nonce: String) async throws -> Data
    func finalizeResponse(finalize: Data) async throws -> String
    func certificateRequest(nonce: String) async throws -> Data
    func createNewClient(certificateChain: String) async throws

    var e2eIdentity: E2eiEnrollmentProtocol { get }
}

// MARK: - E2EIService

/// This class provides an interface for WireE2eIdentityProtocol (CoreCrypto) methods.
public final class E2EIService: E2EIServiceInterface {
    // MARK: - Properties

    private let onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>
    private let defaultDPoPTokenExpiry: UInt32 = 30
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    public let e2eIdentity: E2eiEnrollmentProtocol

    // MARK: - Life cycle

    public init(
        e2eIdentity: E2eiEnrollmentProtocol,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>
    ) {
        self.e2eIdentity = e2eIdentity
        self.coreCryptoProvider = coreCryptoProvider
        self.onNewCRLsDistributionPointsSubject = onNewCRLsDistributionPointsSubject
    }

    // MARK: - Methods

    public func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory {
        try await e2eIdentity.directoryResponse(directory: directoryData)
    }

    public func getNewAccountRequest(nonce: String) async throws -> Data {
        try await e2eIdentity.newAccountRequest(previousNonce: nonce)
    }

    public func setAccountResponse(accountData: Data) async throws {
        try await e2eIdentity.newAccountResponse(account: accountData)
    }

    public func getNewOrderRequest(nonce: String) async throws -> Data {
        try await e2eIdentity.newOrderRequest(previousNonce: nonce)
    }

    public func setOrderResponse(order: Data) async throws -> NewAcmeOrder {
        try await e2eIdentity.newOrderResponse(order: order)
    }

    public func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        try await e2eIdentity.newAuthzRequest(url: url, previousNonce: previousNonce)
    }

    public func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        try await e2eIdentity.newAuthzResponse(authz: authz)
    }

    public func getOAuthRefreshToken() async throws -> String {
        try await e2eIdentity.getRefreshToken()
    }

    public func createDpopToken(nonce: String) async throws -> String {
        try await e2eIdentity.createDpopToken(expirySecs: defaultDPoPTokenExpiry, backendNonce: nonce)
    }

    public func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data {
        try await e2eIdentity.newDpopChallengeRequest(accessToken: accessToken, previousNonce: nonce)
    }

    public func getNewOidcChallengeRequest(idToken: String, refreshToken: String, nonce: String) async throws -> Data {
        try await e2eIdentity.newOidcChallengeRequest(
            idToken: idToken,
            refreshToken: refreshToken,
            previousNonce: nonce
        )
    }

    public func setDPoPChallengeResponse(challenge: Data) async throws {
        try await e2eIdentity.newDpopChallengeResponse(challenge: challenge)
    }

    public func setOIDCChallengeResponse(challenge: Data) async throws {
        try await coreCrypto.perform {
            guard let coreCrypto = $0 as? CoreCrypto else {
                throw E2EIServiceFailure.missingCoreCrypto
            }

            return try await e2eIdentity.newOidcChallengeResponse(cc: coreCrypto, challenge: challenge)
        }
    }

    public func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data {
        try await e2eIdentity.checkOrderRequest(orderUrl: orderUrl, previousNonce: nonce)
    }

    public func checkOrderResponse(order: Data) async throws -> String {
        try await e2eIdentity.checkOrderResponse(order: order)
    }

    public func finalizeRequest(nonce: String) async throws -> Data {
        try await e2eIdentity.finalizeRequest(previousNonce: nonce)
    }

    public func finalizeResponse(finalize: Data) async throws -> String {
        try await e2eIdentity.finalizeResponse(finalize: finalize)
    }

    public func certificateRequest(nonce: String) async throws -> Data {
        try await e2eIdentity.certificateRequest(previousNonce: nonce)
    }

    public func createNewClient(certificateChain: String) async throws {
        guard let enrollment = e2eIdentity as? E2eiEnrollment else {
            throw E2EIServiceFailure.missingEnrollment
        }

        let crlDistributionPoints = try await coreCryptoProvider.initialiseMLSWithEndToEndIdentity(
            enrollment: enrollment,
            certificateChain: certificateChain
        )

        if let crlDistributionPoints {
            onNewCRLsDistributionPointsSubject.send(crlDistributionPoints)
        }
    }

    enum E2EIServiceFailure: Error {
        case missingCoreCrypto
        case missingEnrollment
    }
}
