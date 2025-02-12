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
@preconcurrency import AWSS3
import AWSSDKIdentity
@preconcurrency import CellsSDK
import ClientRuntime
import Foundation
import Smithy
import WireCellsAPI

package class WireCellsServiceImplementation: WireCellsService {

    private enum Constants {
        static let awsSecret = "gatewaysecret"
        static let s3Bucket = "io"
        static let s3EndpointPath = "io"
        static let s3Region = "us-east-1"
        static let s3SigningRegion = "us-east-1"
        static let wireCellsEndpointPath = "/a"
    }

    private let cellsApiConfig: CellsSDKAPIConfiguration
    private let rootPath: URL
    private let s3Client: S3Client
    private let secretKey: String

    package init(endpointURL: URL, rootPath: URL, secretKey: String) throws(WireCellsServiceInitError) {
        self.cellsApiConfig = CellsSDKAPIConfiguration(
            basePath: endpointURL.appendingPathComponent(Constants.wireCellsEndpointPath).absoluteString,
            customHeaders: ["Authorization": "Bearer " + secretKey]
        )
        self.rootPath = rootPath
        self.secretKey = secretKey

        // Create the S3 client
        do {
            let identity = try StaticAWSCredentialIdentityResolver(AWSCredentialIdentity(
                accessKey: secretKey,
                secret: "gatewaysecret"
            ))

            let s3ClientConfiguration = try S3Client.S3ClientConfiguration()
            s3ClientConfiguration.region = Constants.s3Region
            s3ClientConfiguration.signingRegion = Constants.s3SigningRegion
            s3ClientConfiguration.forcePathStyle = true
            s3ClientConfiguration.endpoint = endpointURL.appendingPathComponent(Constants.s3EndpointPath).absoluteString

            s3ClientConfiguration.awsCredentialIdentityResolver = identity

            self.s3Client = S3Client(config: s3ClientConfiguration)
        } catch {
            throw .failedToInitializeS3Client
        }
    }

    package func uploadFiles(_ filesUploadInfo: [WireCellsFileUploadInfo]) -> AsyncStream<WireCellsFileUploadProgress> {

        let rootPath = rootPath
        let s3Client = s3Client

        return AsyncStream { continuation in
            Task {
                await withTaskGroup(of: WireCellsFileUploadProgress.self) { group in
                    for fileUploadInfo in filesUploadInfo {
                        group.addTask {
                            do {
                                let path = rootPath.appendingPathComponent(fileUploadInfo.uploadPath)
                                let input = PutObjectInput(
                                    body: ByteStream.data(fileUploadInfo.data),
                                    key: path.absoluteString
                                )
                                _ = try await s3Client.putObject(input: input)

                                let uploadedFile = WireCellsUploadedFile(path: path)
                                return .success(file: fileUploadInfo, uploadedFile: uploadedFile)
                            } catch {
                                return .failure(file: fileUploadInfo, error: .genericError(error))
                            }
                        }
                    }

                    for await result in group {
                        continuation.yield(result)
                    }
                    continuation.finish()
                }
            }
        }
    }

    package func listFiles() async throws(WireCellsFileQueryError) -> [RestNode] {
        try await _listFiles(atPath: rootPath.appendingPathComponent("/*").absoluteString)
    }

    package func listFiles(atPath path: String) async throws(WireCellsFileQueryError) -> [RestNode] {
        try await _listFiles(atPath: rootPath.appendingPathComponent(path).appendingPathComponent("/*").absoluteString)
    }

    private func _listFiles(atPath path: String) async throws(WireCellsFileQueryError) -> [RestNode] {
        let request = RestLookupRequest()
        let locator = RestNodeLocator(path: path)
        request.locators = RestNodeLocators(many: [locator])
        let requestBuilder = NodeServiceAPI.lookupWithRequestBuilder(body: request, apiConfiguration: cellsApiConfig)

        do {
            let response: Response<RestNodeCollection> = try await requestBuilder.execute()
            return response.body.nodes
        } catch {
            throw .genericError(error)
        }
    }
}
