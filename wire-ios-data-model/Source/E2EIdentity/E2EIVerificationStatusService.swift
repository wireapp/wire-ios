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

// MARK: - E2EIVerificationStatusServiceInterface

// sourcery: AutoMockable
public protocol E2EIVerificationStatusServiceInterface {
    func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus
}

// MARK: - E2EIVerificationStatusService

public final class E2EIVerificationStatusService: E2EIVerificationStatusServiceInterface {
    // MARK: Lifecycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: Public

    // MARK: - Error

    public enum E2EIVerificationStatusError: Error {
        case missingConversation
        case failedToFetchVerificationStatus
    }

    // MARK: - Public interface

    /// Returns the state of a conversation regarding end-to-end identity.
    /// Note: coreCrypto indicates a conversation with one of the states: `verified`, `notVerified`, `notEnabled`.
    /// For further use, we need to convert it to MLSVerificationStatus, which has `verified`, `notVerified`, and
    /// `degraded` states.
    ///
    /// - Parameters:
    ///  - groupID: the id of the MLS group for which to get the verification status
    /// - Throws:
    ///   `E2eIVerificationStatusError` if the status couldn't be fetched
    /// - Returns:
    /// - `MLSVerificationStatus`

    public func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus {
        do {
            return try await coreCrypto.perform {
                try await $0.e2eiConversationState(conversationId: groupID.data).toMLSVerificationStatus()
            }
        } catch {
            WireLogger.e2ei
                .warn("can't get conversation \(groupID.safeForLoggingDescription) verification state: \(error)")

            throw E2EIVerificationStatusError.failedToFetchVerificationStatus
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }
}

extension WireCoreCrypto.E2eiConversationState {
    fileprivate func toMLSVerificationStatus() -> MLSVerificationStatus {
        switch self {
        case .verified:
            return .verified
        case .notEnabled,
             .notVerified:
            return .notVerified
        @unknown default:
            fatalError("unsupported value of 'E2eiConversationState'!")
        }
    }
}
