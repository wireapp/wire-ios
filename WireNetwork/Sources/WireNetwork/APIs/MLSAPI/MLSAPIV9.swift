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

final class MLSAPIV9: MLSAPIV8 {

    override var apiVersion: APIVersion { .v9 }

    override func resetMLSConversation(epoch: Int64, groupID: String) async throws {
        let parameters = MLSResetParameters(epoch: epoch, groupID: groupID)
               
        let encodedJSON: Data
        do {
            encodedJSON = try JSONEncoder.defaultEncoder.encode(parameters)
        } catch {
            assertionFailure("failed to encode body")
            throw MLSAPIError.invalidRequestBody(error)
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
                .failure(code: .badRequest, label: "mls-not-enabled", error: MLSAPIError.mlsNotEnabled)
//                .failure(code: .badRequest, label: "body", error: MLSAPIError.mlsNotEnabled)
                .failure(code: .forbidden, label: "action-denied", error: MLSAPIError.insufficientAuthorization)
                .failure(code: .conflict, decodableError: FailureResponse.self)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let failureResponse = error as? FailureResponse {
                throw MLSAPIError(
                throw MLSAPIError.mlsError(failureResponse.label, failureResponse.message)
            } else {
                throw error
            }
        }

    }
}

struct MLSResetParameters: Encodable {
    var epoch: Int64
    var groupID: String
}


