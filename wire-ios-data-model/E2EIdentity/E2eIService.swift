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

}

/// This class provides an interface for WireE2eIdentityProtocol (CoreCrypto) methods.
public final class E2eIService: E2eIServiceInterface {

    public let e2eIdentity: WireE2eIdentityProtocol
    public init(e2eIdentity: WireE2eIdentityProtocol) {
        self.e2eIdentity = e2eIdentity
    }

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

}
