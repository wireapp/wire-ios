//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

extension MLSMessageSync {

    class Transcoder<Message: MLSMessage>: EntityTranscoder {

        // MARK: - Types

        typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

        // MARK: - Properties

        let context: NSManagedObjectContext
        var onRequestScheduledHandler: OnRequestScheduledHandler?

        // MARK: - Life cycle {

        init(context: NSManagedObjectContext) {
            self.context = context
        }

        // MARK: - Request generation

        func request(forEntity entity: Message, apiVersion: APIVersion) -> ZMTransportRequest? {
            switch apiVersion {
            case .v0, .v1:
                Logging.mls.warn("can't send mls message on api version: \(apiVersion.rawValue)")
                return nil

            case .v2, .v3, .v4:
                return internalRequest(for: entity, apiVersion: apiVersion)
            }
        }

        private func internalRequest(for message: Message, apiVersion: APIVersion) -> ZMTransportRequest? {
            guard let encryptedMessage = encryptMessage(message) else {
                return nil
            }

            let request = ZMTransportRequest(
                path: "/mls/messages",
                method: .methodPOST,
                binaryData: encryptedMessage,
                type: "message/mls",
                contentDisposition: nil,
                apiVersion: apiVersion.rawValue
            )

            if let expirationDate = message.expirationDate {
                request.expire(at: expirationDate)
            }

            onRequestScheduledHandler?(message, request)

            return request
        }

        private func encryptMessage(_ message: Message) -> Data? {
            guard
                let conversation = message.conversation,
                conversation.messageProtocol == .mls
            else {
                Logging.mls.warn("failed to encrypt message: it doesn't belong to an mls conversation.")
                return nil
            }

            guard let groupID = conversation.mlsGroupID else {
                Logging.mls.warn("failed to encrypt message: group id is missing.")
                return nil
            }

            guard let mlsService = context.mlsService else {
                Logging.mls.warn("failed to encrypt message: mlsService is missing.")
                return nil
            }

            do {
                return try message.encryptForTransport { messageData in
                    let encryptedBytes = try mlsService.encrypt(message: messageData.bytes, for: groupID)
                    return encryptedBytes.data
                }
            } catch let error {
                Logging.mls.warn("failed to encrypt message: \(String(describing: error))")
                return nil
            }
        }

        // MARK: - Response handling

        func request(
            forEntity entity: Message,
            didCompleteWithResponse response: ZMTransportResponse
        ) {
            guard let apiVersion = APIVersion(rawValue: response.apiVersion) else { return }

            switch apiVersion {
            case .v0, .v1:
                return

            case .v2, .v3:
                v2processResponse(response, for: entity)

            case .v4:
                v4processResponse(response, for: entity)
            }
        }

        private func v2processResponse(
            _ response: ZMTransportResponse,
            for entity: Message
        ) {
            guard response.result == .success else {
                Logging.mls.warn("failed to send mls message. Response: \(response)")
                return
            }

            entity.delivered(with: response)
        }

        private func v4processResponse(
            _ response: ZMTransportResponse,
            for entity: Message
        ) {
            guard response.result == .success else {
                Logging.mls.warn("failed to send mls message. Response: \(response)")
                return
            }

            let payload = Payload.MLSMessageSendingStatus(response, decoder: .defaultDecoder)
            payload?.updateFailedRecipients(for: entity)
            entity.delivered(with: response)
        }

        func shouldTryToResend(
            entity: Entity,
            afterFailureWithResponse response: ZMTransportResponse
        ) -> Bool {
            switch response.httpStatus {
            case 533:
                guard
                    let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder),
                    let data = payload.data
                else {
                    return false
                }

                switch data.type {
                case .federation:
                    payload.updateExpirationReason(for: entity, with: .federationRemoteError)
                case .unknown:
                    payload.updateExpirationReason(for: entity, with: .unknown)
                }

                return false
            default:
                return false
            }
        }

    }

}
