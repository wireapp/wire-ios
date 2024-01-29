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

public protocol E2eISetupServiceInterface {

    func setupEnrollment(userName: String, handle: String, team: UUID) async throws -> E2eiEnrollment

}

/// This class setups e2eIdentity object from CoreCrypto.
public final class E2eISetupService: E2eISetupServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func setupEnrollment(userName: String, handle: String, team: UUID) async throws -> E2eiEnrollment {
        do {
            return try await setupNewActivationOrRotate(userName: userName, handle: handle, teamId: team)
        } catch {
            throw Failure.failedToSetupE2eIClient(error)
        }
    }

    private func setupNewActivationOrRotate(
        userName: String,
        handle: String,
        teamId: UUID) async throws -> E2eiEnrollment {
            let ciphersuite = CiphersuiteName.default.rawValue
            let expiryDays = UInt32(90)

            return try await coreCryptoProvider.coreCrypto(requireMLS: true).perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: ciphersuite)
                if e2eiIsEnabled {
                    return try await $0.e2eiNewRotateEnrollment(displayName: userName,
                                                                handle: handle,
                                                                team: teamId.uuidString.lowercased(),
                                                                expirySec: expiryDays,
                                                                ciphersuite: ciphersuite)
                } else {
                    return try await $0.e2eiNewActivationEnrollment(displayName: userName,
                                                                    handle: handle,
                                                                    team: teamId.uuidString.lowercased(),
                                                                    expirySec: expiryDays,
                                                                    ciphersuite: ciphersuite)
                }
            }
        }

    enum Failure: Error {
        case failedToSetupE2eIClient(_ underlyingError: Error?)
    }

}
