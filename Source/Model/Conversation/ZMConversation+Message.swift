//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

private let log = ZMSLog(tag: "Conversations")

@objc 
extension ZMConversation {
    
    @discardableResult
    func append(buttonActionWithId id: String, referenceMessageId: UUID, nonce: UUID = UUID()) -> ZMClientMessage? {
        let buttonAction = ButtonAction(buttonId: id, referenceMessageId: referenceMessageId)
        return appendClientMessage(with: GenericMessage(content: buttonAction, nonce: nonce), hidden: true)
    }
    
    @discardableResult @objc(appendLocation:nonce:)
    public func append(location: LocationData, nonce: UUID = UUID()) -> ZMConversationMessage? {
        let locationContent = Location.with() {
            $0.latitude = location.latitude
            $0.longitude = location.longitude
            if let name = location.name {
                $0.name = name
            }
            $0.zoom = location.zoomLevel
        }

        return appendClientMessage(with: GenericMessage(content: locationContent, nonce: nonce, expiresAfter: messageDestructionTimeoutValue))
    }
    
    @discardableResult
    public func appendKnock(nonce: UUID = UUID()) -> ZMConversationMessage? {
        return appendClientMessage(with: GenericMessage(content: Knock.with({ $0.hotKnock = false }), nonce: nonce, expiresAfter: messageDestructionTimeoutValue))
    }
    
    @discardableResult @objc(appendSelfConversationWithLastReadOfConversation:)
    public static func appendSelfConversation(withLastReadOf theConversation: ZMConversation) -> ZMClientMessage? {
        guard let moc = theConversation.managedObjectContext,
              let lastReadTimeStamp = theConversation.lastReadServerTimeStamp,
              let convID = theConversation.remoteIdentifier,
              convID != ZMConversation.selfConversationIdentifier(in: moc)
            else { return nil }
        
        let nonce: UUID = UUID()
        let lastRead = LastRead(conversationID: convID, lastReadTimestamp: lastReadTimeStamp)
        let genericMessage = GenericMessage(content: lastRead, nonce: nonce)
        let selfConversation = ZMConversation.selfConversation(in: moc)
        
        let clientMessage = selfConversation.appendClientMessage(with: genericMessage, expires: false, hidden: false)
        return clientMessage
    }
    
    /// Create and append to self conversation a ClientMessage that has generic message data built with the given data
    @nonobjc
    public static func appendSelfConversation(genericMessage: GenericMessage, managedObjectContext: NSManagedObjectContext) -> ZMClientMessage? {
        let selfConversation = ZMConversation.selfConversation(in: managedObjectContext)
        let clientMessage = selfConversation.appendClientMessage(with: genericMessage, expires: false, hidden: false)
        return clientMessage
    }
    
    @nonobjc
    public static func appendSelfConversation(withClearedOf conversation: ZMConversation) -> ZMClientMessage? {
        guard let convID = conversation.remoteIdentifier,
            let cleared = conversation.clearedTimeStamp,
            let managedObjectContext = conversation.managedObjectContext,
            convID != ZMConversation.selfConversationIdentifier(in: managedObjectContext) else {
                return nil
        }
        let message = GenericMessage(content: Cleared(timestamp: cleared, conversationID: convID), nonce: UUID())
        return appendSelfConversation(genericMessage: message, managedObjectContext: managedObjectContext)
    }
    
    @discardableResult @objc(appendText:mentions:fetchLinkPreview:nonce:)
    public func append(text: String,
                       mentions: [Mention] = [],
                       fetchLinkPreview: Bool = true,
                       nonce: UUID = UUID()) -> ZMConversationMessage? {
        
        return append(text: text, mentions: mentions, replyingTo: nil, fetchLinkPreview: fetchLinkPreview, nonce: nonce)
    }
    
