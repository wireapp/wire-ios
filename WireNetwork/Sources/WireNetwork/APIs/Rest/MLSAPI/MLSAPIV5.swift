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

    override func uploadKeyPackages(clientID: String, keyPackages: KeyPackageUpload) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(keyPackages.toNetworkModel())

        let path = "\(pathPrefix)/mls/key-packages/self/\(clientID)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(
                code: .created
            )
            .failure(
                code: .badRequest,
                error: MLSAPIError.invalidRequestBody
            )
            .failure(
                code: .badRequest,
                label: "mls-protocol-error",
                wrappingMessage: { MLSAPIError.mlsProtocolError(message: $0) }
            )
            .failure(
                code: .forbidden,
                label: "mls-identity-mismatch",
                wrappingMessage: { MLSAPIError.mlsIdentityMismatch(message: $0) }
            )
            .parse(
                code: response.statusCode,
                data: data
            )
    }

    override func countKeyPackages(clientID: String, ciphersuite: MLSCipherSuite) async throws -> Int {
        let path = "\(pathPrefix)/mls/key-packages/self/\(clientID)/count"
        let ciphersuiteHexString = String(format: "0x%04X", ciphersuite.toNetworkModel().rawValue)

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .withQueryItem(name: "ciphersuite", value: ciphersuiteHexString)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: CountKeyPackagesResponseV5.self)
            .failure(code: .notFound, error: MLSAPIError.clientNotFound)
            .parse(code: response.statusCode, data: data)
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

private struct CountKeyPackagesResponseV5: Decodable, ToAPIModelConvertible {

    let count: Int

    func toAPIModel() -> Int {
        count
    }

}

struct KeyPackageUploadV0: Equatable, Sendable, Encodable {

    enum CodingKeys: String, CodingKey {
        case keyPackages = "key_packages"
    }

    let keyPackages: [String]

}

extension KeyPackageUpload {

    func toNetworkModel() -> KeyPackageUploadV0 {
        KeyPackageUploadV0(
            keyPackages: keyPackages.map(\.base64EncodedData)
        )
    }

}

extension MLSCipherSuite {

    func toNetworkModel() -> MLSCipherSuiteV0 {
        switch self {
        case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
            .MLS_128_DHKEMP256_AES128GCM_SHA256_P256
        case .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
        case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448:
            .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448
        case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
            .MLS_256_DHKEMP521_AES256GCM_SHA512_P521
        case .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
            .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448
        case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
            .MLS_256_DHKEMP384_AES256GCM_SHA384_P384
        }
    }

}
