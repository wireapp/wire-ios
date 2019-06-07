//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@objc
public protocol MessageContentType: NSObjectProtocol {
    func setContent(on builder: ZMGenericMessageBuilder)
    func expectsReadConfirmation() -> Bool
    func hasLegalHoldStatus() -> Bool
    var legalHoldStatus: ZMLegalHoldStatus { get }
    func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType?
    func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType?
}

@objc
public protocol EphemeralMessageContentType: MessageContentType {
    func setEphemeralContent(on builder: ZMEphemeralBuilder)
}

extension MessageContentType {

    /// An optional hint that indicates the state of legal hold on the sender's side.
    var legalHoldStatusHint: ZMLegalHoldStatus? {
        guard hasLegalHoldStatus() else {
            return nil
        }

        return legalHoldStatus
    }

}

@objc public extension ZMGenericMessage {

    var v3_isImage: Bool {
        return assetData?.original.hasRasterImage ?? false
    }

    var v3_uploadedAssetId: String? {
        guard assetData?.uploaded.hasAssetId() == true else { return nil }
        return assetData?.uploaded.assetId
    }

    var previewAssetId: String? {
        guard assetData?.preview.remote.hasAssetId() == true else { return nil }
        return assetData?.preview.remote.assetId
    }

}

public extension ZMGenericMessage {
    
    @objc
    static func message(withBase64String base64String: String) -> ZMGenericMessage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        
        let builder = ZMGenericMessageBuilder()
        builder.merge(from: data)
        
