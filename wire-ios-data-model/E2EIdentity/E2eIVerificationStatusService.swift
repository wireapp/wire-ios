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
    private var coreCrypto: SafeCoreCryptoProtocol {
        get throws {
            try coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus {
        /// TODO: should use coreCrypto.e2eiConversationState(groupID) -> E2EIConversationState from the new CC version
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
