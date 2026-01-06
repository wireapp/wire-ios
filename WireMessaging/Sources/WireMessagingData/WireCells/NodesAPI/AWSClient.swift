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

import AWSClientRuntime
package import AWSS3
package import Foundation
import Smithy
import SmithyHTTPAPI
import SmithyIdentity
import SmithyStreams
import WireLogging
import WireMessagingDomain

// sourcery: AutoMockable
package protocol S3ClientProtocol: Sendable {

    func getObject(input: GetObjectInput) async throws -> GetObjectOutput
    func putObject(input: PutObjectInput) async throws -> PutObjectOutput
    func uploadPart(input: UploadPartInput) async throws -> UploadPartOutput
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutput
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutput
    func presignedURLForGetObject(input: GetObjectInput, expiration: Foundation.TimeInterval) async throws -> URL

}

extension S3Client: S3ClientProtocol, @unchecked @retroactive Sendable {}

package enum WireCellsAWSClientError: Error {
    case downloadError
    case downloadErrorNoData
    case downloadErrorUnknownObject
    case missingUploadID
    case noContent
    case uploadError
    case writeError
}

final class AWSClient: Sendable {
    private enum Constants {
        static let bucket = "io"
        static let multipartChunkSize = 10 * 1024 * 1024
        static let maxRegularUploadSize = 100 * 1024 * 1024
        static let preSignedUrlExpiryInHours = 24
        static let readAsyncChunkSize = 5 * 1024 * 1024
        static let region = "us-east-1"
    }

    private let s3: any S3ClientProtocol
    private let makeStream: @Sendable (FileStream) -> ObservableStream