        return builder.buildAndValidate()
    }
    
    @objc
    static func message(content: MessageContentType, nonce: UUID = UUID()) -> ZMGenericMessage {
        let builder = ZMGenericMessageBuilder()
        
        builder.setMessageId(nonce.transportString())
        content.setContent(on: builder)
        
        return builder.build()
    }
    
    @objc(messageWithContent:nonce:timeout:)
    static func _message(content: EphemeralMessageContentType, nonce: UUID = UUID(), expiresAfter timeout: TimeInterval) -> ZMGenericMessage {
        return message(content: content, nonce: nonce, expiresAfter: timeout)
    }
    
    static func message(content: EphemeralMessageContentType, nonce: UUID = UUID(), expiresAfter timeout: TimeInterval?) -> ZMGenericMessage {
        let builder = ZMGenericMessageBuilder()
    
        let messageContent: MessageContentType
        if let timeout = timeout, timeout > 0 {
            messageContent = ZMEphemeral.ephemeral(content: content, expiresAfter: timeout)
        } else {
            messageContent = content
        }
        
        builder.setMessageId(nonce.transportString())
        messageContent.setContent(on: builder)
        
        return builder.build()
    }
    
    @objc
    static func clientAction(_ action: ZMClientAction, nonce: UUID = UUID()) -> ZMGenericMessage {
        let builder = ZMGenericMessageBuilder()
        
        builder.setMessageId(nonce.transportString())
        builder.setClientAction(action)
        
        return builder.build()
    }
    
    // MARK: Updating assets with asset ID and token
    
    @objc func updatedUploaded(withAssetId assetId: String, token: String?) -> ZMGenericMessage? {
        guard let asset = assetData, let remote = asset.uploaded, asset.hasUploaded() else { return nil }
        let newRemote = remote.updated(withId: assetId, token: token)
        let builder = toBuilder()!
        if hasAsset() {
            let assetBuilder = asset.toBuilder()
            _ = assetBuilder?.setUploaded(newRemote)
            builder.setAsset(assetBuilder)
        } else if hasEphemeral() && ephemeral.hasAsset() {
            let ephemeralBuilder = ephemeral.toBuilder()
            let assetBuilder = ephemeral.asset.toBuilder()
            _ = assetBuilder?.setUploaded(newRemote)
            _ = ephemeralBuilder?.setAsset(assetBuilder)
            builder.setEphemeral(ephemeralBuilder)
        } else {
            return nil
        }

        return builder.buildAndValidate()
    }
        
    func updatedAsset(withUploadedOTRKey otrKey: Data, sha256: Data) -> ZMGenericMessage? {
        return updatedAsset(withAsset: ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha256))
    }
    
    func updatedAsset(withAsset asset: ZMAsset) -> ZMGenericMessage? {
        let builder = toBuilder()!
        
        if hasEphemeral() {
            let ephemeralBuilder = ephemeral.toBuilder()!
            asset.setEphemeralContent(on: ephemeralBuilder)
            builder.setEphemeral(ephemeralBuilder)
        } else {
            asset.setContent(on: builder)
        }
        
        return builder.buildAndValidate()
    }
    
    func updatedAssetOriginal(withImageProperties imageProperties: ZMIImageProperties) -> ZMGenericMessage? {
        return updatedAsset(withAsset: ZMAsset.asset(originalWithImageSize: imageProperties.size, mimeType: imageProperties.mimeType, size: UInt64(imageProperties.length)))
    }
    
    func updatedAssetPreview(withImageProperties imageProperties: ZMIImageProperties) -> ZMGenericMessage? {
        let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: Int32(imageProperties.size.width), height: Int32(imageProperties.size.height))
        let preview = ZMAssetPreview.preview(withSize: UInt64(imageProperties.length), mimeType: imageProperties.mimeType ?? "", remoteData: nil, imageMetadata: imageMetadata)
        let asset = ZMAsset.asset(withOriginal: nil, preview: preview)
        
        return updatedAsset(withAsset: asset)
    }
    
    func updatedAssetPreview(withUploadedOTRKey otrKey: Data, sha256: Data) -> ZMGenericMessage? {
        guard let asset = assetData else { return nil }
        
        let previewBuilder = asset.preview.toBuilder()!
        let remotedata = ZMAssetRemoteData.remoteData(withOTRKey: otrKey, sha256: sha256)
        previewBuilder.setRemote(remotedata)
        
        return updatedAsset(withAsset: ZMAsset.asset(withOriginal: nil, preview: previewBuilder.build()!))
    }

    @objc func updatedPreview(withAssetId assetId: String, token: String?) -> ZMGenericMessage? {
        guard let asset = assetData, let preview = asset.preview, let remote = preview.remote, preview.hasRemote() else { return nil }
        let newRemote = remote.updated(withId: assetId, token: token)
        let previewBuilder = preview.toBuilder()
        _ = previewBuilder?.setRemote(newRemote)
        let builder = toBuilder()!
        if hasAsset() {
            let assetBuilder = asset.toBuilder()
            _ = assetBuilder?.setPreview(previewBuilder)
            builder.setAsset(assetBuilder)
        } else if hasEphemeral() && ephemeral.hasAsset() {
            let ephemeralBuilder = ephemeral.toBuilder()
            let assetBuilder = ephemeral.asset.toBuilder()
            _ = assetBuilder?.setPreview(previewBuilder)
            _ = ephemeralBuilder?.setAsset(assetBuilder)
            builder.setEphemeral(ephemeralBuilder)
        } else {
            return nil
        }

        return builder.buildAndValidate()
    }
    
    @objc func setExpectsReadConfirmation(_ value: Bool) -> ZMGenericMessage? {
        guard let builder = toBuilder() else { return nil }
        
        if hasEphemeral(), let content = ephemeral?.updateExpectsReadConfirmation(value) {
            content.setContent(on: builder)
        } else if let content = content?.updateExpectsReadConfirmation(value) {
            content.setContent(on: builder)
        }
        
        return builder.buildAndValidate()
    }

    @objc func setLegalHoldStatus(_ status: ZMLegalHoldStatus) -> ZMGenericMessage? {
        guard let builder = toBuilder() else { return nil }

        if hasEphemeral(), let content = ephemeral?.updateLegalHoldStatus(status) {
            content.setContent(on: builder)
        } else if let content = content?.updateLegalHoldStatus(status) {
            content.setContent(on: builder)
        }

        return builder.buildAndValidate()
    }

}

