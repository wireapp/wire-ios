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


/// Convenience functions to simplify the creation of
/// the protobuf objects without using the provided builder

public extension ZMGenericMessage {
    
    public static func genericMessage(withExternal external: ZMExternal, messageID: String) -> ZMGenericMessage {
        let builder = ZMGenericMessage.builder()!
        builder.setExternal(external)
        builder.setMessageId(messageID)
        return builder.build()
    }
    
    
    public static func genericMessage(withKeyWithChecksum keys: ZMEncryptionKeyWithChecksum, messageID: String) -> ZMGenericMessage {
        let external = ZMExternal.external(withKeyWithChecksum: keys)
        return ZMGenericMessage.genericMessage(withExternal: external, messageID: messageID)
    }
    
    // MARK: ZMLocationMessageData
    
    public static func genericMessage(withLocation location: ZMLocation, messageID: String) -> ZMGenericMessage {
        let builder = ZMGenericMessage.builder()!
        builder.setLocation(location)
        builder.setMessageId(messageID)
        return builder.build()
    }
    
    // MARK: ZMAssetClientMessage
    
    public static func genericMessage(withAsset asset: ZMAsset, messageID: String) -> ZMGenericMessage {
        let builder = ZMGenericMessage.builder()!
        builder.setAsset(asset)
        builder.setMessageId(messageID)
        return builder.build()
    }
    
    public static func genericMessage(withAssetSize size: UInt64,
                                                    mimeType: String,
                                                    name: String,
                                                    messageID: String) -> ZMGenericMessage {
        
        let asset = ZMAsset.asset(withOriginal: .original(withSize: size, mimeType: mimeType, name: name))
        return ZMGenericMessage.genericMessage(withAsset: asset, messageID: messageID)
    }
    
    public static func genericMessage(withFileMetadata fileMetadata: ZMFileMetadata, messageID: String) -> ZMGenericMessage {
        return ZMGenericMessage.genericMessage(withAsset: fileMetadata.asset, messageID: messageID)
    }
    
    public static func genericMessage(withUploadedOTRKey otrKey: Data, sha256: Data, messageID: String) -> ZMGenericMessage {
        return ZMGenericMessage.genericMessage(withAsset: .asset(withUploadedOTRKey: otrKey, sha256: sha256), messageID: messageID)
    }
    
    public static func genericMessage(withNotUploaded notUploaded: ZMAssetNotUploaded, messageID: String) -> ZMGenericMessage {
        return ZMGenericMessage.genericMessage(withAsset: .asset(withNotUploaded: notUploaded), messageID: messageID)
    }
    
}

// Accessor helpers for linkpreviews
extension ZMGenericMessage {
    public var linkPreviews: [ZMLinkPreview] {
        if hasText(), let previews = text.linkPreview {
            return previews.flatMap { $0 as? ZMLinkPreview }
        } else if hasEdited(), let previews = edited.text.linkPreview {
            return previews.flatMap { $0 as? ZMLinkPreview }
        }

        return []
    }
}

public extension ZMLocation {

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
}

public extension ZMExternal {
    
    public static func external(withOTRKey otrKey: Data, sha256: Data) -> ZMExternal {
        let builder = ZMExternal.builder()!
        builder.setOtrKey(otrKey)
        builder.setSha256(sha256)
        return builder.build()
    }
    
    public static func external(withKeyWithChecksum keys: ZMEncryptionKeyWithChecksum) -> ZMExternal {
        return ZMExternal.external(withOTRKey: keys.aesKey, sha256: keys.sha256)
    }
    
}

public extension ZMAsset {
    
    public static func asset(withOriginal original: ZMAssetOriginal? = nil, preview: ZMAssetPreview? = nil) -> ZMAsset {
        let builder = ZMAsset.builder()!
        if let original = original {
            builder.setOriginal(original)
        }
        if let preview = preview {
            builder.setPreview(preview)
        }
        return builder.build()
    }
    
    public static func asset(withUploadedOTRKey otrKey: Data, sha256: Data) -> ZMAsset {
        let builder = ZMAsset.builder()!
        builder.setUploaded(.remoteData(withOTRKey: otrKey, sha256: sha256))
        return builder.build()
    }
    
    public static func asset(withNotUploaded notUploaded: ZMAssetNotUploaded) -> ZMAsset {
        let builder = ZMAsset.builder()!
        builder.setNotUploaded(notUploaded)
        return builder.build()
    }
    
}

public extension ZMAssetOriginal {
    
    public static func original(withSize size: UInt64, mimeType: String, name: String?) -> ZMAssetOriginal {
        return original(withSize: size, mimeType: mimeType, name: name, imageMetaData: nil)
    }
    
