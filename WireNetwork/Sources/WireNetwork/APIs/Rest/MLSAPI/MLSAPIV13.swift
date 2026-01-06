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

final class MLSAPIV13: MLSAPIV12 {

    override var apiVersion: APIVersion { .v13 }

    override func postCommitBundle(_ bundle: CommitBundle) async throws -> [UpdateEvent] {
        let request = try URLRequestBuilder(path: "\(pathPrefix)/mls/commit-bundles")
            .withMethod(.post)
            .withAcceptType(.json)
            .withBody(bundle.transportData(), contentType: .mls)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        do {
            return try ResponseParser()
                .success(
                    code: .created,
                    type: CommitBundleResponseV5.self
                )
                .failure(
                    code: .conflict,
                    label: "mls-stale-message",
                    error: MLSAPIError.mlsStaleMessage
                )
                .failure(
                    code: .conflict,
                    label: "mls-client-mismatch",
                    error: MLSAPIError.mlsClientMismatch
                )
                .failure( // New in v13
                    code: .conflict,
                    label: "mls-group-out-of-sync",
                    decodingError: { data in
                        let payload = try JSONDecoder().decode(
                            MissingUsersPayloadV13.self,
                            from: data
                        )
                        let missingUsers = payload.missingUsers.map {
                            $0.toAPIModel()
                        }
                        return MLSAPIError.groupOutOfSync(missingUsers: Set(missingUsers))
                    }
                )
                .failure(
                    code: .badRequest,
                    label: "mls-invalid-leaf-node-index",
                    error: MLSAPIError.mlsInvalidLeafNodeIndex
                )
                .failure(
                    code: .badRequest,
                    label: "mls-invalid-leaf-node-signature",
                    error: MLSAPIError.mlsInvalidLeafNodeSignature
                )
                .failure(
                    code: .badRequest,
                    label: "mls-commit-missing-references",
                    error: MLSAPIError.mlsCommitMissingReferences
                )
                .failure(
                    code: .conflict,
                    decodableError: FailureResponseV0.self
                )
                .parse(
                    code: response.statusCode,
                    data: data
                )
        } catch {
            if let failureResponse = error as? FailureResponseV0 {
                throw MLSAPIError.mlsError(failureResponse.label, failureResponse.message)
            } else {
                throw error
            }
        }

    }

    private struct MissingUsersPayloadV13: Decodable {

        let missingUsers: [QualifiedIDV0]

        enum CodingKeys: String, CodingKey {
            case missingUsers = "missing_users"
        }

    }
}
