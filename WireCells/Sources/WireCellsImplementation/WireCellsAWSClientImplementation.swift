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
import AWSS3
package import Foundation
import SmithyIdentity
import SmithyStreams
package import WireCellsAPI

package final class WireCellsAWSClientImplementation: WireCellsAWSClient {
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

    package convenience init(credentials: WireCellsCredentials) {
        let config = try! S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(
                .init(
                    accessKey: credentials.accessToken,
                    secret: credentials.gatewaySecret
                )
            ),
            region: Constants.region,
            endpoint: credentials.serverURL.absoluteString
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

    package func download(
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

    package func upload(path: URL, node: WireCellsNodeDTO) async -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.upload(path: path, node: node) { progress in
                        continuation.yield(Int(progress))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func upload(
        path: URL,
        node: WireCellsNodeDTO,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        if fileSize > Constants.maxRegularUploadSize {
            try await uploadMultipart(path: path, node: node, onProgressUpdate: onProgressUpdate)
        } else {
            try await uploadRegular(path: path, node: node, onProgressUpdate: onProgressUpdate)
        }
    }

    private func uploadRegular(
        path: URL,
        node: WireCellsNodeDTO,
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
            metadata: node.createDraftNodeMetadata()
        )

        _ = try await s3.putObject(input: input)
    }

    private func uploadMultipart(
        path: URL,
        node: WireCellsNodeDTO,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileHandle = try FileHandle(forReadingFrom: path)
        defer { try? fileHandle.close() }

        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        let createOutput = try await s3.createMultipartUpload(
            input: .init(bucket: Constants.bucket, key: node.path, metadata: node.createDraftNodeMetadata())
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

    package func getPreSignedUrl(objectKey: String) async throws -> String {
        let expiration = TimeInterval(Constants.preSignedUrlExpiryInHours * 60 * 60)
        let input = GetObjectInput(bucket: Constants.bucket, key: objectKey)
        let signed = try await s3.presignedURLForGetObject(input: input, expiration: expiration)
        return signed.absoluteString
    }
}

private extension WireCellsNodeDTO {
    func createDraftNodeMetadata() -> [String: String] {
        [
            "Draft-Mode": "true",
            "Create-Resource-UUID": uuid.uuidString,
            "Create-Version-ID": versionId.uuidString
        ]
    }
}
