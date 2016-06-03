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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMTransport
import zimages


private let zmLog = ZMSLog(tag: "Network")


// MARK: - File Asset Upload Request generation


extension ClientMessageRequestFactory {
    
    /**
     This method should be used as entry point to create a request to insert or update a file message of any kind.
     
     - parameter format:         The format (Placeholder, FileData...) of the request that should be created
     - parameter message:        The message for which the request should be created
     - parameter conversationId: The @c remoteIdentifier of the conversation in which the message should be inserted on the remote
     
     - returns: The generated request or @c nil in case of an error or a failed precondition
     */
    public func upstreamRequestForEncryptedFileMessage(format: ZMAssetClientMessageDataType, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        
        let hasAssetId = message.assetId != nil
        
        if format == .Placeholder {
            return upstreamRequestForInsertedEcryptedPlaceholderFileMessage(message, forConversationWithId: conversationId)
        }
        
        if format == .Thumbnail {
            return upstreamRequestForInsertedEcryptedThumbnailFileMessage(message, forConversationWithId: conversationId)
        }
        
        if format == .FullAsset {
            if !hasAssetId {
                return upstreamRequestForInsertedEcryptedFullAssetFileMessage(message, forConversationWithId: conversationId)
            } else {
                return upstreamRequestForUpdatedEcryptedFullAssetFileMessage(message, forConversationWithId: conversationId)
            }
        }
        
        return nil
    }
    
    // MARK: Inserting
    
    /// Returns the request to upload the Asset.Original message
    func upstreamRequestForInsertedEcryptedPlaceholderFileMessage(message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        let path = "/conversations/\(conversationId.transportString())/otr/messages"
        guard let assetOriginalData = message.encryptedMessagePayloadForDataType(.Placeholder) where nil != message.filename else { return nil }
        let request = ZMTransportRequest(path: path, method: .MethodPOST, binaryData: assetOriginalData, type: protobufContentType, contentDisposition: nil)
        request.appendDebugInformation("Inserting file upload placeholder (Original)")
        request.appendDebugInformation("\(message.dataSet)")
        request.forceToBackgroundSession()
        return request
    }
    
    /// Returns the multipart request to upload the Asset.Uploaded payload which includes the file data
    func upstreamRequestForInsertedEcryptedFullAssetFileMessage(message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        guard let moc = message.managedObjectContext else { return nil }
        guard message.imageMessageData == nil else { return nil }
        let path = "/conversations/\(conversationId.transportString())/otr/assets"
        guard let assetUploadedData = message.encryptedMessagePayloadForDataType(.FullAsset), filename = message.filename else { return nil }
        guard let fileData = moc.zm_fileAssetCache.assetData(message.nonce, fileName: filename, encrypted: true) else { return nil }
        let multipartData = dataForMultipartFileUploadRequest(assetUploadedData, fileData: fileData)
        
        guard let uploadURL = moc.zm_fileAssetCache.storeRequestData(message.nonce, data: multipartData) else {
            zmLog.debug("Failed to write multipart file upload request to file")
            return nil
        }
        
        let request = ZMTransportRequest.uploadRequestWithFileURL(uploadURL, path: path, contentType: "multipart/mixed")
        request.appendDebugInformation("Inserting file upload metadata (Asset.Uploaded) with binary file data")
        return request
    }
    
    /// Returns the multipart request to upload the thumbnail payload which includes the file data
    func upstreamRequestForInsertedEcryptedThumbnailFileMessage(message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        guard let moc = message.managedObjectContext else { return nil }
        guard message.fileMessageData != nil else { return nil }
        let path = "/conversations/\(conversationId.transportString())/otr/assets"
        guard let thumbnailMetaData = message.encryptedMessagePayloadForDataType(.Thumbnail) else { return nil }
        guard let thumbnailData = moc.zm_imageAssetCache.assetData(message.nonce, format: .Medium, encrypted: true) else { return nil }
        
        let request = ZMTransportRequest.multipartRequestWithPath(
            path,
            imageData: thumbnailData,
            metaData: thumbnailMetaData,
            metaDataContentType: protobufContentType,
            mediaContentType: octetStreamContentType
        )
        
        request.appendDebugInformation("Inserting file upload thumbnail (Asset.Preview) with binary file data")
        return request
    }
    
    // MARK: Updating
    
    func upstreamRequestForUpdatedEcryptedFullAssetFileMessage(message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        let path = "/conversations/\(conversationId.transportString())/otr/assets/\(message.assetId!.transportString())"
        guard let assetUploadedData = message.encryptedMessagePayloadForDataType(.FullAsset) else { return nil }
        let request = ZMTransportRequest(path: path, method: .MethodPOST, binaryData: assetUploadedData, type: protobufContentType, contentDisposition: nil)
        request.appendDebugInformation("Updating file upload metadata (Asset.Uploaded)")
        request.appendDebugInformation("\(assetUploadedData)")
        request.forceToBackgroundSession()
        return request
    }
    
    // MARK: Downloading
    
    func downstreamRequestForEcryptedOriginalFileMessage(message: ZMAssetClientMessage) -> ZMTransportRequest? {
        guard let conversation = message.conversation else { return nil }
        let path = "/conversations/\(conversation.remoteIdentifier.transportString())/otr/assets/\(message.assetId!.transportString())"
        
        let request = ZMTransportRequest(getFromPath: path)
        request.appendDebugInformation("Downloading file (Asset)")
        request.forceToBackgroundSession()
        return request
    }
    
    // MARK: Helper
    
    func dataForMultipartFileUploadRequest(metaData: NSData, fileData: NSData) -> NSData {
        let fileDataHeader = ["Content-MD5": fileData.zmMD5Digest().base64String()]
        return .multipartDataWithItems([
            ZMMultipartBodyItem(data: metaData, contentType: protobufContentType, headers: nil),
            ZMMultipartBodyItem(data: fileData, contentType: octetStreamContentType, headers: fileDataHeader),
            ], boundary: "frontier")
    }
    
}