@objc
extension ZMKnock: EphemeralMessageContentType {
    
    @objc public static func knock() -> ZMKnock {
        let builder = ZMKnock.builder()!
        builder.setHotKnock(false)
        return builder.build()
    }

    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setKnock(self)
    }
    
    public func setEphemeralContent(on builder: ZMEphemeralBuilder) {
        builder.setKnock(self)
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setExpectsReadConfirmation(value)
        return builder?.build()
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setLegalHoldStatus(value)
        return builder?.build()
    }

}

@objc
extension ZMText: EphemeralMessageContentType {

    public static func text(with message: String, mentions: [Mention] = [], linkPreviews: [ZMLinkPreview] = [], replyingTo quotedMessage: ZMOTRMessage? = nil) -> ZMText {
        let builder = ZMTextBuilder()
                
        builder.setContent(message)
        builder.setMentionsArray(mentions.compactMap(ZMMention.mention))
        builder.setLinkPreviewArray(linkPreviews)
        
        if let quotedMessage = quotedMessage, let quotedMessageNonce = quotedMessage.nonce {
            let quoteBuilder = ZMQuoteBuilder()
            quoteBuilder.setQuotedMessageId(quotedMessageNonce.transportString())
            quoteBuilder.setQuotedMessageSha256(quotedMessage.hashOfContent)
            builder.setQuote(quoteBuilder)
        }
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setText(self)
    }
    
    public func setEphemeralContent(on builder: ZMEphemeralBuilder) {
        builder.setText(self)
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setExpectsReadConfirmation(value)
        return builder?.build()
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setLegalHoldStatus(value)
        return builder?.build()
    }
    
    public func applyEdit(from text: ZMText) -> ZMText {
        guard let builder = text.toBuilder() else { return self }
        
        // Transfer read receipt expectation
        builder.setExpectsReadConfirmation(expectsReadConfirmation())
        
        // We always keep the quote from the original message
        if hasQuote() {
            builder.setQuote(self.quote)
        } else {
            builder.clearQuote()
        }
        
        return builder.build()
    }
    
    public func updateLinkPeview(from text: ZMText) -> ZMText {
        guard let builder = self.toBuilder() else { return self }
        
        if let linkPreview = text.linkPreview, linkPreview.count > 0 {
            builder.setLinkPreviewArray(text.linkPreview)
        }
        
        return builder.build()
    }
    
}

@objc extension ZMAssetRemoteData {

    public func updated(withId assetId: String, token: String?) -> ZMAssetRemoteData {
        let builder = toBuilder()!
        builder.setAssetId(assetId)
        if let token = token {
            builder.setAssetToken(token)
        }
        return builder.build()
    }

}

extension ZMGenericMessage {
    
    // Accessor helpers for linkpreviews
    @objc public var linkPreviews: [ZMLinkPreview] {
        if hasText(), let previews = text.linkPreview {
            return previews.compactMap { $0 }
        }
        if hasEdited(), let previews = edited.text.linkPreview {
            return previews.compactMap { $0 }
        }
        if hasEphemeral() && ephemeral.hasText(), let previews = ephemeral.text.linkPreview {
            return previews.compactMap { $0 }
        }
        return []
    }
    
    public var content: MessageContentType? {
        if hasEphemeral() {
            return ephemeral.content
        } else if hasText() {
            return text
        } else if hasAsset() {
            return asset
        } else if hasImage() {
            return image
        } else if hasKnock() {
            return knock
        } else if hasEdited() {
            return edited
        } else if hasHidden() {
            return hidden
        } else if hasCleared() {
            return cleared
        } else if hasDeleted() {
            return deleted
        } else if hasAvailability() {
            return availability
        } else if hasReaction() {
            return reaction
        } else if hasLocation() {
            return location
        } else if hasCalling() {
            return  calling
        } else if hasConfirmation() {
            return confirmation
        } else if hasExternal() {
            return external
        }
        
       return nil
    }
    
