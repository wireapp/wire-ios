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

import Foundation
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation

struct MessageStoreAdapter: MessageStoreProtocol {

    let messageLocalStore: any MessageLocalStoreProtocol

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalBackupableMessageCount()
    }

    func fetchAllMessages() async throws -> [MessageEntity] {
        let messages = try await messageLocalStore.fetchAllBackupableMessages()
        return await messageLocalStore.context.perform {
            messages.compactMap { message in
                if let message = MessageEntity(message) { message } else { nil }
            }
        }
    }

    // MARK: -

    struct MessageEntity: MessageEntityProtocol {
        typealias QualifiedID = WireFoundation.QualifiedID

        let id: String
        let conversationID: QualifiedID
        let senderUserID: QualifiedID
        let senderClientID: String?
        let creationDate: Date
        let content: WireBackup.MessageContent

        init?(_ message: ZMMessage) {
            if let clientMessage = message as? ZMClientMessage, !clientMessage.isObfuscated {
                self.init(clientMessage)
            } else if let assetClientMessage = message as? ZMAssetClientMessage, !assetClientMessage.isObfuscated {
                self.init(assetClientMessage)
            } else {
                return nil
            }
        }

        init?(_ clientMessage: ZMClientMessage) {

            if let messageText = clientMessage.textMessageData?.messageText {
                self.init(clientMessage, content: .text(messageText))

            } else if let locationMessageData = clientMessage.locationMessageData {
                self.init(
                    clientMessage,
                    content: .location(
                        longitude: locationMessageData.longitude,
                        latitude: locationMessageData.latitude,
                        name: locationMessageData.name,
                        zoom: locationMessageData.zoomLevel
                    )
                )

            } else {
                return nil
            }

        }

        init?(_ assetClientMessage: ZMAssetClientMessage) {

            guard let asset = assetClientMessage.underlyingMessage?.assetData else { return nil }

            let size: UInt64
            let name: String?
            let encryption: MessageContent.AssetContent.EncryptionAlgorithm?
            let metadata: MessageContent.AssetContent.Metadata? = nil

            if asset.hasOriginal, asset.uploaded.hasAssetID {
                size = asset.original.size
                name = asset.original.name
            } else if asset.hasPreview, asset.uploaded.hasAssetID {
                size = asset.original.size
                name = nil
            } else {
                return nil
            }

            switch (asset.uploaded.hasEncryption, asset.uploaded.encryption) {
            case (false, _):
                encryption = .none
            case (true, .aesCbc):
                encryption = .aesCBC
            case (true, .aesGcm):
                encryption = .aesGCM
            }

            self.init(
                assetClientMessage,
                content: .asset(
                    mimeType: asset.original.hasMimeType ? asset.original.mimeType : "application/octet-stream",
                    size: size,
                    name: name,
                    otrKey: asset.uploaded.otrKey, // TODO: uploaded?
                    sha256: asset.uploaded.sha256,
                    assetID: asset.uploaded.assetID,
                    assetToken: asset.uploaded.hasAssetToken ? asset.uploaded.assetToken : nil,
                    assetDomain: asset.uploaded.hasAssetDomain ? asset.uploaded.assetDomain : nil,
                    encryption: encryption,
                    metadata: metadata
                )
            )

        }

        init?(_ message: ZMMessage, content: MessageContent) {

            guard
                let id = message.nonce?.transportString(),
                let senderUserID = message.senderUser?.qualifiedID,
                let creationDate = message.serverTimestamp,
                let conversationID = message.conversation?.qualifiedID
            else {
                // TODO: Ideally the fetch request for exporting messages wouldn't fetch messages which can't be exported.
                return nil
            }

            self.id = id
            self.conversationID = QualifiedID(conversationID)
            self.senderUserID = QualifiedID(senderUserID)
            self.senderClientID = message.senderClientID
            self.creationDate = creationDate
            self.content = content
        }

    }

}
