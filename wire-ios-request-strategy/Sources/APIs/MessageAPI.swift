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

// sourcery: AutoMockable
public protocol MessageAPI {

    func broadcastProteusMessage(message: any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse)

    func sendProteusMessage(message: any ProteusMessage, conversationID: QualifiedID) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse)

    func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse)

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

    func broadcastProteusMessage(message: any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/broadcast/otr/messages"

        // FIXME: [WPB-5499] move encryption out of the API - [jacob]
        guard let encryptedPayload = await
            message.encryptForTransport()
        else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard
                let messageSendingStatus = Payload.MessageSendingStatusV0(response, decoder: .defaultDecoder)
            else {
                throw NetworkError.errorDecodingResponse(response)
            }
            throw NetworkError.missingClients(messageSendingStatus.toMessageSendingStatus(domain: ""), response)
        } else {
            let payload: Payload.MessageSendingStatusV0 = try mapResponse(response)
            return (payload.toMessageSendingStatus(domain: ""), response)
        }
    }

    func sendProteusMessage(
        message: any ProteusMessage,
        conversationID: QualifiedID
    ) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/" + ["conversations", conversationID.uuid.transportString(), "otr", "messages"].joined(separator: "/")

        // FIXME: [WPB-5499] move encryption out of the API - [jacob]
        guard let encryptedPayload = await message.encryptForTransport()
        else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate = (await message.context.perform {
            message.expirationDate
        }) {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard
                let messageSendingStatus = Payload.MessageSendingStatusV0(response, decoder: .defaultDecoder)
            else {
                throw NetworkError.errorDecodingResponse(response)
            }
            throw NetworkError.missingClients(messageSendingStatus.toMessageSendingStatus(domain: ""), response)
        } else {
            let payload: Payload.MessageSendingStatusV0 = try mapResponse(response)
            return (payload.toMessageSendingStatus(domain: ""), response)
        }
    }

    func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse) {
        throw NetworkError.endpointNotAvailable
    }
}

func mapResponse<T: Decodable>(_ response: ZMTransportResponse) throws -> T {
    if response.result == .success {
        return try mapSuccessResponse(response)
    } else {
        throw mapFailureResponse(response)
    }
}

func mapSuccessResponse<T: Decodable>(_ response: ZMTransportResponse) throws -> T {
    guard
        let value = T(response, decoder: .defaultDecoder)
    else {
        throw NetworkError.errorDecodingResponse(response)
    }
    return value
}

func mapFailureResponse(_ response: ZMTransportResponse) -> Error {
    guard
        let responseFailure = Payload.ResponseFailure(response, decoder: .defaultDecoder)
    else {
        return NetworkError.errorDecodingResponse(response)
    }
    return NetworkError.invalidRequestError(responseFailure, response)
}

class MessageAPIV1: MessageAPIV0 {

    private let protobufContentType = "application/x-protobuf"

    override var apiVersion: APIVersion {
        .v1
    }

    override func broadcastProteusMessage(message: any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/broadcast/proteus/messages"

        guard let encryptedPayload = await message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard let messageSendingStatus = Payload.MessageSendingStatusV1(
                response,
                decoder: .defaultDecoder
            ) else {
                throw NetworkError.errorDecodingResponse(response)
            }

            throw NetworkError.missingClients(messageSendingStatus.toAPIModel(), response)

        } else {
            let payload: Payload.MessageSendingStatusV1 = try mapResponse(response)
            return (payload.toAPIModel(), response)
        }
    }

    override func sendProteusMessage(
        message: any ProteusMessage,
        conversationID: QualifiedID
    ) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/" + ["conversations", conversationID.domain, conversationID.uuid.transportString(), "proteus", "messages"].joined(separator: "/")

        guard let encryptedPayload = await message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate = await message.context.perform({ message.expirationDate }) {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            guard let messageSendingStatus = Payload.MessageSendingStatusV1(
                response,
                decoder: .defaultDecoder
            ) else {
                throw NetworkError.errorDecodingResponse(response)
            }

            throw NetworkError.missingClients(messageSendingStatus.toAPIModel(), response)

        } else {
            let payload: Payload.MessageSendingStatusV1 = try mapResponse(response)
            return (payload.toAPIModel(), response)
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

    private let protobufContentType = "application/x-protobuf"

    override func broadcastProteusMessage(message: any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/broadcast/proteus/messages"

        guard let encryptedPayload = await message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            // New V4 payload
            guard let messageSendingStatus = Payload.MessageSendingStatusV4(
                response,
                decoder: .defaultDecoder
            ) else {
                throw NetworkError.errorDecodingResponse(response)
            }

            throw NetworkError.missingClients(messageSendingStatus.toAPIModel(), response)

        } else {
            let payload: Payload.MessageSendingStatusV4 = try mapResponse(response)
            return (payload.toAPIModel(), response)
        }
    }

    override func sendProteusMessage(
        message: any ProteusMessage,
        conversationID: QualifiedID
    ) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        let path = "/" + ["conversations", conversationID.domain, conversationID.uuid.transportString(), "proteus", "messages"].joined(separator: "/")

        guard let encryptedPayload = await message.encryptForTransportQualified() else {
            WireLogger.messaging.error("failed to encrypt message for transport")
            throw NetworkError.errorEncodingRequest
        }

        let request = ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: encryptedPayload.data,
            type: protobufContentType,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate = await message.context.perform({ message.expirationDate }) {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)

        if response.httpStatus == 412 {
            // New V4 payload
            guard let messageSendingStatus = Payload.MessageSendingStatusV4(
                response,
                decoder: .defaultDecoder
            ) else {
                throw NetworkError.errorDecodingResponse(response)
            }

            throw NetworkError.missingClients(messageSendingStatus.toAPIModel(), response)

        } else {
            let payload: Payload.MessageSendingStatusV4 = try mapResponse(response)
            return (payload.toAPIModel(), response)
        }
    }
}

class MessageAPIV5: MessageAPIV4 {
    override var apiVersion: APIVersion {
        .v5
    }

    override func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse) {

        let request = ZMTransportRequest(
            path: "/mls/messages",
            method: .post,
            binaryData: encryptedMessage,
            type: "message/mls",
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )

        if let expirationDate {
            request.expire(at: expirationDate)
        }

        let response = await httpClient.send(request)
        let payload: Payload.MLSMessageSendingStatus = try mapResponse(response)

        return (payload, response)
    }
}

class MessageAPIV6: MessageAPIV5 {
    override var apiVersion: APIVersion {
        .v6
    }
}
