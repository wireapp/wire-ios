//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDataModel
import WireFoundation

// sourcery: AutoMockable
public protocol ResetMLSConversationLockRepositoryProtocol {
    func setInitiatedReset(conversationID: WireDataModel.QualifiedID)
    func wasResetInitiated(conversationID: WireDataModel.QualifiedID) -> Bool
    func removeResetInitiated(conversationID: WireDataModel.QualifiedID)
}

/// Used to synchronise access from 'Initiate' and 'Handle event' steps of reset broken MLS conversations
/// When initiated we do not need to handle sent event if it's same device
public struct ResetMLSConversationLockRepository: ResetMLSConversationLockRepositoryProtocol {

    enum Key: String, DefaultsKey {
        case resetMLSConversationInitiated
    }

    private let privateUserDefaults: PrivateUserDefaults<Key>

    public init(userID: UUID) {
        self.privateUserDefaults = .init(userID: userID)
    }

    public func setInitiatedReset(conversationID: WireDataModel.QualifiedID) {
        privateUserDefaults
            .set(
                true,
                forKey: .resetMLSConversationInitiated,
                additionalScope: conversationID.uuid.uuidString
            )
    }

    public func wasResetInitiated(conversationID: WireDataModel.QualifiedID) -> Bool {
        privateUserDefaults.bool(
            forKey: .resetMLSConversationInitiated,
            additionalScope: conversationID.uuid.uuidString
        )
    }

    public func removeResetInitiated(conversationID: WireDataModel.QualifiedID) {
        privateUserDefaults.removeObject(
            forKey: .resetMLSConversationInitiated,
            additionalScope: conversationID.uuid.uuidString,
        )
    }

}
