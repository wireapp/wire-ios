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

public class ClientMessageRequestFactory: NSObject {
    
    public func upstreamRequestForMessage(message: ZMClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        if(message.isEncrypted) {
            return upstreamRequestForEncriptedClientMessage(message, forConversationWithId: conversationId);
        }
        else {
            return upstreamRequestForClientMessage(message, forConversationWithId: conversationId);
        }
    }
    
    public func upstreamRequestForAssetMessage(format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        if (message.isEncrypted) {
            return upstreamRequestForEncryptedImageMessage(format, message: message, forConversationWithId: conversationId);
        } else {
            return upstreamRequestForImageMessage(format, message: message, forConversationWithId: conversationId);
        }
    }
    
    private func upstreamRequestForEncriptedClientMessage(message: ZMClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        let path = "/" + ["conversations", conversationId.transportString(), "otr", "messages"].joinWithSeparator("/")
        let metaData = message.encryptedMessagePayloadData()
        let request = ZMTransportRequest(path: path, method: ZMTransportRequestMethod.MethodPOST, binaryData: metaData, type: "application/x-protobuf", contentDisposition: nil)
        request.appendDebugInformation("\(message.genericMessage)")
        return request
    }

    private func upstreamRequestForClientMessage(message: ZMClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        let path = "/" + ["conversations", conversationId.transportString(), "client-messages"].joinWithSeparator("/")
        let payload = ["content": message.genericMessage.data().base64String]
        let request = ZMTransportRequest(path: path, method: ZMTransportRequestMethod.MethodPOST, payload: payload)
        request.appendDebugInformation("\(message.genericMessage)")
        return request
    }

    private func upstreamRequestForEncryptedImageMessage(format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {

        let genericMessage = format == .Medium ? message.mediumGenericMessage : message.previewGenericMessage
        let format = ImageFormatFromString(genericMessage.image.tag)
        let isInline = message.isInlineForFormat(format)
        let hasAssetId = message.assetId != nil
        
        if isInline || !hasAssetId {
            //inline messsages and new messages should be always posted with image data
            //and using endpoint for image asset upload
            return upstreamRequestForInsertedEncryptedImageMessage(format, message: message, forConversationWithId: conversationId);
        }
        else if hasAssetId {
            //not inline messages updated with missing clients should use retry endpoint and not send message data
            return upstreamRequestForUpdatedEncryptedImageMessage(format, message: message, forConversationWithId: conversationId)
        }
        return nil
    }
    
    // request for first upload and reupload inline images
    private func upstreamRequestForInsertedEncryptedImageMessage(format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        if let imageData = message.imageDataForFormat(format, encrypted: true) {
            let path = "/" +  ["conversations", conversationId.transportString(), "otr", "assets"].joinWithSeparator("/")
            let metaData = message.encryptedMessagePayloadForImageFormat(format)
            let request = ZMTransportRequest.multipartRequestWithPath(path, imageData: imageData, metaData: metaData.data(), metaDataContentType: "application/x-protobuf", mediaContentType: "application/octet-stream")
            request.appendDebugInformation("\(message.genericMessageForFormat(format))")
            request.appendDebugInformation("\(metaData)")
            return request
        }
        return nil
    }
    
    // request to reupload image (not inline)
    private func upstreamRequestForUpdatedEncryptedImageMessage(format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        let path = "/" + ["conversations", conversationId.transportString(), "otr", "assets", message.assetId!.transportString()].joinWithSeparator("/")
        let metaData = message.encryptedMessagePayloadForImageFormat(format)
        let request = ZMTransportRequest(path: path, method: ZMTransportRequestMethod.MethodPOST, binaryData: metaData.data(), type: "application/x-protobuf", contentDisposition: nil)
        request.appendDebugInformation("\(message.genericMessageForFormat(format))")
        request.appendDebugInformation("\(metaData)")
        return request
    }
    
    
    private func upstreamRequestForImageMessage(format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: NSUUID) -> ZMTransportRequest? {
        if let imageData =  message.imageDataForFormat(format, encrypted: false) {
            let path = "/" + ["conversations", conversationId.transportString(), "assets"].joinWithSeparator("/")
            let disposition = ZMAssetMetaDataEncoder.contentDispositionForImageOwner(
                message.genericMessageForFormat(format),
                format: format,
                conversationID: conversationId,
                correlationID: message.nonce)
            let request = ZMTransportRequest.multipartRequestWithPath(path, imageData: imageData, metaData: disposition)
            request.appendDebugInformation("\(message.genericMessageForFormat(format))")
            return request
        }
        return nil
    }
    
    public func requestToGetAsset(assetId: NSUUID, inConversation conversationId: NSUUID, isEncrypted: Bool) -> ZMTransportRequest {
        let path = "/" + ["conversations", conversationId.transportString()!, isEncrypted ? "otr" : "", "assets", assetId.transportString()!].joinWithSeparator("/")
        return ZMTransportRequest.imageGetRequestFromPath(path)
    }

}
