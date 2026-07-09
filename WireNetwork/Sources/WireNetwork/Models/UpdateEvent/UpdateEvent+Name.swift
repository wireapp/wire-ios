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

import Foundation

public extension UpdateEvent {

    var name: String {
        switch self {
        case let .conversation(event):
            switch event {
            case .accessUpdate:
                "conversation.accessUpdate"
            case .codeUpdate:
                "conversation.codeUpdate"
            case .create:
                "conversation.create"
            case .delete:
                "conversation.delete"
            case .memberJoin:
                "conversation.memberJoin"
            case .memberLeave:
                "conversation.memberLeave"
            case .memberUpdate:
                "conversation.memberUpdate"
            case .messageTimerUpdate:
                "conversation.messageTimerUpdate"
            case .mlsMessageAdd:
                "conversation.mlsMessageAdd"
            case .mlsWelcome:
                "conversation.mlsWelcome"
            case .proteusMessageAdd:
                "conversation.proteusMessageAdd"
            case .protocolUpdate:
                "conversation.protocolUpdate"
            case .receiptModeUpdate:
                "conversation.receiptModeUpdate"
            case .rename:
                "conversation.rename"
            case .typing:
                "conversation.typing"
            case .permissionUpdate:
                "conversation.add-permission-update"
            case .mlsReset:
                "conversation.mls-reset"
            }
        case let .featureConfig(event):
            switch event {
            case .update:
                "featureConfig.update"
            }
        case let .federation(event):
            switch event {
            case .connectionRemoved:
                "federation.connectionRemoved"
            case .delete:
                "federation.delete"
            }
        case let .user(event):
            switch event {
            case .clientAdd:
                "user.clientAdd"
            case .clientRemove:
                "user.clientRemove"
            case .connection:
                "user.connection"
            case .contactJoin:
                "user.contactJoin"
            case .delete:
                "user.delete"
            case .legalholdDisable:
                "user.legalholdDisable"
            case .legalholdEnable:
                "user.legalholdEnable"
            case .legalholdRequest:
                "user.legalholdRequest"
            case .propertiesSet:
                "user.propertiesSet"
            case .propertiesDelete:
                "user.propertiesDelete"
            case .pushRemove:
                "user.pushRemove"
            case .update:
                "user.update"
            }
        case let .team(event):
            switch event {
            case .delete:
                "team.delete"
            case .memberLeave:
                "team.memberLeave"
            case .memberUpdate:
                "team.memberUpdate"
            case .create:
                "team.create"
            }
        case let .unknown(eventType):
            "unknown.\(eventType)"
        }
    }

}
