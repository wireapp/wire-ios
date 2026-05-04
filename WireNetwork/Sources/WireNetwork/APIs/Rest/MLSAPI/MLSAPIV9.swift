//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

class MLSAPIV9: MLSAPIV8 {

    override var apiVersion: APIVersion { .v9 }

    override func resetMLSConversation(epoch: UInt64, groupID: String) async throws {
        let parameters = MLSResetParameters(epoch: epoch, groupID: groupID)

        let encodedJSON: Data
        do {
            encodedJSON = try JSONEncoder.defaultEncoder.encode(parameters)
        } catch {
            assertionFailure("failed to encode body")
            throw MLSAPIError.invalidRequestBody
        }

        let request = try URLRequestBuilder(path: "\(pathPrefix)/mls/reset-conversation")
            .withMethod(.post)
            .withAcceptType(.json)
            .withBody(encodedJSON, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        do {
            return try ResponseParser()
                .success(code: .ok)
                .failure(code: .badRequest, decodableError: FailureResponseV0.self) // 400
                .failure(code: .forbidden, decodableError: FailureResponseV0.self) // 403
                .failure(code: .notFound, decodableError: FailureResponseV0.self) // 404
                .failure(code: .conflict, decodableError: FailureResponseV0.self) // 409
                .parse(code: response.statusCode, data: data)
        } catch {
            if let failureResponse = error as? FailureResponseV0 {

                switch failureResponse.label {
                case "mls-protocol-error":
                    throw MLSAPIError
                        .mlsProtocolError(message: failureResponse.message)
                case "mls-group-id-not-supported":
                    throw MLSAPIError.mlsGroupIdNotSupported(message: failureResponse.message)
                case "mls-federated-reset-not-supported":
                    throw MLSAPIError.mlsFederatedResetNotSupported(message: failureResponse.message)
                case "mls-not-enabled":
                    throw MLSAPIError.mlsNotEnabled
                case "invalid-op":
                    throw MLSAPIError.invalidOperation(message: failureResponse.message)
                case "action-denied":
                    throw MLSAPIError.actionDenied(message: failureResponse.message)
                case "access-denied":
                    throw MLSAPIError.accessDenied(message: failureResponse.message)
                case "no-conversation":
                    throw MLSAPIError.noConversation(message: failureResponse.message)
                case "mls-stale-message":
                    throw MLSAPIError.mlsStaleMessage
                case "mls-invalid-leaf-node-index":
                    throw MLSAPIError.mlsInvalidLeafNodeIndex
                case "mls-invalid-leaf-node-signature":
                    throw MLSAPIError.mlsInvalidLeafNodeSignature
                default:
                    throw MLSAPIError.mlsError(failureResponse.label, failureResponse.message)
                }
            } else {
                throw error
            }
        }

    }
}

struct MLSResetParameters: Encodable {
    var epoch: UInt64
    var groupID: String

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case epoch
    }

}
