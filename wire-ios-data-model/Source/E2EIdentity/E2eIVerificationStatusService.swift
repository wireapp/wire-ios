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

// sourcery: AutoMockable
public protocol E2eIVerificationStatusServiceInterface {

    func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus

}

public final class E2eIVerificationStatusService: E2eIVerificationStatusServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Error

    public enum E2eIVerificationStatusError: Error {

        case missingConversation
        case failedToFetchVerificationStatus

    }

    // MARK: - Public interface

    /// Returns the state of a conversation regarding end-to-end identity.
    ///
    /// - Parameters:
    ///  - groupID: the id of the MLS group for which to get the verification status
    /// - Throws:
    ///   `E2eIVerificationStatusError` if the status couldn't be fetched
    /// - Returns:
    /// - `MLSVerificationStatus`

    public func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus {
        /// TODO: should use try coreCryptoProvider.coreCrypto.e2eiConversationState(groupID) -> E2EIConversationState from the new CC version
        return E2EIConversationState.notVerified.toMLSVerificationStatus()
    }

}

// TODO: Remove it. It's a mock for an old CC version
public enum E2EIConversationState {
    case verified
    case notVerified
    case notEnabled
}

private extension E2EIConversationState {

    func toMLSVerificationStatus() -> MLSVerificationStatus {
        switch self {
        case .verified:
            return .verified
        case .notVerified, .notEnabled:
            return .notVerified
        }
    }

}