    // Accessor helpers for ephemeral images
    @objc public var imageAssetData : ZMImageAsset? {
        if hasRasterImage {
            return image
        }
        if hasEphemeral() && ephemeral.hasRasterImage {
            return ephemeral.image
        }
        return nil
    }

    @objc public var locationData : ZMLocation? {
        if hasLocation() {
            return location
        }
        if hasEphemeral() && ephemeral.hasLocation() {
            return ephemeral.location
        }
        return nil
    }
    
    @objc public var assetData : ZMAsset? {
        if hasAsset() {
            return asset
        }
        if hasEphemeral() && ephemeral.hasAsset() {
            return ephemeral.asset
        }
        return nil
    }
    
    @objc public var knockData : ZMKnock? {
        if hasKnock() {
            return knock
        }
        if hasEphemeral() && ephemeral.hasKnock() {
            return ephemeral.knock
        }
        return nil
    }
    
    @objc public var textData : ZMText? {
        if hasText() {
            return text
        }
        if hasEdited() && edited.hasText() {
            return edited.text
        }
        if hasEphemeral() && ephemeral.hasText() {
            return ephemeral.text
        }
        return nil
    }

}

extension ZMEphemeral: MessageContentType {

    public static func ephemeral(content: EphemeralMessageContentType, expiresAfter timeout: TimeInterval) -> ZMEphemeral {
        let builder = ZMEphemeralBuilder()
        
        builder.setExpireAfterMillis(Int64(timeout * 1000))
        content.setEphemeralContent(on: builder)
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setEphemeral(self)
    }
    
    public var ephemeralContent: EphemeralMessageContentType? {
        return content as? EphemeralMessageContentType
    }

    public var content: MessageContentType? {
        if hasText() {
            return text
        } else if hasAsset() {
            return asset
        } else if hasImage() {
            return image
        } else if hasKnock() {
            return knock
        } else if hasLocation() {
            return location
        }
        
        return nil
    }

    public func hasLegalHoldStatus() -> Bool {
        return content?.hasLegalHoldStatus() == true
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return content?.legalHoldStatus ?? .DISABLED
    }
    
    public func expectsReadConfirmation() -> Bool {
        return content?.expectsReadConfirmation() ?? false
    }

    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        let builder = toBuilder()!
        (content?.updateExpectsReadConfirmation(value) as? EphemeralMessageContentType)?.setEphemeralContent(on: builder)
        return builder.build()
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        let builder = toBuilder()!
        (content?.updateLegalHoldStatus(value) as? EphemeralMessageContentType)?.setEphemeralContent(on: builder)
        return builder.build()
    }
    
}


extension ZMLocation: EphemeralMessageContentType {

    public static func location(withLatitude latitude: Float, longitude: Float, name: String? = nil, zoomLevel: Int32? = nil) -> ZMLocation {
        let builder = ZMLocation.builder()!
        builder.setLatitude(latitude)
        builder.setLongitude(longitude)
        if let name = name {
            builder.setName(name)
        }
        if let zoomLevel = zoomLevel {
            builder.setZoom(zoomLevel)
        }
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setLocation(self)
    }
    
    public func setEphemeralContent(on builder: ZMEphemeralBuilder) {
        builder.setLocation(self)
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setExpectsReadConfirmation(value)
        return builder?.build()
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setLegalHoldStatus(value)
        return builder?.build()
    }

}

extension ZMExternal: MessageContentType {
    
    @objc public static func external(withOTRKey otrKey: Data, sha256: Data) -> ZMExternal {
        let builder = ZMExternal.builder()!
        builder.setOtrKey(otrKey)
        builder.setSha256(sha256)
        return builder.build()
    }
    
