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

public protocol E2eIClientInterface {

    func setupEnrollment(e2eiClientId: E2eIClientID, userName: String, handle: String) async throws -> WireE2eIdentityProtocol

}

// TODO: change to Service
/// This class setups e2eIdentity object from CoreCrypto.
public final class E2eIClient: E2eIClientInterface {

    private let coreCrypto: SafeCoreCryptoProtocol
    public init(coreCrypto: SafeCoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
    }

    public func setupEnrollment(e2eiClientId: E2eIClientID, userName: String, handle: String) async throws -> WireE2eIdentityProtocol {
        do {
            return try coreCrypto.perform {
                /// TODO: Use e2eiNewRotateEnrollment or e2eiNewActivationEnrollment from the new CC version
                try $0.e2eiNewEnrollment(clientId: e2eiClientId.rawValue,
                                         displayName: userName,
                                         handle: handle,
                                         expiryDays: UInt32(90),
                                         ciphersuite: defaultCipherSuite.rawValue)
            }

        } catch {
            throw Failure.failedToSetupE2eIClient(error)
        }
    }

    enum Failure: Error {
        case failedToSetupE2eIClient(_ underlyingError: Error)
    }

}

// TODO: Move to the separate file
protocol MLSConversationsVerificationStatusesHandler {
    func invoke()
    /// epoch observer -> conversation (groupID)
    /// MLSConversationService.getConversationVerificationStatus(conversation.iD) -> newStatus
    ///  getconversationByGroupID -> conversation
    /// updateStatusAndNotifyUserIfNeeded (conversation)
    ///
    /// **private func updateStatusAndNotifyUserIfNeeded (conversation)**
    /// var currentStatus = conversation.conversation.mlsVerificationStatus
    /// var newStatus = getActualNewStatus(newStatusFromCC, currentStatus)
    /// if (newStatus == currentStatus) return
    /// conversationRepository.updateMlsVerificationStatus(newStatus, conversation.conversation.id)
    /// if (newStatus == VerificationStatus.DEGRADED || newStatus == VerificationStatus.VERIFIED) {
    ///    notifyUserAboutStateChanges(conversation.conversation.id, newStatus)
    /// }
}

public enum VerificationStatus {
    case verified
    case notVerified
    case degraded
}

public protocol MLSConversationServiceInterface {
    func getConversationVerificationStatus(groupID: MLSGroupID) -> Bool
}
class MLSConversationService: MLSConversationServiceInterface {
    private let coreCrypto: SafeCoreCryptoProtocol
    public init(coreCrypto: SafeCoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
    }

    public func getConversationVerificationStatus(groupID: MLSGroupID) -> Bool {
        /// another method
        return coreCrypto.perform { $0.conversationExists(conversationId: groupID.bytes) }
    }
}
// mlsVerificationState
