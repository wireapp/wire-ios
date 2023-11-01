////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

protocol MessageAPI {

    func sendProteusMessage(message: any ProteusMessage, conversationID: QualifiedID) async -> Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError>

}

extension Payload.ClientListByUserID {
    func toClientListByQualifiedUserID(domain: String) -> Payload.ClientListByQualifiedUserID {
        return [domain: self]
    }
}

extension Payload.MessageSendingStatusV0 {
    func toMessageSendingStatus(domain: String) -> Payload.MessageSendingStatus {
        Payload.MessageSendingStatus(
            time: time,
            missing: missing.toClientListByQualifiedUserID(domain: domain),
            redundant: redundant.toClientListByQualifiedUserID(domain: domain),
            deleted: deleted.toClientListByQualifiedUserID(domain: domain),
            failedToSend: [:],
            failedToConfirm: [:])
    }
}

class MessageAPIV0: MessageAPI {

    open var apiVersion: APIVersion {
        .v0
    }

    internal let httpClient: HttpClient
    private let protobufContentType = "application/x-protobuf"

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func sendProteusMessage(
        message: any ProteusMessage,
        conversationID: QualifiedID
    ) async -> Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError> {
        let path = "/" + ["conversations", conversationID.uuid.transportString(), "otr", "messages"].joined(separator: "/")

        guard let encryptedPayload = message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            return .failure(NetworkError.errorEncodingRequest)
        }

        let request = ZMTransportRequest(
            path: path,
            method: .methodPOST,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate = message.expirationDate {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard
                let messageSendingStatus = Payload.MessageSendingStatusV0(response, decoder: .defaultDecoder)
            else {
                return .failure(NetworkError.errorDecodingResponse(response))
            }
            return .failure(.missingClients(messageSendingStatus.toMessageSendingStatus(domain: ""), response))
        } else {
            let result: Swift.Result<Payload.MessageSendingStatusV0, NetworkError> = mapResponse(response)

            return result.map { payload in
                (payload.toMessageSendingStatus(domain: ""), response)
            }
        }
    }
}

func mapResponse<T: Decodable>(_ response: ZMTransportResponse) -> Swift.Result<T, NetworkError> {
    if response.result == .success {
        guard
            let value = T(response, decoder: .defaultDecoder)
        else {
            return .failure(NetworkError.errorDecodingResponse(response))
        }
        return .success(value)
    } else {
        guard
            let responseFailure = Payload.ResponseFailure(response, decoder: .defaultDecoder)
        else {
            return .failure(NetworkError.errorDecodingResponse(response))
        }
        return .failure(.invalidRequestError(responseFailure, response))
    }
}

class MessageAPIV1: MessageAPIV0 {

    private let protobufContentType = "application/x-protobuf"

    override var apiVersion: APIVersion {
        .v1
    }

    override func sendProteusMessage(
        message: any ProteusMessage,
        conversationID: QualifiedID
    ) async -> Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError> {
        let path = "/" + ["conversations", conversationID.domain, conversationID.uuid.transportString(), "proteus", "messages"].joined(separator: "/")

        guard let encryptedPayload = message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            return .failure(NetworkError.errorEncodingRequest)
        }

        let request = ZMTransportRequest(
            path: path,
            method: .methodPOST,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate = message.expirationDate {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard
                let messageSendingStatus = Payload.MessageSendingStatus(response, decoder: .defaultDecoder)
            else {
                return .failure(NetworkError.errorDecodingResponse(response))
            }
            return .failure(.missingClients(messageSendingStatus, response))
        } else {
            return mapResponse(response).map { payload in
                (payload, response)
            }
        }
    }
}

class MessageAPIV2: MessageAPIV1 {
    override var apiVersion: APIVersion {
        .v2
    }
}

class MessageAPIV3: MessageAPIV2 {
    override var apiVersion: APIVersion {
        .v3
    }
}

class MessageAPIV4: MessageAPIV3 {
    override var apiVersion: APIVersion {
        .v4
    }
}

class MessageAPIV5: MessageAPIV4 {
    override var apiVersion: APIVersion {
        .v5
    }
}
