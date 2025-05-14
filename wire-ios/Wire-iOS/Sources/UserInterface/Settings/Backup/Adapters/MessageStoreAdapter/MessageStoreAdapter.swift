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

import CoreData
import Foundation
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation
import WireProtos
import WireAPI

struct MessageStoreAdapter<MessageLocalStore>: MessageStoreProtocol, @unchecked Sendable
    where MessageLocalStore: MessageLocalStoreProtocol {
    typealias QualifiedID = WireFoundation.QualifiedID

    /// The context to call `perform(schedule:_:)` on if needed.
    private let context: NSManagedObjectContext
    private let messageLocalStore: MessageLocalStore

    private let processor: any ConversationProtobufMessageProcessorProtocol

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalMessageCountForBackup()
    }

    func fetchAllMessageIDs() async throws -> [BackupMessageModel.ID] {
        try await messageLocalStore.fetchAllMessageIDsForBackup().map(\.uuidString)
    }

    func fetchAllMessages() async throws -> [BackupMessageModel] {
        let messages = try await messageLocalStore.fetchAllMessagesForBackup()
        return await context.perform {
            messages.compactMap { message in
                if let message = BackupMessageModel(message) { message } else { nil }
            }
        }
    }

    func addMessage(_ message: BackupMessageModel) async throws {

        let conversationID = message.conversationID
        let conversation = await context.perform {
            ZMConversation.fetch(with: conversationID.id, domain: conversationID.domain, in: context)
        }
        guard let conversation, let nonce = UUID(transportString: message.id) else { return }

        let senderUserID = message.senderUserID
        let userLocalStore = UserLocalStore(context: context, messageLocalStore: messageLocalStore)

        switch message.content {

        case let .text(textContent):

            let textMessage = Text(content: textContent.text)
            let genericMessage = GenericMessage(content: textMessage, nonce: nonce)

            try await processor.processProtobufMessage(
                genericMessage,
                content: genericMessage.content!,
                conversation: conversation,
                conversationID: WireAPI.QualifiedID(conversationID),
                senderID: WireAPI.QualifiedID(senderUserID),
                senderClientID: message.senderClientID,
                date: message.creationDate,
                eventMessage: "backup.import"
            )

        default:
            return ()

            /*
        case let .location(locationContent):
            let (clientMessage, isCreated) = try await messageLocalStore.fetchOrCreateClientMessage(
                id: message.id,
                conversation: conversation,
                sender: (id: senderUserID.id, domain: senderUserID.domain, clientID: message.senderClientID),
                date: message.creationDate
            )
            guard isCreated else { return } // don't overwrite existing messages
            let locationContent = Location.with { location in
                if let name = locationContent.name {
                    location.name = name
                }
                location.latitude = locationContent.latitude
                location.longitude = locationContent.longitude
                location.zoom = locationContent.zoom ?? 0
            }
            let genericMessage = GenericMessage(content: locationContent, nonce: nonce)
            try await context.perform {
                try clientMessage.setUnderlyingMessage(genericMessage)
                clientMessage.sender = sender
                clientMessage.visibleInConversation = conversation
            }

        case let .asset(assetContent):
            let (assetClientMessage, isCreated) = try await messageLocalStore.fetchOrCreateAssetClientMessage(
                id: message.id,
                conversation: conversation,
                sender: (id: senderUserID.id, domain: senderUserID.domain, clientID: message.senderClientID),
                date: message.creationDate
            )
            guard isCreated else { return } // don't overwrite existing messages

            let genericMessage: GenericMessage
            switch assetContent.metadata {
            case let .image(imageData):
                let asset = Asset(
                    imageSize: CGSize(width: Double(imageData.width), height: Double(imageData.height)),
                    mimeType: assetContent.mimeType,
                    size: assetContent.size
                )
                // TODO: moc.zm_fileAssetCache.storeOriginalImage(data: imageData, for: message) ?
                // guard !message.isRestricted else {
                //    throw AppendMessageError.fileSharingIsRestricted
                // }
                //
                genericMessage = GenericMessage(content: asset, nonce: nonce)
            // try mergeWithExistingData(message: genericMessage) // TODO: ?
            case let .video(videoData):
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
            case let .audio(audioData):
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
            case let .generic(data):
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
            try await context.perform {
                try assetClientMessage.setUnderlyingMessage(genericMessage)
                assetClientMessage.sender = sender
                assetClientMessage.visibleInConversation = conversation
            }
             */
        }
    }

}

extension MessageStoreAdapter where MessageLocalStore == WireDomain.MessageLocalStore {

    init(context: NSManagedObjectContext) {
        self.context = context
        self.messageLocalStore = MessageLocalStore(context: context)

        processor = TEMP_ConversationProtobufMessageProcessor(
            context: context,
            mlsService: context.performAndWait { context.mlsService },
            userDefaults: .standard
        )
    }

}
