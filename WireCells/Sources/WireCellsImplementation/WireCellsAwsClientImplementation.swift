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


package import Foundation
import AWSS3
import AWSClientRuntime
import SmithyIdentity
package import WireCellsAPI

package final class WireCellsAwsClientImplementation: WireCellsAwsClient {
    private enum Constants {
        static let bucket = "io"
        static let multipartChunkSize = 10 * 1024 * 1024
        static let maxRegularUploadSize = 100 * 1024 * 1024
        static let preSignedUrlExpiryInHours = 24
        static let readAsyncChunkSize = 5 * 1024 * 1024
        static let region = "us-east-1"
    }

    private let s3: S3Client

    package init(credentials: WireCellsCredentials) {
        let config = try! S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(
                .init(
                    accessKey: credentials.accessToken,
                    secret: credentials.gatewaySecret
                )
            ),
            region: Constants.region,
            endpoint: credentials.serverUrl.absoluteString
        )
        self.s3 = S3Client(config: config)
    }

    // TODO: Report progress update
    package func download(
        objectKey: String,
        to fileHandle: FileHandle,
        onProgressUpdate: @escaping (UInt64) -> Void
    ) async throws {
        let input = GetObjectInput(bucket: Constants.bucket, key: objectKey)
        let response = try await s3.getObject(input: input)
        guard let body = response.body else {
            throw WireCellsAwsClientError.downloadErrorNoData
        }

        switch body {
        case .data:
            guard let data = try await body.readData() else {
                throw WireCellsAwsClientError.downloadError
            }

            // Write the `Data` to the file.

            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                throw WireCellsAwsClientError.writeError
            }
            break

        case .stream(let stream):
            
            while let chunk = try await stream.readAsync(upToCount: Constants.readAsyncChunkSize) {
                // TODO: Report progress update
                // Write the chunk to the destination file.
                do {
                    try fileHandle.write(contentsOf: chunk)
                } catch {
                    throw WireCellsAwsClientError.writeError
                }
            }

            break
        default:
            throw WireCellsAwsClientError.downloadErrorUnknownObject
        }
    }

    package func upload(
        path: URL,
        node: WireCellsCellNodeDTO,
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
        node: WireCellsCellNodeDTO,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileHandle = try FileHandle(forReadingFrom: path)
        defer { try? fileHandle.close() }

        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        let metadata = node.createDraftNodeMetadata()

        let input = PutObjectInput(
            body: .from(fileHandle: fileHandle),
            bucket: Constants.bucket,
            key: node.path,
            metadata: metadata
        )

        _ = try await s3.putObject(input: input)
        onProgressUpdate(UInt64(fileSize))
    }

    private func uploadMultipart(
        path: URL,
        node: WireCellsCellNodeDTO,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        let fileHandle = try FileHandle(forReadingFrom: path)
        defer { try? fileHandle.close() }

        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as! Int64

        let createOutput = try await s3.createMultipartUpload(
            input: .init(bucket: Constants.bucket, key: node.path, metadata: node.createDraftNodeMetadata())
        )
        guard let uploadId = createOutput.uploadId else {
            throw WireCellsAwsClientError.missingUploadID
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

    // TODO: Implement this method
    package func getPreSignedUrl(objectKey: String) async throws -> String {
//        let signer = S3Presigner(client: s3)
//        let input = GetObjectInput(bucket: Constants.bucket, key: objectKey)
//        let signed = try await signer.presignGetObject(input: input, expires: .hours(Constants.preSignedUrlExpiryInHours))
//        return signed.url.absoluteString
        fatalError("Not implemented")
    }
}

private extension WireCellsCellNodeDTO {
    func createDraftNodeMetadata() -> [String: String] {
        [
            "X-Metadata-Draft-Mode": "true",
            "X-Metadata-Create-Resource-UUID": uuid.uuidString,
            "X-Metadata-Create-Version-ID": versionId.uuidString
        ]
    }
}
