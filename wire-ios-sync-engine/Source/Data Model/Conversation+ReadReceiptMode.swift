//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

public enum ReadReceiptModeError: Error {
    case invalidOperation
    case accessDenied
    case noConversation
    case unknown

    init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "access-denied"): self = .accessDenied
        case (404, "no-conversation"): self = .noConversation
        case (400 ..< 499, _): self = .unknown
        default: return nil
        }
    }
}

public extension ZMConversation {

    /// Enable or disable read receipts in a group conversation
    func setEnableReadReceipts(
        _ enabled: Bool,
        in userSession: ZMUserSession,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let apiVersion = userSession.resolvedBackendMetadata.apiVersion else {
            return completion(.failure(ReadReceiptModeError.unknown))
        }
        guard conversationType == .group else { return  completion(.failure(ReadReceiptModeError.invalidOperation)) }
        guard let conversationId = remoteIdentifier?.transportString()
        else { return completion(.failure(ReadReceiptModeError.noConversation)) }

        let path: String
        if apiVersion >= .v8 {
            if domain == nil {
                WireLogger.conversation.warn("ZMConversation.setEnableReadReceipts: conversation.domain == nil")
            }
            guard let domain = domain ?? userSession.resolvedBackendMetadata.domain else {
                return completion(.failure(ReadReceiptModeError.unknown))
            }
            path = "/conversations/\(domain)/\(conversationId)/receipt-mode"
        } else {
            path = "/conversations/\(conversationId)/receipt-mode"
        }

        let payload = ["receipt_mode": enabled ? 1 : 0] as ZMTransportData
        let request = ZMTransportRequest(
            path: path,
            method: .put,
            payload: payload,
            apiVersion: apiVersion.rawValue
        )

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 200, let event = response.updateEvent {

                userSession.processConversationEvents([event]) {
                    userSession.managedObjectContext.performGroupedBlock {
                        completion(.success(()))
                    }
                }
            } else if response.httpStatus == 204 {
                self.hasReadReceiptsEnabled = enabled
                completion(.success(()))
            } else {
                completion(.failure(ReadReceiptModeError(response: response) ?? .unknown))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

}
