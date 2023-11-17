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

    func directoryResponse(directoryData: Data) async throws -> WireCoreCrypto.AcmeDirectory
    func getNewAccountRequest(previousNonce: String) async throws -> Data
    func setAccountResponse(accountData: Data) async throws
    func getNewOrderRequest(nonce: String) async throws -> Data
    func setOrderResponse(order: Data) async throws -> WireCoreCrypto.NewAcmeOrder

}

public final class E2EIService: E2EIServiceInterface {

    // MARK: - Properties

    private weak var context: NSManagedObjectContext?
    public var wireE2eIdentity: WireE2eIdentity?
    private let coreCrypto: SafeCoreCryptoProtocol

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext,
                coreCrypto: SafeCoreCryptoProtocol) {
        self.context = context
        self.coreCrypto = coreCrypto
    }

    // MARK: - Setup enrollment

    public func setupNewEnrollment() {
        guard
            let context = context,
            let selfUserHandle = ZMUser.selfUser(in: context).handle,
            let selfUserName = ZMUser.selfUser(in: context).name,
            let selfClient = ZMUser.selfUser(in: context).selfClient(),
            let clientId = MLSClientID(userClient: selfClient)
        else {
            return
        }
        // TODO: we should use the new CoreCrypto version: `e2eiNewRotateEnrollment` and `e2eiNewActivationEnrollment`
        print(clientId.rawValue)
        print(clientId)
        wireE2eIdentity = try? coreCrypto.perform { try $0.e2eiNewEnrollment(clientId: "OWE0ZGVkNDYtYmE4Yi00MTI0LTk1MDktZTgzZjkwMmFiMWVk:871610f2e52b6480@elna.wire.link",
//                                                                                clientId.rawValue,
                                                                             displayName: selfUserName,
                                                                             handle: selfUserHandle,
                                                                             expiryDays: UInt32(90),
                                                                             ciphersuite: defaultCipherSuite.rawValue)

        }

    }

    public func isE2EIEnabled() -> Bool {
        // TODO: we should use the new CoreCrypto version
        // return coreCrypto.e2eiIsEnabled(defaultCipherSuite.rawValue)
        return true
    }

    // MARK: - WireE2EIdentity methods

    public func directoryResponse(directoryData: Data) async throws -> WireCoreCrypto.AcmeDirectory {
        let buffer = [UInt8](directoryData)
        guard let wireE2eIdentity = wireE2eIdentity else {
            WireLogger.e2ei.warn("wireE2eIdentity is missing")

            throw Failure.failedToEncodeDirectoryResponse
        }

        do {
            return try wireE2eIdentity.directoryResponse(directory: buffer)
        } catch {
            throw Failure.failedToEncodeDirectoryResponse
        }
    }

    public func getNewAccountRequest(previousNonce: String) async throws -> Data {
        guard let wireE2eIdentity = wireE2eIdentity else {
            WireLogger.e2ei.warn("wireE2eIdentity is missing")

            throw Failure.failedToGetAccountRequest
        }
        do {
            let accountRequest = try wireE2eIdentity.newAccountRequest(previousNonce: previousNonce)
            return accountRequest.data
        } catch {
            throw Failure.failedToGetAccountRequest
        }
    }

    public func setAccountResponse(accountData: Data) async throws {
        let acc = try JSONDecoder().decode(NewAccResponse.self, from: accountData)
        print(acc)
        guard let wireE2eIdentity = wireE2eIdentity else {
            WireLogger.e2ei.warn("wireE2eIdentity is missing")

            throw Failure.failedToSetAccountResponse
        }

        let buffer = [UInt8](accountData)
        do {
            try wireE2eIdentity.newAccountResponse(account: buffer)
        } catch {
            throw Failure.failedToSetAccountResponse
        }
    }

    public func getNewOrderRequest(nonce: String) async throws -> Data {
        guard let wireE2eIdentity = wireE2eIdentity else {
            WireLogger.e2ei.warn("wireE2eIdentity is missing")

            throw Failure.failedToGetNewOrderRequest
        }
        do {
            let bytes = try wireE2eIdentity.newOrderRequest(previousNonce: nonce)
            print(bytes)
            print(bytes.data)
            return bytes.data
        } catch {
            print("Error:  \(error as! E2eIdentityError)")
            throw Failure.failedToGetNewOrderRequest
        }
    }

    public func setOrderResponse(order: Data) async throws -> WireCoreCrypto.NewAcmeOrder {
        guard let wireE2eIdentity = wireE2eIdentity else {
            WireLogger.e2ei.warn("wireE2eIdentity is missing")

            throw Failure.failedToSetOrderResponse
        }
        let buffer = [UInt8](order)
        do {
            return try wireE2eIdentity.newOrderResponse(order: buffer)
        } catch {
            throw Failure.failedToSetOrderResponse
        }

    }
    
    struct NewAccResponse: Decodable {
        let contact: [String]
        let status: String
        let orders: String
    }

    enum Failure: Error, Equatable {

        case failedToEncodeDirectoryResponse
        case failedToGetAccountRequest
        case failedToSetAccountResponse
        case failedToGetNewOrderRequest
        case failedToSetOrderResponse

    }

}
