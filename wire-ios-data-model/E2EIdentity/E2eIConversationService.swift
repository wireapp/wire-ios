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

public protocol E2eIConversationServiceInterface {

    func getConversationVerificationStatus(groupID: MLSGroupID) -> MLSVerificationStatus

}

public final class E2eIConversationService: E2eIConversationServiceInterface {
    private let coreCrypto: SafeCoreCryptoProtocol
    public init(coreCrypto: SafeCoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
    }

    public func getConversationVerificationStatus(groupID: MLSGroupID) -> MLSVerificationStatus {
        /// TODO: should use coreCrypto.e2eiConversationState(groupID) -> E2EIConversationState
        /// will be available in the latest CC version.
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