    @discardableResult @objc(appendText:mentions:replyingToMessage:fetchLinkPreview:nonce:)
    public func append(text: String,
                       mentions: [Mention] = [],
                       replyingTo quotedMessage: ZMConversationMessage? = nil,
                       fetchLinkPreview: Bool = true,
                       nonce: UUID = UUID()) -> ZMConversationMessage? {
        
        guard !(text as NSString).zmHasOnlyWhitespaceCharacters() else { return nil }
        
        let text = Text(content: text, mentions: mentions, linkPreviews: [], replyingTo: quotedMessage as? ZMOTRMessage)
        let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfter: messageDestructionTimeoutValue)
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: managedObjectContext!)
        
        do {
            clientMessage.add(try genericMessage.serializedData())
            clientMessage.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
            clientMessage.needsLinkAttachmentsUpdate = fetchLinkPreview
            clientMessage.quote = quotedMessage as? ZMMessage
            
            append(clientMessage, expires: true, hidden: false)
            
            if let managedObjectContext = managedObjectContext {
                NotificationInContext(name: ZMConversation.clearTypingNotificationName,
                                      context: managedObjectContext.notificationContext,
                                      object: self).post()
            }
            
            return clientMessage
        } catch {
            return nil
        }
    }
    
    @discardableResult @objc(appendImageAtURL:nonce:)
    public func append(imageAtURL URL: URL, nonce: UUID = UUID()) -> ZMConversationMessage?  {
        guard URL.isFileURL,
              ZMImagePreprocessor.sizeOfPrerotatedImage(at: URL) != .zero,
              let imageData = try? Data.init(contentsOf: URL, options: []) else { return nil }
        
        return append(imageFromData: imageData)
    }
    
    @discardableResult @objc(appendImageFromData:nonce:)
    public func append(imageFromData imageData: Data, nonce: UUID = UUID()) -> ZMConversationMessage? {
        guard let managedObjectContext = managedObjectContext,
              let imageData = try? imageData.wr_removingImageMetadata() else { return nil }
        
        
        // mimeType is assigned first, to make sure UI can handle animated GIF file correctly
        let mimeType = ZMAssetMetaDataEncoder.contentType(forImageData: imageData) ?? ""
        // We update the size again when the the preprocessing is done
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        
        let asset = WireProtos.Asset(imageSize: imageSize, mimeType: mimeType, size: UInt64(imageData.count))
        
        return append(asset: asset, nonce: nonce, expires: true, prepareMessage: { message in
            managedObjectContext.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: imageData)
        })
    }
    
    @discardableResult @objc(appendFile:nonce:)
    public func append(file fileMetadata: ZMFileMetadata, nonce: UUID = UUID()) -> ZMConversationMessage? {
        guard let data = try? Data.init(contentsOf: fileMetadata.fileURL, options: .mappedIfSafe),
              let managedObjectContext = managedObjectContext else { return nil }
        
        return append(asset: fileMetadata.asset, nonce: nonce, expires: false) { (message) in
            managedObjectContext.zm_fileAssetCache.storeAssetData(message, encrypted: false, data: data)
            
            if let thumbnailData = fileMetadata.thumbnail {
                managedObjectContext.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: thumbnailData)
            }
        }
    }
    
    @nonobjc
    private func append(asset: WireProtos.Asset, nonce: UUID, expires: Bool, prepareMessage: (ZMAssetClientMessage) -> Void) -> ZMAssetClientMessage? {
        guard let managedObjectContext = managedObjectContext,
              let message = ZMAssetClientMessage(asset: asset,
                                                 nonce: nonce,
                                                 managedObjectContext: managedObjectContext,
                                                 expiresAfter: messageDestructionTimeoutValue)
        else { return nil }
        
        message.sender = ZMUser.selfUser(in: managedObjectContext)
        
        if expires {
            message.setExpirationDate()
        }
        
        append(message)
        unarchiveIfNeeded()
        prepareMessage(message)
        message.updateCategoryCache()
        message.prepareToSend()
        
        return message
    }
    
    // MARK: - Objective-C compability methods
    
    @discardableResult @objc(appendMessageWithText:)
    public func _append(text: String) -> ZMConversationMessage? {
        return append(text: text)
    }
    
    @discardableResult @objc(appendMessageWithText:fetchLinkPreview:)
    public func _append(text: String, fetchLinkPreview: Bool) -> ZMConversationMessage? {
        return append(text: text, fetchLinkPreview: fetchLinkPreview)
    }
    
    @discardableResult @objc(appendKnock)
    public func _appendKnock() -> ZMConversationMessage? {
        return appendKnock()
    }
    
    @discardableResult @objc(appendMessageWithLocationData:)
    public func _append(location: LocationData) -> ZMConversationMessage? {
        return append(location: location)
    }
    
    @discardableResult @objc(appendMessageWithImageData:)
    public func _append(imageFromData imageData: Data) -> ZMConversationMessage? {
        return append(imageFromData: imageData)
    }
    
    @discardableResult @objc(appendMessageWithFileMetadata:)
    public func _append(file fileMetadata: ZMFileMetadata) -> ZMConversationMessage? {
        return append(file: fileMetadata)
    }
    
    // MARK: - Helper methods
    
    @nonobjc
    func append(message: MessageCapable, nonce: UUID = UUID(), hidden: Bool = false, expires: Bool = false) -> ZMClientMessage? {
        return appendClientMessage(with: GenericMessage(content: message, nonce: nonce), expires: expires, hidden: hidden)
    }
    
}
