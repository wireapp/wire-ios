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
import GenericMessageProtocol

// MARK: - GenericMessage

public extension GenericMessage {

    /// Deserializes a `GenericMessage` instance from the data contained in the provided base64 encoded string. If
    /// `true` is passed for the `validate` argument, the initializer fails if `validateFields()` returns false.

    init?(
        from base64String: String,
        validate: Bool
    ) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        self.init(from: data, validate: validate)
    }

    /// Deserializes a `GenericMessage` instance from the provided data. If `true` is passed for the `validate`
    /// argument, the initializer fails if `validateFields()` returns false.

    init?(
        from data: Data,
        validate: Bool
    ) {
        let genericMessage = GenericMessage.with { message in
            try? message.merge(serializedData: data)
        }
        guard !validate || genericMessage.validateFields() else { return nil }
        self = genericMessage
    }

    init(
        content: EphemeralMessageCapable,
        nonce: UUID = UUID(),
        expiresAfter timeout: MessageDestructionTimeoutValue? = nil
    ) {
        self.init(content: content, nonce: nonce, expiresAfterTimeInterval: timeout?.rawValue)
    }

    init(
        content: EphemeralMessageCapable,
        nonce: UUID = UUID(),
        expiresAfterTimeInterval timeout: TimeInterval? = nil
    ) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            let messageContent: MessageCapable = if let timeout, timeout > 0 {
                Ephemeral(content: content, expiresAfter: timeout)
            } else {
                content
            }
            messageContent.setContent(on: &$0)
        }
    }

    init(content: MessageCapable, nonce: UUID = UUID()) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            let messageContent = content
            messageContent.setContent(on: &$0)
        }
    }

    init(clientAction action: ClientAction, nonce: UUID = UUID()) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            $0.clientAction = action
        }
    }
}

public extension GenericMessage {
    var messageData: MessageCapable? {
        guard let content else { return nil }
        switch content {
        case let .text(data):
            return data
        case let .confirmation(data):
            return data
        case let .reaction(data):
            return data
        case let .asset(data):
            return data
        case let .multipart(data):
            return data
        case let .ephemeral(data):
            return data.messageData
        case let .clientAction(data):
            return data
        case let .cleared(data):
            return data
        case let .lastRead(data):
            return data
        case let .knock(data):
            return data
        case let .external(data):
            return data
        case let .availability(data):
            return data
        case let .edited(data):
            return data
        case let .deleted(data):
            return data
        case let .calling(data):
            return data
        case let .inCallEmoji(data):
            return data
        case let .hidden(data):
            return data
        case let .location(data):
            return data
        case let .image(data):
            return data
        case let .composite(data):
            return data
        case let .buttonAction(data):
            return data
        case let .buttonActionConfirmation(data):
            return data
        case let .dataTransfer(data):
            return data
        case let .inCallHandRaise(data):
            return data
        }
    }

