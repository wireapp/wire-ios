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


import Foundation
import ZMTransport
import zimages
import ZMCDataModel

private let zmLog = ZMSLog(tag: "Network")

public final class ClientMessageRequestFactory: NSObject {
    
    let protobufContentType = "application/x-protobuf"
    let octetStreamContentType = "application/octet-stream"

    public func upstreamRequestForMessage(_ message: ZMClientMessage, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        return upstreamRequestForEncryptedClientMessage(message, forConversationWithId: conversationId);
    }

    public func upstreamRequestForMessage(_ message: EncryptedPayloadGenerator, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        return upstreamRequestForEncryptedClientMessage(message, forConversationWithId: conversationId);
    }
    
    public func upstreamRequestForAssetMessage(_ format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        return upstreamRequestForEncryptedImageMessage(format, message: message, forConversationWithId: conversationId);
    }
    
    fileprivate func upstreamRequestForEncryptedClientMessage(_ message: EncryptedPayloadGenerator, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        let originalPath = "/" + ["conversations", conversationId.transportString(), "otr", "messages"].joined(separator: "/")
        guard let dataAndMissingClientStrategy = message.encryptedMessagePayloadData() else {
            return nil
        }
        let path = originalPath.pathWithMissingClientStrategy(strategy: dataAndMissingClientStrategy.strategy)
        let request = ZMTransportRequest(path: path, method: .methodPOST, binaryData: dataAndMissingClientStrategy.data, type: protobufContentType, contentDisposition: nil)
        request.addContentDebugInformation(message.debugInfo)
        return request
    }

    fileprivate func upstreamRequestForEncryptedImageMessage(_ format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {

        let genericMessage = format == .medium ? message.imageAssetStorage!.mediumGenericMessage : message.imageAssetStorage!.previewGenericMessage
        let format = ImageFormatFromString(genericMessage!.imageAssetData!.tag)
        let isInline = message.imageAssetStorage!.isInline(for: format)
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
    fileprivate func upstreamRequestForInsertedEncryptedImageMessage(_ format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        if let imageData = message.imageAssetStorage!.imageData(for: format, encrypted: true) {
            let (metaData, strategy) = message.encryptedMessagePayloadForImageFormat(format)!
            let originalPath = "/" +  ["conversations", conversationId.transportString(), "otr", "assets"].joined(separator: "/")
            let path = originalPath.pathWithMissingClientStrategy(strategy: strategy)
            let request = ZMTransportRequest.multipartRequest(withPath: path, imageData: imageData, metaData: metaData.data(), metaDataContentType: protobufContentType, mediaContentType: octetStreamContentType)
            request.addContentDebugInformation("\(message.imageAssetStorage!.genericMessage(for: format))")
            request.addContentDebugInformation("\(metaData)")
            request.forceToBackgroundSession()
            return request
        }
        return nil
    }
    
    // request to reupload image (not inline)
    fileprivate func upstreamRequestForUpdatedEncryptedImageMessage(_ format: ZMImageFormat, message: ZMAssetClientMessage, forConversationWithId conversationId: UUID) -> ZMTransportRequest? {
        let (metaData, strategy) = message.encryptedMessagePayloadForImageFormat(format)!
        
        let originalPath = "/" + ["conversations", conversationId.transportString(), "otr", "assets", message.assetId!.transportString()].joined(separator: "/")
        let path = originalPath.pathWithMissingClientStrategy(strategy: strategy)
        
        let request = ZMTransportRequest(path: path, method: ZMTransportRequestMethod.methodPOST, binaryData: metaData.data(), type: protobufContentType, contentDisposition: nil)
        request.addContentDebugInformation("\(message.imageAssetStorage!.genericMessage(for: format))")
        request.addContentDebugInformation("\(metaData)")
        request.forceToBackgroundSession()
        return request
    }
    
    public func requestToGetAsset(_ assetId: String, inConversation conversationId: UUID, isEncrypted: Bool) -> ZMTransportRequest {
        let path = "/" + ["conversations", conversationId.transportString(), isEncrypted ? "otr" : "", "assets", assetId].joined(separator: "/")
        let request = ZMTransportRequest.imageGet(fromPath: path)
        request.forceToBackgroundSession()
        return request
    }
}

// MARK: - Testing Helper
extension ZMClientMessage {
    public var encryptedMessagePayloadDataOnly : Data? {
        return self.encryptedMessagePayloadData()?.data
    }
}


extension String {

    func pathWithMissingClientStrategy(strategy: MissingClientsStrategy) -> String {
        switch strategy {
        case .doNotIgnoreAnyMissingClient:
            return self
        case .ignoreAllMissingClients:
            return self + "?ignore_missing"
        case .ignoreAllMissingClientsNotFromUsers(let users):
            let userIDs = users.flatMap{$0.remoteIdentifier?.transportString()}
            return self + "?report_missing=\(userIDs.joined(separator: ","))"
        }
    }
}
