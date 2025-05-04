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
import WireProtos

struct MessageStoreAdapter: MessageStoreProtocol {
    typealias QualifiedID = WireFoundation.QualifiedID

    let messageLocalStore: any MessageLocalStoreProtocol // TODO: create and only inject the context
    let userLocalStore: any UserLocalStoreProtocol

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalBackupableMessageCount()
    }

    func fetchAllMessageIDs() async throws -> [BackupMessageModel.ID] {
        try await messageLocalStore.fetchAllBackupableMessageIDs().map(\.uuidString)
    }

    func fetchAllMessages() async throws -> [BackupMessageModel] {
        let messages = try await messageLocalStore.fetchAllBackupableMessages()
        return await messageLocalStore.context.perform {
            messages.compactMap { message in
                if let message = BackupMessageModel(message) { message } else { nil }
            }
        }
    }

    func addMessage( // TODO: should it accept MessageEntity?
        id: BackupMessageModel.ID,
        conversationID: QualifiedID,
        senderUserID: QualifiedID,
        senderClientID: String?,
        creationDate: Date,
        content: WireBackup.MessageContent
    ) async throws {

        let conversation = await messageLocalStore.context.perform {
            ZMConversation.fetch(
                with: conversationID.id,
                domain: conversationID.domain,
                in: messageLocalStore.context
            )
        }
        guard let conversation, let nonce = UUID(transportString: id) else { return }
        let sender = await userLocalStore.fetchOrCreateUser(id: senderUserID.id, domain: senderUserID.domain)

        switch content {

        case .text(let textContent):
            let (clientMessage, isCreated) = try await messageLocalStore.fetchOrCreateClientMessage(
                id: id,
                conversation: conversation,
                sender: (id: senderUserID.id, domain: senderUserID.domain, clientID: senderClientID),
                date: creationDate
            )
            guard isCreated else { return }
            let textMessage = Text(content: textContent.text)
            let genericMessage = GenericMessage(content: textMessage, nonce: nonce)
            try await messageLocalStore.context.perform {
                try clientMessage.setUnderlyingMessage(genericMessage)
                clientMessage.sender = sender
                clientMessage.visibleInConversation = conversation
                clientMessage.markAsSent()
            }

        case .location(let locationContent):
            let (clientMessage, isCreated) = try await messageLocalStore.fetchOrCreateClientMessage(
                id: id,
                conversation: conversation,
                sender: (id: senderUserID.id, domain: senderUserID.domain, clientID: senderClientID),
                date: creationDate
            )
            guard isCreated else { return }
            let locationContent = Location.with { location in
                if let name = locationContent.name {
                    location.name = name
                }
                location.latitude = locationContent.latitude
                location.longitude = locationContent.longitude
                location.zoom = locationContent.zoom ?? 0
            }
            let genericMessage = GenericMessage(content: locationContent, nonce: nonce)
            try await messageLocalStore.context.perform {
                try clientMessage.setUnderlyingMessage(genericMessage)
                clientMessage.sender = sender
                clientMessage.visibleInConversation = conversation
            }

        case .asset(let assetContent):
            let (assetClientMessage, isCreated) = try await messageLocalStore.fetchOrCreateAssetClientMessage(
                id: id,
                conversation: conversation,
                sender: (id: senderUserID.id, domain: senderUserID.domain, clientID: senderClientID),
                date: creationDate
            )
            guard isCreated else { return }
            let genericMessage: GenericMessage
            switch assetContent.metadata {
            case .image(let imageData):
                let asset = Asset(
                    imageSize: CGSize(width: Double(imageData.width), height: Double(imageData.height)),
                    mimeType: assetContent.mimeType,
                    size: assetContent.size
                )
                // TODO: moc.zm_fileAssetCache.storeOriginalImage(data: imageData, for: message) ?
                /*
                guard !message.isRestricted else {
                    throw AppendMessageError.fileSharingIsRestricted
                }
                 */
                genericMessage = GenericMessage(content: asset, nonce: nonce)
                // try mergeWithExistingData(message: genericMessage) // TODO: ?
            case .video(let videoData):
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "video"
                        original.video = WireProtos.Asset.VideoMetaData.with { video in
                            video.durationInMillis = videoData.duration.map { $0 / 1000 } ?? 0 // TODO: compare with backup creation
                            video.width = videoData.width ?? 0
                            video.height = videoData.height ?? 0
                        }
                    }
                }
                genericMessage = GenericMessage(content: asset, nonce: nonce)
                // TODO: contributionType = .videoMessage ?
                // TODO: moc.zm_fileAssetCache.storeOriginalFile
            case .audio(let audioData):
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "audio"
                        original.audio = Asset.AudioMetaData.with { audio in
                            let loudnessArray = audioData.normalization?.map { Float($0 / 255) }
                            audio.durationInMillis = audioData.duration.map { $0 * 1000 } ?? 0
                            // audio.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as Data
                            // TODO: fix
                        }
                    }
                }
                genericMessage = GenericMessage(content: asset, nonce: nonce)
                // TODO: see video
            case .generic(let data):
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "file"
                    }
                }
                genericMessage = GenericMessage(content: asset, nonce: nonce)
            case .none:
                return // TODO: ??
            }
            try await messageLocalStore.context.perform {
                try assetClientMessage.setUnderlyingMessage(genericMessage)
                assetClientMessage.sender = sender
                assetClientMessage.visibleInConversation = conversation
            }
        }
    }

}

// MARK: -

extension BackupMessageModel {

    init?(_ message: ZMMessage) {
        switch message {
        case let message as ZMClientMessage where !message.isObfuscated:
            guard let genericMessage = message.underlyingMessage, genericMessage.isInitialized else { return nil }
            self.init(message, genericMessage: genericMessage)
        case let message as ZMAssetClientMessage where !message.isObfuscated:
            guard let genericMessage = message.underlyingMessage, genericMessage.isInitialized else { return nil }
            self.init(message, genericMessage: genericMessage)
        default:
            return nil
        }
    }

    init?(_ message: ZMMessage, genericMessage: GenericMessage) {

        guard
            let id = message.nonce,
            let senderUserID = message.senderUser?.qualifiedID,
            let creationDate = message.serverTimestamp,
            let conversationID = message.conversation?.qualifiedID,
            let content = genericMessage.content.flatMap(MessageContent.init)
        else {
            // TODO: Ideally the fetch request for exporting messages wouldn't fetch messages which can't be exported.
            return nil
        }

        self.init(
            id: id.uuidString,
            conversationID: QualifiedID(conversationID),
            senderUserID: QualifiedID(senderUserID),
            senderClientID: message.senderClientID,
            creationDate: creationDate,
            content: content
        )

    }

}
