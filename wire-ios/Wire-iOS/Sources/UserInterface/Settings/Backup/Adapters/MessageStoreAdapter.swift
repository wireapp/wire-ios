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

    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalBackupableMessageCount()
    }

    func fetchAllMessageIDs() async throws -> [MessageEntity.MessageID] {
        try await messageLocalStore.fetchAllBackupableMessageIDs().map(\.uuidString)
    }

    func fetchAllMessages() async throws -> [MessageEntity] {
        let messages = try await messageLocalStore.fetchAllBackupableMessages()
        return await messageLocalStore.context.perform {
            messages.compactMap { message in
                if let message = MessageEntity(message) { message } else { nil }
            }
        }
    }

    func addMessage( // TODO: should it accept MessageEntity?
        id: MessageEntity.MessageID,
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

    // MARK: -

    struct MessageEntity: MessageEntityProtocol {

        let id: MessageID
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
            guard
                let message = clientMessage.underlyingMessage,
                message.isInitialized,
                let messageContent = message.content.flatMap(MessageContent.init)
            else { return nil }

            self.init(clientMessage, content: messageContent)
        }

        init?(_ assetClientMessage: ZMAssetClientMessage) {

            guard let asset = assetClientMessage.underlyingMessage?.assetData else { return nil }

            let size: UInt64
            let name: String?
            let encryption: MessageContent.AssetContent.EncryptionAlgorithm?
            let metadata: MessageContent.AssetContent.Metadata?

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

            if let imageAssetData = assetClientMessage.underlyingMessage?.imageAssetData {
                metadata = .image(
                    width: imageAssetData.hasWidth ? imageAssetData.width : 0, // TODO: take originalWidth instead?
                    height: imageAssetData.hasHeight ? imageAssetData.height : 0,
                    tag: imageAssetData.hasTag ? imageAssetData.tag : nil
                )
//            } else if let v = assetClientMessage.underlyingMessage?.audio {
//                //
            } else {
                fatalError()
            }

//            if assetClientMessage.isImage, let genericMessage = assetClientMessage.underlyingMessage, let imageMessageData = assetClientMessage.imageMessageData {
//
//
//                metadata = .image(
//                    width: Int32(imageMessageData.originalSize.width),
//                    height: Int32(imageMessageData.originalSize.height),
//                    tag: .none // TODO: ?
//                )
//            } else if assetClientMessage.isVideo {
//                fatalError("TODO")
////                metadata = .video(width: <#T##Int32?#>, height: <#T##Int32?#>, duration: <#T##UInt64?#>)
//            } else if assetClientMessage.isAudio {
//                fatalError("TODO")
//            } else if assetClientMessage.isFile {
//                fatalError("TODO")
//            } else {
//                metadata = .none
//            }

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
                let id = message.nonce,
                let senderUserID = message.senderUser?.qualifiedID,
                let creationDate = message.serverTimestamp,
                let conversationID = message.conversation?.qualifiedID
            else {
                // TODO: Ideally the fetch request for exporting messages wouldn't fetch messages which can't be exported.
                return nil
            }

            self.id = id.uuidString
            self.conversationID = QualifiedID(conversationID)
            self.senderUserID = QualifiedID(senderUserID)
            self.senderClientID = message.senderClientID
            self.creationDate = creationDate
            self.content = content
        }

    }

}

extension MessageContent {

    fileprivate init?(_ content: GenericMessage.OneOf_Content) {
        switch content {

        case let .text(text):
            self = .text(text.content)

        case let .image(ImageAsset):
            return nil

        case let .knock(Knock):
            return nil
        case let .lastRead(LastRead):
            return nil
        case let .cleared(Cleared):
            return nil
        case let .external(External):
            return nil
        case let .clientAction(ClientAction):
            return nil
        case let .calling(Calling):
            return nil
        case let .asset(Asset):
            return nil
        case let .hidden(MessageHide):
            return nil

        case let .location(location):
            self = .location(
                longitude: location.longitude,
                latitude: location.latitude,
                name: location.hasName ? location.name : nil,
                zoom: location.hasZoom ? location.zoom : nil
            )

        case let .deleted(MessageDelete):
            return nil

        case let .edited(messageEdit):
            switch messageEdit.content {
            case let .text(text):
                self = .text(text.content)
            case let .composite(composite):
                return nil
            case .none:
                return nil
            }

        case let .confirmation(Confirmation):
            return nil
        case let .reaction(Reaction):
            return nil

        case let .ephemeral(ephemeral):
            switch ephemeral.content {

            case .text(let text):
                self = .text(text.content)

            case .image(let imageAsset):
                return nil

            case .knock(let knock):
                return nil

            case .asset(let asset):
                return nil

            case .location(let location):
                self = .location(
                    longitude: location.longitude,
                    latitude: location.latitude,
                    name: location.hasName ? location.name : nil,
                    zoom: location.hasZoom ? location.zoom : nil
                )

            case .none:
                return nil

            }

        case let .availability(Availability):
            return nil
        case let .composite(Composite):
            return nil
        case let .buttonAction(ButtonAction):
            return nil
        case let .buttonActionConfirmation(ButtonActionConfirmation):
            return nil
        case let .dataTransfer(DataTransfer):
            return nil
        case let .inCallEmoji(InCallEmoji):
            return nil
        case let .inCallHandRaise(InCallHandRaise):
            return nil

        }
    }

}