    internal var locationData: Location? {
        guard let content else { return nil }
        switch content {
        case let .location(data):
            return data
        case let .ephemeral(data):
            switch data.content {
            case let .location(data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var compositeData: Composite? {
        switch content {
        case let .composite(data):
            return data
        case let .edited(messageEdit):
            if case let .composite(composite)? = messageEdit.content {
                return composite
            }
        default:
            break
        }
        return nil
    }

    var imageAssetData: ImageAsset? {
        guard let content else { return nil }
        switch content {
        case let .image(data):
            return data
        case let .ephemeral(data):
            switch data.content {
            case let .image(data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var assetData: GenericMessageProtocol.Asset? {
        guard let content else { return nil }
        switch content {
        case let .asset(data):
            return data
        case let .ephemeral(data):
            switch data.content {
            case let .asset(data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var knockData: Knock? {
        guard let content else { return nil }
        switch content {
        case let .knock(data):
            return data
        case let .ephemeral(data):
            switch data.content {
            case let .knock(data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var textData: Text? {
        guard let content else { return nil }
        switch content {
        case let .text(data):
            return data
        case let .edited(messageEdit):
            switch messageEdit.content {
            case .text(let data):
                return data
            case .multipart(let data) where data.hasText:
                return data.text
            default:
                return nil
            }
        case let .ephemeral(ephemeral):
            if case let .text(data)? = ephemeral.content {
                return data
            }
        case let .multipart(data):
            return data.text
        default:
            return nil
        }
        return nil
    }
}

public extension Text {
    func isMentioningSelf(_ selfUser: ZMUser) -> Bool {
        mentions.any { $0.userID.uppercased() == selfUser.remoteIdentifier.uuidString }
    }

    func isQuotingSelf(_ quotedMessage: ZMOTRMessage?) -> Bool {
        quotedMessage?.sender?.isSelfUser ?? false
    }
}

extension GenericMessage {
    var v3_isImage: Bool {
        assetData?.original.hasRasterImage ?? false
    }

    var v3_uploadedAssetId: String? {
        guard
            let assetData,
            case .uploaded? = assetData.status
        else {
            return nil
        }
        return assetData.uploaded.assetID
    }

    public var previewAssetId: String? {
        guard
            let assetData,
            assetData.hasPreview,
            assetData.preview.hasRemote,
            assetData.preview.remote.hasAssetID
        else {
            return nil
        }
        return assetData.preview.remote.assetID
    }
}

public extension GenericMessage {
    var linkPreviews: [LinkPreview] {
        guard let content else { return [] }
        switch content {
        case .text:
            return text.linkPreview.compactMap(\.self)
        case .edited:
            return edited.text.linkPreview.compactMap(\.self)
        case let .ephemeral(ephemeral):
            if case .text? = ephemeral.content {
                return ephemeral.text.linkPreview.compactMap(\.self)
            } else {
                return []
            }
        default:
            return []
        }
    }
}

// MARK: - Ephemeral

public extension Ephemeral {
    init(content: EphemeralMessageCapable, expiresAfter timeout: TimeInterval) {
        self = Ephemeral.with {
            $0.expireAfterMillis = Int64(timeout * 1000)
            content.setEphemeralContent(on: &$0)
        }
    }

    var messageData: MessageCapable? {
        guard let content else { return nil }
        switch content {
        case let .text(data):
            return data
        case let .asset(data):
            return data
        case let .knock(data):
            return data
        case let .location(data):
            return data
        case let .image(data):
            return data
        }
    }
}

public extension Proteus_QualifiedUserId {
    init(with uuid: UUID, domain: String) {
        self = Proteus_QualifiedUserId.with {
            $0.id = uuid.transportString()
            $0.domain = domain
        }
    }
}

// MARK: - ClientEntry

public extension Proteus_ClientEntry {
    init(withClient client: UserClient, data: Data) {
        self = Proteus_ClientEntry.with {
            $0.client = client.clientId
            $0.text = data
        }
    }

    init(withClientId clientId: Proteus_ClientId, data: Data) {
        self = Proteus_ClientEntry.with {
            $0.client = clientId
            $0.text = data
        }
    }
}

// MARK: - QualifiedUserEntry

public extension Proteus_QualifiedUserEntry {
    init(withDomain domain: String, userEntries: [Proteus_UserEntry]) {
        self = Proteus_QualifiedUserEntry.with {
            $0.domain = domain
            $0.entries = userEntries
        }
    }
}

// MARK: - UserEntry

public extension Proteus_UserEntry {
    init(withUser user: ZMUser, clientEntries: [Proteus_ClientEntry]) {
        self = Proteus_UserEntry.with {
            $0.user = user.userId
            $0.clients = clientEntries
        }
    }

    init(withProteusUserId id: Proteus_UserId, clientEntries: [Proteus_ClientEntry]) {
        self = Proteus_UserEntry.with {
            $0.user = id
            $0.clients = clientEntries
        }
    }
}

// MARK: - QualifiedNewOtrMessage

public extension Proteus_QualifiedNewOtrMessage {

    // TODO: [WPB-11206] remove this
    init(
        withSender sender: UserClient,
        nativePush: Bool,
        recipients: [Proteus_QualifiedUserEntry],
        missingClientsStrategy: MissingClientsStrategy,
        blob: Data? = nil
    ) {

        self = Proteus_QualifiedNewOtrMessage.with {
            $0.nativePush = nativePush
            $0.sender = sender.clientId
            $0.recipients = recipients

            if let blob {
                $0.blob = blob
            }

            switch missingClientsStrategy {
            case .doNotIgnoreAnyMissingClient:
                $0.clientMismatchStrategy = .reportAll(.init())
            case .ignoreAllMissingClients:
                $0.clientMismatchStrategy = .ignoreAll(.init())
            case let .ignoreAllMissingClientsNotFromUsers(userIds: userIds):
                $0.clientMismatchStrategy = .reportOnly(.with {
                    $0.userIds = userIds.compactMap {
                        Proteus_QualifiedUserId(with: $0.uuid, domain: $0.domain)
                    }
                })
            }
        }
    }

    init(
        withSenderId userId: UInt64,
        nativePush: Bool,
        recipients: [Proteus_QualifiedUserEntry],
        missingClientsStrategy: MissingClientsStrategy,
        blob: Data? = nil
    ) {

        self = Proteus_QualifiedNewOtrMessage.with {
            $0.nativePush = nativePush
            $0.sender = Proteus_ClientId.with { $0.client = userId }
            $0.recipients = recipients

            if let blob {
                $0.blob = blob
            }

            switch missingClientsStrategy {
            case .doNotIgnoreAnyMissingClient:
                $0.clientMismatchStrategy = .reportAll(.init())
            case .ignoreAllMissingClients:
                $0.clientMismatchStrategy = .ignoreAll(.init())
            case let .ignoreAllMissingClientsNotFromUsers(userIds: userIds):
                $0.clientMismatchStrategy = .reportOnly(.with {
                    $0.userIds = userIds.compactMap {
                        Proteus_QualifiedUserId(with: $0.uuid, domain: $0.domain)
                    }
                })
            }
        }
    }
}

// MARK: - NewOtrMessage

public extension Proteus_NewOtrMessage {
    init(
        withSenderId senderClientId: UInt64,
        nativePush: Bool,
        recipients: [Proteus_UserEntry],
        missingClientsStrategy: MissingClientsStrategy,
        blob: Data? = nil
    ) {
        self = Proteus_NewOtrMessage.with {
            $0.nativePush = nativePush
            $0.sender = Proteus_ClientId.with { $0.client = senderClientId }
            $0.recipients = recipients

            if blob != nil {
                $0.blob = blob!
            }

            switch missingClientsStrategy {
            case let .ignoreAllMissingClientsNotFromUsers(userIds: userIds):
                $0.reportMissing = userIds.map { qualifiedID in
                    Proteus_UserId.with { $0.uuid = qualifiedID.uuid.uuidData }
                }
            case .ignoreAllMissingClients, .doNotIgnoreAnyMissingClient:
                break
            }
        }
    }
}

// MARK: - ButtonAction

extension ButtonAction {
    init(buttonId: String, referenceMessageId: UUID) {
        self = ButtonAction.with {
            $0.buttonID = buttonId
            $0.referenceMessageID = referenceMessageId.transportString()
        }
    }
}

// MARK: - Location

extension Location {
    init(latitude: Float, longitude: Float) {
        self = GenericMessageProtocol.Location.with {
            $0.latitude = latitude
            $0.longitude = longitude
        }
    }
}

// MARK: - Multipart

public extension Multipart {
    init(
        text: Text,
        attachments: [Attachment]
    ) {
        self = Multipart.with {
            $0.text = text
            $0.attachments = attachments
        }
    }
}

// MARK: - Text

public extension Text {
    init(
        content: String,
        mentions: [Mention] = [],
        linkPreviews: [LinkMetadata] = [],
        replyingTo: ZMOTRMessage? = nil
    ) {
        self = Text.with {
            $0.content = content
            $0.mentions = mentions.compactMap { GenericMessageProtocol.Mention.createMention($0) }
            $0.linkPreview = linkPreviews.map { GenericMessageProtocol.LinkPreview($0) }

            if let quotedMessage = replyingTo,
               let quotedMessageNonce = quotedMessage.nonce,
               let quotedMessageHash = quotedMessage.hashOfContent {
                $0.quote = Quote.with {
                    $0.quotedMessageID = quotedMessageNonce.transportString()
                    $0.quotedMessageSha256 = quotedMessageHash
                }
            }
        }
    }

    func applyEdit(from text: Text) -> Text {
        var updatedText = text
        // Transfer read receipt expectation
        updatedText.expectsReadConfirmation = expectsReadConfirmation

        // We always keep the quote from the original message
        if hasQuote {
            updatedText.quote = quote
        } else {
            updatedText.clearQuote()
        }
        return updatedText
    }

    func updateLinkPreview(from text: Text) -> Text {
        guard !text.linkPreview.isEmpty else { return self }
        do {
            let data = try serializedData()
            var updatedText = try Text(serializedBytes: data)
            updatedText.linkPreview = text.linkPreview
            return updatedText
        } catch {
            return self
        }
    }
}

extension GenericMessageProtocol.InCallHandRaise {
    init(handUp: Bool) {

        self = InCallHandRaise.with {
            $0.isHandUp = handUp
        }
    }
}

// MARK: - Reaction

extension GenericMessageProtocol.Reaction {

    public static func createReaction(
        emojis: Set<String>,
        messageID: UUID
    ) -> GenericMessageProtocol.Reaction {
        let transportString = emojis
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: ",")

        return GenericMessageProtocol.Reaction.with {
            $0.emoji = transportString
            $0.messageID = messageID.transportString()
        }
    }

    func toReactionSet() -> Set<String> {
        guard !emoji.isEmpty else { return [] }

        let result = emoji
            .components(separatedBy: ",")
            .map { String($0) }

        return Set(result)
    }

}

public enum ProtosReactionFactory {

    public static func createReaction(
        emojis: Set<String>,
        messageID: UUID
    ) -> GenericMessageProtocol.Reaction {
        GenericMessageProtocol.Reaction.createReaction(
            emojis: emojis,
            messageID: messageID
        )
    }

}

// MARK: - LastRead

public extension LastRead {
    init(conversationID: QualifiedID, lastReadTimestamp: Date) {
        self = LastRead.with {
            $0.conversationID = conversationID.uuid.transportString()
            $0.lastReadTimestamp = Int64(lastReadTimestamp.timeIntervalSince1970 * 1000)
            $0.qualifiedConversationID = GenericMessageProtocol.QualifiedConversationId.with {
                $0.id = conversationID.uuid.transportString()
                $0.domain = conversationID.domain
            }
        }
    }
}

// MARK: - Calling

public extension Calling {
    init(content: String, conversationId: QualifiedID) {
        self = Calling.with {
            $0.content = content
            $0.qualifiedConversationID = QualifiedConversationId.with {
                $0.domain = conversationId.domain
                $0.id = conversationId.uuid.transportString()
            }
        }
    }
}

// MARK: - MessageEdit

public extension GenericMessageProtocol.MessageEdit {
    init(replacingMessageID: UUID, text: Text) {
        self = MessageEdit.with {
            $0.replacingMessageID = replacingMessageID.transportString()
            $0.text = text
        }
    }
    
    init(replacingMessageID: UUID, multipart: Multipart) {
        self = MessageEdit.with {
            $0.replacingMessageID = replacingMessageID.transportString()
            $0.multipart = multipart
        }
    }
}

// MARK: - Cleared

public extension Cleared {
    init(timestamp: Date, conversationID: UUID) {
        self = Cleared.with {
            $0.clearedTimestamp = Int64(timestamp.timeIntervalSince1970 * 1000)
            $0.conversationID = conversationID.transportString()
        }
    }
}

// MARK: - MessageHide

public extension MessageHide {
    init(conversationId: UUID, messageId: UUID) {
        self = MessageHide.with {
            $0.conversationID = conversationId.transportString()
            $0.messageID = messageId.transportString()
        }
    }
}

// MARK: - MessageDelete

public extension MessageDelete {
    init(messageId: UUID) {
        self = MessageDelete.with {
            $0.messageID = messageId.transportString()
        }
    }
}

// MARK: - Confirmation

public extension GenericMessageProtocol.Confirmation {
    init?(messageIds: [UUID], type: Confirmation.TypeEnum = .delivered) {
        guard let firstMessageID = messageIds.first else {
            return nil
        }
        let moreMessageIds = Array(messageIds.dropFirst())
        self = GenericMessageProtocol.Confirmation.with {
            $0.firstMessageID = firstMessageID.transportString()
            $0.moreMessageIds = moreMessageIds.map { $0.transportString() }
            $0.type = type
        }
    }

    init(messageId: UUID, type: Confirmation.TypeEnum = .delivered) {
        self = GenericMessageProtocol.Confirmation.with {
            $0.firstMessageID = messageId.transportString()
            $0.type = type
        }
    }
}

// MARK: - External

extension External {
    init(withOTRKey otrKey: Data, sha256: Data) {
        self = External.with {
            $0.otrKey = otrKey
            $0.sha256 = sha256
        }
    }

    public init(withKeyWithChecksum key: ZMEncryptionKeyWithChecksum) {
        self = External(withOTRKey: key.aesKey, sha256: key.sha256)
    }
}

// MARK: - Mention

public extension GenericMessageProtocol.Mention {
    static func createMention(_ mention: WireDataModel.Mention) -> GenericMessageProtocol.Mention? {
        mention.convertToProtosMention()
    }
}

public extension WireDataModel.Mention {
    func convertToProtosMention() -> GenericMessageProtocol.Mention? {
        guard let userID = (user as? ZMUser)?.remoteIdentifier.transportString() else { return nil }

        return GenericMessageProtocol.Mention.with {
            $0.start = Int32(range.location)
            $0.length = Int32(range.length)
            $0.userID = userID

            guard let domain = user.domain else { return }

            $0.qualifiedUserID = GenericMessageProtocol.QualifiedUserId.with {
                $0.id = userID
                $0.domain = domain
            }
        }
    }
}

// MARK: - LinkPreview

public extension LinkPreview {
    init(_ linkMetadata: LinkMetadata) {
        if let articleMetadata = linkMetadata as? ArticleMetadata {
            self = LinkPreview(articleMetadata: articleMetadata)
        } else if let twitterMetadata = linkMetadata as? TwitterStatusMetadata {
            self = LinkPreview(twitterMetadata: twitterMetadata)
        } else {
            self = LinkPreview.with {
                $0.url = linkMetadata.originalURLString
                $0.permanentURL = linkMetadata.permanentURL?.absoluteString ?? linkMetadata.resolvedURL?
                    .absoluteString ?? linkMetadata.originalURLString
                $0.urlOffset = Int32(linkMetadata.characterOffsetInText)
            }
        }
    }

    init(articleMetadata: ArticleMetadata) {
        self = LinkPreview.with {
            $0.url = articleMetadata.originalURLString
            $0.permanentURL = articleMetadata.permanentURL?.absoluteString ?? articleMetadata.resolvedURL?
                .absoluteString ?? articleMetadata.originalURLString
            $0.urlOffset = Int32(articleMetadata.characterOffsetInText)
            $0.title = articleMetadata.title ?? ""
            $0.summary = articleMetadata.summary ?? ""
            if let imageData = articleMetadata.imageData.first {
                $0.image = GenericMessageProtocol.Asset(
                    name: "picture.jpeg",
                    mimeType: "image/jpeg",
                    imageSize: CGSize(width: 0, height: 0),
                    size: UInt64(imageData.count)
                )
            }
        }
    }

    init(twitterMetadata: TwitterStatusMetadata) {
        self = LinkPreview.with {
            $0.url = twitterMetadata.originalURLString
            $0.permanentURL = twitterMetadata.permanentURL?.absoluteString ?? twitterMetadata.resolvedURL?
                .absoluteString ?? twitterMetadata.originalURLString
            $0.urlOffset = Int32(twitterMetadata.characterOffsetInText)
            $0.title = twitterMetadata.message ?? ""
            if let imageData = twitterMetadata.imageData.first {
                $0.image = GenericMessageProtocol.Asset(
                    name: "picture.jpeg",
                    mimeType: "image/jpeg",
                    imageSize: CGSize(width: 0, height: 0),
                    size: UInt64(imageData.count)
                )
            }

            guard let author = twitterMetadata.author,
                  let username = twitterMetadata.username else { return }

            $0.tweet = GenericMessageProtocol.Tweet.with {
                $0.author = author
                $0.username = username
            }
        }
    }

    init(
        withOriginalURL originalURL: String,
        permanentURL: String,
        offset: Int32,
        title: String?,
        summary: String?,
        imageAsset: GenericMessageProtocol.Asset?,
        article: Article? = nil,
        tweet: Tweet? = nil
    ) {
        self = LinkPreview.with {
            $0.url = originalURL
            $0.permanentURL = permanentURL
            $0.urlOffset = offset

            if let title {
                $0.title = title
            }
            if let summary {
                $0.summary = summary
            }
            if let image = imageAsset {
                $0.image = image
            }
            if let tweet {
                $0.tweet = tweet
            }
            if let article {
                $0.article = article
            }
        }
    }

    mutating func update(withOtrKey otrKey: Data, sha256: Data, original: GenericMessageProtocol.Asset.Original?) {
        image.uploaded = GenericMessageProtocol.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        if let original {
            image.original = original
        }
    }

    mutating func update(withAssetKey assetKey: String, assetToken: String?, assetDomain: String?) {
        image.uploaded.assetID = assetKey
        image.uploaded.assetToken = assetToken ?? ""
        image.uploaded.assetDomain = assetDomain ?? ""
    }

    var hasTweet: Bool {
        switch metaData {
        case .tweet:
            true
        default:
            false
        }
    }
}

public extension Tweet {
    init(author: String?, username: String?) {
        self = Tweet.with {
            if let author {
                $0.author = author
            }
            if let username {
                $0.username = username
            }
        }
    }
}

// MARK: - ImageAsset

public extension ImageAsset {
    func imageFormat() -> ZMImageFormat {
        ZMImageFormat(tag)
    }
}

// MARK: - DataTransfer

public extension DataTransfer {

    init(trackingIdentifier: UUID) {
        self = DataTransfer.with {
            $0.trackingIdentifier = TrackingIdentifier(trackingIdentifier)
        }
    }

    var trackingIdentifierData: String? {
        guard
            hasTrackingIdentifier,
            trackingIdentifier.hasIdentifier
        else {
            return nil
        }

        return trackingIdentifier.identifier
    }
}

// MARK: - TrackingIdentifier

extension TrackingIdentifier {
    init(_ uuid: UUID) {
        self = TrackingIdentifier.with {
            $0.identifier = uuid.transportString()
        }
    }
}
