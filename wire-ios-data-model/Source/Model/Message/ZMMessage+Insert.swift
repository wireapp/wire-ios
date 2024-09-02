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

extension ZMMessage {
    @objc public func prepareToSend() {
        expireAndNotifyIfInsertingIntoDegradedConversation()
    }

    /// If we are adding the message to a degraded conversation we want to expire it immediately
    /// and fire a notification on conversation security level change so that UI could act accordingly
    fileprivate func expireAndNotifyIfInsertingIntoDegradedConversation() {
        guard let conversation = self.conversation else { return }
        guard let currentMoc = self.managedObjectContext else { return }
        guard let syncMoc = currentMoc.zm_sync else { return }
        guard let uiMoc = currentMoc.zm_userInterface else { return }
        if conversation.isDegraded && self.deliveryState == .pending {
            let verificationStatusKey = verificationStatusKey(for: conversation.messageProtocol)

            currentMoc.saveOrRollback()
            syncMoc.performGroupedBlock {
                guard let message = (try? syncMoc.existingObject(with: self.objectID)) as? ZMOTRMessage else { return }
                message.causedSecurityLevelDegradation = true
                WireLogger.messaging.warn("expiring message because inserting into degraded conversation " + String(describing: message.nonce?.transportString().readableHash))
                message.expire(withReason: .other)

                syncMoc.saveOrRollback()
                NotificationDispatcher.notifyNonCoreDataChanges(
                    objectID: conversation.objectID,
                    changedKeys: [verificationStatusKey],
                    uiContext: uiMoc)
            }
        }
    }

    private func verificationStatusKey(for messageProtocol: MessageProtocol) -> String {
        switch messageProtocol {
        case .proteus:
            return #keyPath(ZMConversation.securityLevel)
        case .mls, .mixed:
            return ZMConversation.mlsVerificationStatusKey
        }
    }
}