    public static func original(withSize size: UInt64, mimeType: String, name: String?, imageMetaData: ZMAssetImageMetaData?) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        if let name = name {
            builder.setName(name)
        }
        if let imageMeta = imageMetaData {
            builder.setImage(imageMeta)
        }
        return builder.build()
    }
    
    public static func original(withSize size: UInt64, mimeType: String, name: String, videoDurationInMillis: UInt, videoDimensions: CGSize) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setName(name)
        
        let videoBuilder = ZMAssetVideoMetaData.builder()!
        videoBuilder.setDurationInMillis(UInt64(videoDurationInMillis))
        videoBuilder.setWidth(Int32(videoDimensions.width))
        videoBuilder.setHeight(Int32(videoDimensions.height))
        builder.setVideo(videoBuilder)
        
        return builder.build()
    }
    
    public static func original(withSize size: UInt64, mimeType: String, name: String, audioDurationInMillis: UInt, normalizedLoudness: [Float]) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setName(name)
        
        let loudnessArray = normalizedLoudness.map { UInt8(roundf($0*255)) }
        let audioBuilder = ZMAssetAudioMetaData.builder()!
        audioBuilder.setDurationInMillis(UInt64(audioDurationInMillis))
        audioBuilder.setNormalizedLoudness(NSData(bytes: loudnessArray, length: loudnessArray.count) as Data!)
        builder.setAudio(audioBuilder)
        
        return builder.build()
    }
    
    /// Returns the normalized loudness as floats between 0 and 1
    public var normalizedLoudnessLevels : [Float] {
        
        guard self.audio.hasNormalizedLoudness() else { return [] }
        guard self.audio.normalizedLoudness.count > 0 else { return [] }
        
        guard let data = self.audio.normalizedLoudness else {return []}
        let offsets = 0..<data.count
        return offsets.map { offset -> UInt8 in
            var number : UInt8 = 0
            data.copyBytes(to: &number, from: (0 + offset)..<(MemoryLayout<UInt8>.size+offset))
            return number
            }
            .map { Float(Float($0)/255.0) }
    }
}

public extension ZMAssetPreview {
    
    public static func preview(withSize size: UInt64, mimeType: String, remoteData: ZMAssetRemoteData, imageMetaData: ZMAssetImageMetaData) -> ZMAssetPreview {
        let builder = ZMAssetPreview.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setRemote(remoteData)
        builder.setImage(imageMetaData)
        return builder.build()
    }

}

public extension ZMAssetImageMetaData {
    public static func imageMetaData(withWidth width: Int32, height: Int32) -> ZMAssetImageMetaData {
        let builder = ZMAssetImageMetaData.builder()!
        builder.setWidth(width)
        builder.setHeight(height)
        return builder.build()
    }
}

public extension ZMAssetRemoteData {
    
    public static func remoteData(withOTRKey otrKey: Data, sha256: Data, assetId: String? = nil, assetToken: String? = nil) -> ZMAssetRemoteData {
        let builder = ZMAssetRemoteData.builder()!
        builder.setOtrKey(otrKey)
        builder.setSha256(sha256)
        if let identifier = assetId {
            builder.setAssetId(identifier)
        }
        if let token = assetToken {
            builder.setAssetToken(token)
        }
        return builder.build()
    }
}

public extension ZMClientEntry {
    
    public static func entry(withClient client: UserClient, data: Data) -> ZMClientEntry {
        let builder = ZMClientEntry.builder()!
        builder.setClient(client.clientId)
        builder.setText(data)
        return builder.build()
    }
    
}

public extension ZMUserEntry {
    
    public static func entry(withUser user: ZMUser, clientEntries: [ZMClientEntry]) -> ZMUserEntry {
        let builder = ZMUserEntry.builder()!
        builder.setUser(user.userId())
        builder.setClientsArray(clientEntries)
        return builder.build()
    }
    
}

public extension ZMNewOtrMessage {
    
    public static func message(withSender sender: UserClient, nativePush: Bool, recipients: [ZMUserEntry], blob: Data? = nil) -> ZMNewOtrMessage {
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

public extension ZMOtrAssetMeta {
    
    public static func otrAssetMeta(withSender sender: UserClient, nativePush: Bool, inline: Bool, recipients: [ZMUserEntry]) -> ZMOtrAssetMeta {
        let builder = ZMOtrAssetMeta.builder()!
        builder.setNativePush(nativePush)
        builder.setIsInline(inline)
        builder.setSender(sender.clientId)
        builder.setRecipientsArray(recipients)
        return builder.build()
    }
    
}


public extension ZMArticle {

    public static func article(withPermanentURL permanentURL: String, title: String?, summary: String?, imageAsset: ZMAsset?) -> ZMArticle {
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
    
    public static func linkPreview(withOriginalURL originalURL: String, permanentURL: String, offset: Int32, title: String?, summary: String?, imageAsset: ZMAsset?) -> ZMLinkPreview {
        return linkPreview(withOriginalURL: originalURL, permanentURL: permanentURL, offset: offset, title: title, summary: summary, imageAsset: imageAsset, tweet: nil)
    }
    
    public static func linkPreview(withOriginalURL originalURL: String, permanentURL: String, offset: Int32, title: String?, summary: String?, imageAsset: ZMAsset?, tweet: ZMTweet?) -> ZMLinkPreview {
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

extension ZMAssetRemoteData {
    func builder(withAssetID assetID: String, token: String?) -> ZMAssetRemoteDataBuilder {
        let builder = toBuilder()!
        builder.setAssetId(assetID)
        if let token = token {
            builder.setAssetToken(token)
        }
        return builder
    }
}

public extension ZMTweet {
    public static func tweet(withAuthor author: String?, username: String?) -> ZMTweet {
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

// MARK: - Equatable

func ==(lhs: ZMAssetPreview, rhs: ZMAssetPreview) -> Bool {
    return lhs.data() == rhs.data()
}
