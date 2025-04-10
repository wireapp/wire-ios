//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

todo:
feature flag
swift 6 package
extract WireDomainPackage oder neue struktur

import Foundation
import WireDataModel
import WireDomainPackage

struct CreateBackupZMMessageAdapter: CreateBackupMessageEntityProtocol {

    typealias QualifiedID = WireDomainPackage.QualifiedID

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        ZMMessage.fetchRequest()
    }

    let id: String
    let conversationID: QualifiedID
    let senderUserID: QualifiedID
    let senderClientID: String
    let creationDate: Date
    let content: CreateBackupMessageContent

    init?(_ record: any NSFetchRequestResult) {
        if !(record is ZMSystemMessage) {
            print("record as? ZMMessage", record as? ZMMessage)
            if let message = record as? ZMMessage {
                print("message.nonce?.transportString()", message.nonce?.transportString())
                if let id = message.nonce?.transportString() {
                    print("message.senderUser?.qualifiedID", message.senderUser?.qualifiedID)
                    if let senderUserID = message.senderUser?.qualifiedID {
                        print("message.senderClientID", message.senderClientID)
                        print("message.serverTimestamp", message.serverTimestamp)
                        if let creationDate = message.serverTimestamp {
                            print("message.conversation?.qualifiedID", message.conversation?.qualifiedID)
                            if let conversationID = message.conversation?.qualifiedID {
                                print("message.content", message.content)
                                if let content = message.content {
                                    print("message.isObfuscated", message.isObfuscated)
                                }
                            }
                        }
                    }
                }
            }
        }

        guard
            let message = record as? ZMMessage,
            let id = message.nonce?.transportString(),
            let senderUserID = message.senderUser?.qualifiedID,
            // let senderClientID = message.senderClientID,
            let creationDate = message.serverTimestamp,
            let conversationID = message.conversation?.qualifiedID,
            let content = message.content,
            !message.isObfuscated
        else {
            return nil // TODO: prevent silent failure?
        }

        self.id = id
        self.conversationID = QualifiedID(conversationID)
        self.senderUserID = QualifiedID(senderUserID)
        self.senderClientID = message.senderClientID ?? "" // TODO: should be optional
        self.creationDate = creationDate
        self.content = content
    }

}

extension ZMMessage {

    fileprivate var content: CreateBackupMessageContent? {

        if isText, let messageText = textMessageData?.messageText {
            .text(messageText)

        } else if isLocation, let locationMessageData {
            .location(
                longitude: locationMessageData.longitude,
                latitude: locationMessageData.latitude,
                name: locationMessageData.name,
                zoom: locationMessageData.zoomLevel
            )

//        } else if isImage {
//            fatalError()
//
//        } else if isVideo {
//            fatalError()
//
//        } else if isAudio {
//            fatalError()

        } else if isFile, let fileMessageData {
            fatalError()
            /*
            .asset(
                mimeType: fileMessageData.mimeType ?? "", // TODO: empty string?
                size: fileMessageData.size,
                name: fileMessageData.filename,
                otrKey: <#T##Data#>,
                sha256: <#T##Data#>
            )
             */

        } else {
            nil

        }
    }
}