    convenience init(
        serverURLResolver: @escaping @Sendable () throws -> URL,
        accessToken: any AccessTokenProvider
    ) {
        let config = try! S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: CredentialIdentityResolver(accessTokenProvider: accessToken),
            region: Constants.region,
            endpointResolver: AWSEndpointResolver(
                serverURLResolver: serverURLResolver,
                bucket: Constants.bucket
            )
        )
        self.init(s3: S3Client(config: config))
    }

    init(
        s3: any S3ClientProtocol,
        makeStream: @Sendable @escaping (FileStream) -> ObservableStream = { ObservableStream($0) }
    ) {
        self.s3 = s3
        self.makeStream = makeStream
    }

    func download(
        objectKey: String,
        to fileHandle: FileHandle,
        onProgressUpdate: @escaping (UInt64) -> Void
    ) async throws {
        let input = GetObjectInput(bucket: Constants.bucket, key: objectKey)
        let response = try await s3.getObject(input: input)
        guard let body = response.body else {
            throw WireCellsAWSClientError.downloadErrorNoData
        }

        switch body {
        case .data:
            guard let data = try await body.readData() else {
                throw WireCellsAWSClientError.downloadError
            }

            // Write the `Data` to the file.

            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                throw WireCellsAWSClientError.writeError
            }

            onProgressUpdate(UInt64(data.count))

        case let .stream(stream):

            var  bytesRead: UInt64 = 0
            while let chunk = try await stream.readAsync(upToCount: Constants.readAsyncChunkSize) {

                // Write the chunk to the destination file.
                do {
                    try fileHandle.write(contentsOf: chunk)
                } catch {
                    throw WireCellsAWSClientError.writeError
                }

                bytesRead += UInt64(chunk.count)
                onProgressUpdate(bytesRead)
            }

        default:
            throw WireCellsAWSClientError.downloadErrorUnknownObject
        }
    }

    func upload(
        path: URL,
        node: WireCellsNodeNetworkModel,
        versionID: UUID
    ) async -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.upload(path: path, node: node, versionID: versionID) { progress in
                        continuation.yield(Int(progress))
                    }
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func upload(
        path: URL,
        node: WireCellsNodeNetworkModel,
        versionID: UUID,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        if fileSize > Constants.maxRegularUploadSize {
            // FIXME: [WPB-18598] Use multipart upload when working
            try await uploadRegular(path: path, node: node, versionID: versionID, onProgressUpdate: onProgressUpdate)
        } else {
            try await uploadRegular(path: path, node: node, versionID: versionID, onProgressUpdate: onProgressUpdate)
        }
    }

    private func uploadRegular(
        path: URL,
        node: WireCellsNodeNetworkModel,
        versionID: UUID,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileStream = FileStream(fileHandle: try FileHandle(forReadingFrom: path))
        let stream = makeStream(fileStream)

        let progressTask = Task {
            for await progress in stream.readProgress {
                onProgressUpdate(UInt64(progress))
            }
        }
        defer { progressTask.cancel() }

        let input = PutObjectInput(
            body: .stream(stream),
            bucket: Constants.bucket,
            key: node.path,
            metadata: node.createDraftNodeMetadata(versionID: versionID)
        )

        try await withTaskCancellationHandler {
            _ = try await s3.putObject(input: input)
        } onCancel: {
            // TODO: [WPB-18574] AWS SDK doesn't support cancelling in flight requests. Find a work around.
            WireLogger.wireCells.info("Cancelling upload for node: \(node.path)")
        }
    }

    private func uploadMultipart(
        path: URL,
        node: WireCellsNodeNetworkModel,
        versionID: UUID,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileHandle = try FileHandle(forReadingFrom: path)
        defer { try? fileHandle.close() }

        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        let createOutput = try await s3.createMultipartUpload(
            input: .init(
                bucket: Constants.bucket,
                key: node.path,
                metadata: node.createDraftNodeMetadata(versionID: versionID)
            )
        )
        guard let uploadId = createOutput.uploadId else {
            throw WireCellsAWSClientError.missingUploadID
        }

        var completedParts: [S3ClientTypes.CompletedPart] = []
        var position: UInt64 = 0
        var partNumber = 1
        var totalUploaded: UInt64 = 0

        while position < fileSize {
            try fileHandle.seek(toOffset: position)
            let contentLength = min(UInt64(fileSize) - position, UInt64(Constants.multipartChunkSize))

            let uploadPartOutput = try await s3.uploadPart(input: .init(
                body: .from(fileHandle: fileHandle),
                bucket: Constants.bucket,
                contentLength: Int(contentLength),
                key: node.path,
                partNumber: partNumber,
                uploadId: uploadId
            ))

            if let etag = uploadPartOutput.eTag {
                completedParts.append(.init(eTag: etag, partNumber: partNumber))
            }

            totalUploaded += contentLength
            onProgressUpdate(totalUploaded)
            position += contentLength
            partNumber += 1
        }

        _ = try await s3.completeMultipartUpload(
            input: .init(
                bucket: Constants.bucket,
                key: node.path,
                multipartUpload: .init(parts: completedParts),
                uploadId: uploadId
            )
        )
    }

    func getPreSignedUrl(objectKey: String) async throws -> String {
        let expiration = TimeInterval(Constants.preSignedUrlExpiryInHours * 60 * 60)
        let input = GetObjectInput(bucket: Constants.bucket, key: objectKey)
        let signed = try await s3.presignedURLForGetObject(input: input, expiration: expiration)
        return signed.absoluteString
    }
}

private extension WireCellsNodeNetworkModel {
    func createDraftNodeMetadata(versionID: UUID) -> [String: String] {
        [
            "Draft-Mode": "true",
            "Create-Resource-UUID": uuid.transportString(),
            "Create-Version-ID": versionID.transportString()
        ]
    }
}

private struct AWSEndpointResolver: EndpointResolver {
    let serverURLResolver: @Sendable () throws -> URL
    let bucket: String

    init(
        serverURLResolver: @escaping @Sendable () throws -> URL,
        bucket: String
    ) {
        self.serverURLResolver = serverURLResolver
        self.bucket = bucket
    }

    func resolve(params: AWSS3.EndpointParams) throws -> SmithyHTTPAPI.Endpoint {
        let serverURL = try serverURLResolver().appendingPathComponent("/\(bucket)")
        return try SmithyHTTPAPI.Endpoint(urlString: serverURL.absoluteString)
    }
}

private struct CredentialIdentityResolver: AWSCredentialIdentityResolver {

    let accessTokenProvider: any AccessTokenProvider

    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        let accessToken = try await accessTokenProvider.accessToken()

        return AWSCredentialIdentity(
            accessKey: accessToken.token,
            secret: "gatewaysecret", // This is not used and is safe to commit.
            expiration: accessToken.expirationDate
        )
    }

}
