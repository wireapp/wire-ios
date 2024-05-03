//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import SwiftProtobuf
import WireDataModel
import WireImages
import WireTransport

private let zmLog = ZMSLog(tag: "Network")

public final class ClientMessageRequestFactory: NSObject {

    let protobufContentType = "application/x-protobuf"
    let octetStreamContentType = "application/octet-stream"

    public func upstreamRequestForFetchingClients(conversationId: UUID,
                                                  domain: String?,
                                                  selfClient: UserClient,
                                                  apiVersion: APIVersion) -> ZMTransportRequest? {
        var path: String
        var message: SwiftProtobuf.Message

        switch apiVersion {
        case .v0:
            path = "/" + ["conversations",
                          conversationId.transportString(),
                          "otr",
                          "messages"].joined(separator: "/")

            // In wire protos this is annotated as deprecated, and recommended to use QualifiedNewOtrMessage
            // So, not sure if we should use it with v0 on non-federated endpoints
            // But, if so, we can create the message once for all versions
            message = Proteus_NewOtrMessage(
                withSender: selfClient,
                nativePush: false,
                recipients: []
            )
        case .v1, .v2, .v3, .v4, .v5, .v6:
            guard let domain = domain.nonEmptyValue ?? BackendInfo.domain else {
                zmLog.error("could not create request: missing domain")
                return nil
            }

            path = "/" + ["conversations",
                          domain,
                          conversationId.transportString(),
                          "proteus",
                          "messages"].joined(separator: "/")

            message = Proteus_QualifiedNewOtrMessage(
                withSender: selfClient,
                nativePush: false,
                recipients: [],
                missingClientsStrategy: .doNotIgnoreAnyMissingClient
            )
        }

        guard let data = try? message.serializedData() else {
            zmLog.debug("failed to serialize message")
            return nil
        }

        return ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    public func requestToGetAsset(_ assetId: String, inConversation conversationId: UUID, apiVersion: APIVersion) -> ZMTransportRequest {
        guard apiVersion < .v2 else { fatalError("Endpoint not availale in API v2") }
        let path = "/" + ["conversations", conversationId.transportString(), "otr", "assets", assetId].joined(separator: "/")
        let request = ZMTransportRequest.imageGet(fromPath: path, apiVersion: apiVersion.rawValue)
        request.forceToBackgroundSession()
        return request
    }

}

// MARK: - Downloading
extension ClientMessageRequestFactory {
    func downstreamRequestForEcryptedOriginalFileMessage(_ message: ZMAssetClientMessage, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard apiVersion < .v2 else { fatalError("Endpoint not availale in API v2") }
        guard let conversation = message.conversation, let identifier = conversation.remoteIdentifier else { return nil }
        let path = "/conversations/\(identifier.transportString())/otr/assets/\(message.assetId!.transportString())"

        let request = ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
        request.addContentDebugInformation("Downloading file (Asset)\n\(String(describing: message.dataSetDebugInformation))")
        request.forceToBackgroundSession()
        return request
    }
}

extension String {

    func pathWithMissingClientStrategy(strategy: MissingClientsStrategy) -> String {
        switch strategy {
        case .doNotIgnoreAnyMissingClient,
             .ignoreAllMissingClientsNotFromUsers:
            return self
        case .ignoreAllMissingClients:
            return self + "?ignore_missing=true"
        }
    }
}
