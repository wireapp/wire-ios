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

public protocol E2EIServiceInterface {

    func setupEnrollment()
    func directoryResponse(directoryData: Data) throws -> AcmeDirectory
    func getNewAccountRequest(previousNonce: String) async throws -> Data
    func setAccountResponse(accountData: Data) async throws

}

/// This class provides an interface for CoreCrypto methods related to E2EI.
public final class E2EIService: E2EIServiceInterface {

    // MARK: - Properties

    public var e2eIdentity: WireE2eIdentity?

    private let coreCrypto: SafeCoreCryptoProtocol
    private let selfUser: ZMUser

    // MARK: - Life cycle

    public init(coreCrypto: SafeCoreCryptoProtocol,
                selfUser: ZMUser) {
        self.coreCrypto = coreCrypto
        self.selfUser = selfUser
    }

    // MARK: - Setup enrollment

    public func setupEnrollment() {
        guard
            let handle = selfUser.handle,
            let name = selfUser.name,
            let selfClient = selfUser.selfClient(),
            let clientId = MLSClientID(userClient: selfClient)
        else {
            return
        }
        // TODO: we should use the new CoreCrypto version: `e2eiNewRotateEnrollment` and `e2eiNewActivationEnrollment`
        e2eIdentity = try? coreCrypto.perform {
            try $0.e2eiNewEnrollment(clientId: clientId.rawValue,
                                     displayName: name,
                                     handle: handle,
                                     expiryDays: UInt32(90),
                                     ciphersuite: defaultCipherSuite.rawValue)

        }
    }

    // MARK: - E2EIdentity methods

    public func directoryResponse(directoryData: Data) throws -> AcmeDirectory {
        return try wireE2eIdentity().directoryResponse(directory: directoryData.bytes)
    }

    public func getNewAccountRequest(previousNonce: String) async throws -> Data {
        return try wireE2eIdentity().newAccountRequest(previousNonce: previousNonce).data
    }

    public func setAccountResponse(accountData: Data) async throws {
        try wireE2eIdentity().newAccountResponse(account: accountData.bytes)
    }

    // MARK: - Private methods

    private func wireE2eIdentity() throws -> WireE2eIdentity {
        guard let e2eIdentity = e2eIdentity else {
            throw Failure.missingE2eIdentity
        }
        return e2eIdentity
    }

    enum Failure: Error, Equatable {

        case missingE2eIdentity

    }

}
