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

class MLSAPIV5: MLSAPIV4 {

    override var apiVersion: APIVersion { .v5 }

    // MARK: Methods

    override func getBackendMLSPublicKeys() async throws -> BackendMLSPublicKeys {
        let request = try URLRequestBuilder(path: "\(pathPrefix)/mls/public-keys")
            .withMethod(.get)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: BackendMLSPublicKeysResponseV5.self)
            .failure(code: .badRequest, label: "mls-not-enabled", error: MLSAPIError.mlsNotEnabled)
            .parse(code: response.statusCode, data: data)
    }

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
                .success(code: .created, type: CommitBundleResponseV5.self)
                .failure(code: .conflict, label: "mls-stale-message", error: MLSAPIError.mlsStaleMessage)
                .failure(code: .conflict, label: "mls-client-mismatch", error: MLSAPIError.mlsClientMismatch)
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
                .failure(code: .conflict, decodableError: FailureResponseV0.self)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let failureResponse = error as? FailureResponseV0 {
                throw MLSAPIError.mlsError(failureResponse.label, failureResponse.message)
            } else {
                throw error
            }
        }

    }

}

private struct BackendMLSPublicKeysResponseV5: Decodable, ToAPIModelConvertible {

    var removal: MLSPublicKeysV0

    func toAPIModel() -> BackendMLSPublicKeys {
        .init(removal: removal.toAPIModel())
    }

}

struct CommitBundleResponseV5: Decodable, ToAPIModelConvertible {

    let time: UTCTime?
    let events: [UpdateEventDecodingProxy]

    func toAPIModel() -> [UpdateEvent] {
        events.map(\.updateEvent)
    }

}