    @objc public static func external(withKeyWithChecksum keys: ZMEncryptionKeyWithChecksum) -> ZMExternal {
        return ZMExternal.external(withOTRKey: keys.aesKey, sha256: keys.sha256)
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setExternal(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

public extension ZMClientEntry {
    
    @objc static func entry(withClient client: UserClient, data: Data) -> ZMClientEntry {
        let builder = ZMClientEntry.builder()!
        builder.setClient(client.clientId)
        builder.setText(data)
        return builder.build()
    }
    
}

public extension ZMUserEntry {
    
    @objc static func entry(withUser user: ZMUser, clientEntries: [ZMClientEntry]) -> ZMUserEntry {
        let builder = ZMUserEntry.builder()!
        builder.setUser(user.userId())
        builder.setClientsArray(clientEntries)
        return builder.build()
    }
    
}

public extension ZMNewOtrMessage {
    
    @objc static func message(withSender sender: UserClient, nativePush: Bool, recipients: [ZMUserEntry], blob: Data? = nil) -> ZMNewOtrMessage {
        let builder = ZMNewOtrMessage.builder()!
        builder.setNativePush(nativePush)
        builder.setSender(sender.clientId)
        builder.setRecipientsArray(recipients)
        if nil != blob {
            builder.setBlob(blob)
        }
        return builder.build()
    }
    
}

@objc
extension ZMAsset: EphemeralMessageContentType {
    
    static func asset(originalWithImageSize imageSize: CGSize, mimeType: String, size: UInt64) -> ZMAsset {
        let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: Int32(imageSize.width), height: Int32(imageSize.height))
        let original = ZMAssetOriginal.original(withSize: size, mimeType: mimeType, name: nil, imageMetaData: imageMetadata)
        return ZMAsset.asset(withOriginal: original, preview: nil)
    }
        
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setAsset(self)
    }
    
    public func setEphemeralContent(on builder: ZMEphemeralBuilder) {
        builder.setAsset(self)
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setExpectsReadConfirmation(value)
        return builder?.build()
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        let builder = toBuilder()
        builder?.setLegalHoldStatus(value)
        return builder?.build()
    }
    
}

extension ZMImageAsset: EphemeralMessageContentType {
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setImage(self)
    }
    
    public func setEphemeralContent(on builder: ZMEphemeralBuilder) {
        builder.setImage(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}


public extension ZMArticle {

    @objc static func article(withPermanentURL permanentURL: String, title: String?, summary: String?, imageAsset: ZMAsset?) -> ZMArticle {
        let articleBuilder = ZMArticle.builder()!
        articleBuilder.setPermanentUrl(permanentURL)
        if let title = title {
            articleBuilder.setTitle(title)
        }
        if let summary = summary {
            articleBuilder.setSummary(summary)
        }
        if let image = imageAsset {
            articleBuilder.setImage(image)
        }
        return articleBuilder.build()
    }
    
}

public extension ZMLinkPreview {
    
    @objc static func linkPreview(withOriginalURL originalURL: String, permanentURL: String, offset: Int32, title: String?, summary: String?, imageAsset: ZMAsset?) -> ZMLinkPreview {
        return linkPreview(withOriginalURL: originalURL, permanentURL: permanentURL, offset: offset, title: title, summary: summary, imageAsset: imageAsset, tweet: nil)
    }
    
    @objc static func linkPreview(withOriginalURL originalURL: String, permanentURL: String, offset: Int32, title: String?, summary: String?, imageAsset: ZMAsset?, tweet: ZMTweet?) -> ZMLinkPreview {
        let article = ZMArticle.article(withPermanentURL: permanentURL, title: title, summary: summary, imageAsset: imageAsset)
        return linkPreview(withOriginalURL: originalURL, permanentURL: permanentURL, offset: offset, title: title, summary: summary, imageAsset: imageAsset, article: article, tweet: tweet)
    }
    
    fileprivate static func linkPreview(withOriginalURL originalURL: String, permanentURL: String, offset: Int32, title: String?, summary: String?, imageAsset: ZMAsset?, article: ZMArticle?, tweet: ZMTweet?) -> ZMLinkPreview {
        let linkPreviewBuilder = ZMLinkPreview.builder()!
        linkPreviewBuilder.setUrl(originalURL)
        linkPreviewBuilder.setPermanentUrl(permanentURL)
        linkPreviewBuilder.setUrlOffset(offset)
        
        if let title = title {
            linkPreviewBuilder.setTitle(title)
        }
        if let summary = summary {
            linkPreviewBuilder.setSummary(summary)
        }
        if let imageAsset = imageAsset {
            linkPreviewBuilder.setImage(imageAsset)
        }
        if let tweet = tweet {
            linkPreviewBuilder.setTweet(tweet)
        }
        if let article = article {
            linkPreviewBuilder.setArticle(article)
        }
        
        return linkPreviewBuilder.build()
    }

    func update(withOtrKey otrKey: Data, sha256: Data) -> ZMLinkPreview {
        return update(withOtrKey: otrKey, sha256: sha256, original: nil)
    }
    
    func update(withOtrKey otrKey: Data, sha256: Data, original: ZMAssetOriginal?) -> ZMLinkPreview {
        let linkPreviewbuilder = toBuilder()!
        
        if hasArticle() {
            let articleBuilder = article.toBuilder()!
            let assetBuilder = article.image.toBuilder()!
            assetBuilder.setUploaded(remoteBuilder(withOTRKey: otrKey, sha256: sha256))
            if let original = original {
                assetBuilder.setOriginal(original)
            }
            articleBuilder.setImage(assetBuilder)
            linkPreviewbuilder.setArticle(articleBuilder)
        }
        
        let newAssetBuilder = image.toBuilder()!
        newAssetBuilder.setUploaded(remoteBuilder(withOTRKey: otrKey, sha256: sha256))
        if let original = original {
            newAssetBuilder.setOriginal(original)
        }
        linkPreviewbuilder.setImage(newAssetBuilder)
        
        return linkPreviewbuilder.build()
    }
    
    func update(withAssetKey assetKey: String, assetToken: String?) -> ZMLinkPreview {
        
        let linkPreviewbuilder = toBuilder()!
        
        if hasArticle() {
            let articleRemoteBuilder = article.image.uploaded.builder(withAssetID: assetKey, token: assetToken)
            let articleBuilder = article.toBuilder()!
            let assetBuilder = article.image.toBuilder()!
            assetBuilder.setUploaded(articleRemoteBuilder)
            articleBuilder.setImage(assetBuilder)
            linkPreviewbuilder.setArticle(articleBuilder)
        }
        
        let newAssetRemoteBuilder = image.uploaded.builder(withAssetID: assetKey, token: assetToken)
        let newImageBuilder = image.toBuilder()!
        newImageBuilder.setUploaded(newAssetRemoteBuilder)
        linkPreviewbuilder.setImage(newImageBuilder)
        
        return linkPreviewbuilder.build()
    }
    
    fileprivate func remoteBuilder(withOTRKey otrKey: Data, sha256: Data) -> ZMAssetRemoteDataBuilder {
        let remoteDataBuilder = ZMAssetRemoteData.builder()!
        remoteDataBuilder.setOtrKey(otrKey)
        remoteDataBuilder.setSha256(sha256)
        return remoteDataBuilder
    }
    
    fileprivate func uploadedBuilder(withAssetKey key: String, token: String?) -> ZMAssetRemoteDataBuilder {
        let remoteDataBuilder = ZMAssetRemoteData.builder()!
        remoteDataBuilder.setAssetId(key)
        if let token = token {
            remoteDataBuilder.setAssetToken(token)
        }
        return remoteDataBuilder
    }
    
}


public extension ZMTweet {
    @objc static func tweet(withAuthor author: String?, username: String?) -> ZMTweet {
        let builder = ZMTweet.builder()!
        if let author = author {
            builder.setAuthor(author)
        }
        if let username = username {
            builder.setUsername(username)
        }
        return builder.build()
    }
}

@objc
extension ZMAvailability: MessageContentType {
    
    public static func availability(_ availability : Availability) -> ZMAvailability {
        let builder = ZMAvailability.builder()!
        
        switch availability {
        case .none:
            builder.setType(.NONE)
        case .available:
            builder.setType(.AVAILABLE)
        case .away:
            builder.setType(.AWAY)
        case .busy:
            builder.setType(.BUSY)
        }
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setAvailability(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

@objc
extension ZMMessageDelete: MessageContentType {
    
    public static func delete(messageId: UUID) -> ZMMessageDelete {
        let builder = ZMMessageDeleteBuilder()
        
        builder.setMessageId(messageId.transportString())
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setDeleted(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

@objc
extension ZMMessageHide: MessageContentType {
    
    public static func hide(conversationId: UUID, messageId: UUID) -> ZMMessageHide {
        let builder = ZMMessageHideBuilder()
        
        builder.setConversationId(conversationId.transportString())
        builder.setMessageId(messageId.transportString())
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setHidden(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

@objc
extension ZMMessageEdit: MessageContentType {
    
    public static func edit(with text: ZMText, replacingMessageId: UUID) -> ZMMessageEdit {
        let builder = ZMMessageEditBuilder()
        
        builder.setText(text)
        builder.setReplacingMessageId(replacingMessageId.transportString())
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setEdited(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

@objc
extension ZMReaction: MessageContentType {
    
    public static func reaction(emojiString: String, messageId: UUID) -> ZMReaction {
        let builder = ZMReactionBuilder()
        
        builder.setEmoji(emojiString)
        builder.setMessageId(messageId.transportString())
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setReaction(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }

    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
       return nil
    }

}

@objc
extension ZMConfirmation: MessageContentType {
    
    public static func confirm(messageId: UUID, type: ZMConfirmationType = .DELIVERED) -> ZMConfirmation {
        let builder = ZMConfirmationBuilder()
        
        builder.setFirstMessageId(messageId.transportString())
        builder.setType(type)
        
        return builder.build()
    }
    
    public static func confirm(messages: [UUID], type: ZMConfirmationType = .DELIVERED) -> ZMConfirmation {
        let builder = ZMConfirmationBuilder()
        
        builder.setType(type)
        
        if let messageId = messages.first {
            builder.setFirstMessageId(messageId.transportString())
        }
        
        let moreMessageIds = messages.dropFirst().map({ $0.transportString() })
        builder.setMoreMessageIdsArray(moreMessageIds)
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setConfirmation(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

@objc
extension ZMMention {
    
    public static func mention(_ mention: Mention) -> ZMMention? {
        guard let userId = (mention.user as? ZMUser)?.remoteIdentifier else { return nil }
        
        let builder = ZMMentionBuilder()
        
        builder.setUserId(userId.transportString())
        builder.setStart(Int32(mention.range.location))
        builder.setLength(Int32(mention.range.length))
    
        return builder.build()
    }
    
}

@objc
extension ZMLastRead: MessageContentType {
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setLastRead(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

extension ZMCleared: MessageContentType {
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setCleared(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

extension ZMCalling: MessageContentType {
    
    public static func calling(message: String) -> ZMCalling {
        let builder = ZMCallingBuilder()
        
        builder.setContent(message)
        
        return builder.build()
    }
    
    public func setContent(on builder: ZMGenericMessageBuilder) {
        builder.setCalling(self)
    }
    
    public func expectsReadConfirmation() -> Bool {
        return false
    }

    public func hasLegalHoldStatus() -> Bool {
        return false
    }

    public var legalHoldStatus: ZMLegalHoldStatus {
        return .DISABLED
    }
    
    public func updateExpectsReadConfirmation(_ value: Bool) -> MessageContentType? {
        return nil
    }

    public func updateLegalHoldStatus(_ value: ZMLegalHoldStatus) -> MessageContentType? {
        return nil
    }
    
}

