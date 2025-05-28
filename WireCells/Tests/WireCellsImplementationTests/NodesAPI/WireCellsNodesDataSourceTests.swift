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

import AWSS3
import Foundation
import Smithy
import SmithyStreams
import Testing
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

final class WireCellsNodesDataSourceTests {

    private let smallFileURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let smallFileHandle: FileHandle
    private let s3: S3ClientProtocolMock
    private let sut: WireCellsNodesDataSource

    init() throws {
        let smallFile = Data(repeating: 0, count: 100)
        try smallFile.write(to: smallFileURL)

        self.s3 = S3ClientProtocolMock()

        self.smallFileHandle = try FileHandle(forReadingFrom: smallFileURL)
        self.sut = WireCellsNodesDataSource(
            awsClient: WireCellsAWSClientImplementation(
                s3: s3,
                makeStream: { ObservableStream($0, bufferingPolicy: .unbounded) }
            ),
            restAPI: RestAPI(
                serverURL: URL(string: "example.com")!,
                accessToken: "exampleAccessToken"
            ),
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: smallFileURL)
    }

    // MARK: - Test uploadFile

    @Test
    func testUploadRegularUpload_sendsCorrectData() async throws {
        // Given
        let node = WireCellsNode(uuid: UUID(), versionID: UUID(), path: "node-path")
        s3.putObjectInputPutObjectInputPutObjectOutputReturnValue = PutObjectOutput()

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node)
        _ = try await stream.collect() // Wait for upload to complete

        // Then
        let inputPutObject = try #require(s3.putObjectInputPutObjectInputPutObjectOutputReceivedInput)
        #expect(inputPutObject.body?.stream != nil)
        #expect(inputPutObject.bucket == "io")
        #expect(inputPutObject.key == "node-path")
        #expect(inputPutObject.metadata == [
            "Draft-Mode": "true",
            "Create-Resource-UUID": node.id.uuid.uuidString,
            "Create-Version-ID": node.id.versionID.uuidString
        ])
    }

    @Test
    func testUploadRegularUpload_whenSuccess() async throws {
        // Given
        let node = WireCellsNode(uuid: UUID(), versionID: UUID(), path: "node-path")
        s3.putObjectInputPutObjectInputPutObjectOutputClosure = { input in
            let stream = try #require(input.body?.stream)
            _ = try stream.read(upToCount: 1)
            _ = try stream.read(upToCount: 1)
            _ = try stream.readToEnd()

            try await Task.sleep(nanoseconds: 100_000_000) // Pause is necessary for progress to complete emitting

            return PutObjectOutput()
        }

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node)

        // Then
        let progresses = try await stream.collect()
        #expect(progresses == [1, 2, 100])
    }

    @Test
    func testUploadRegularUpload_whenUploadFailure() async throws {
        // Given
        let node = WireCellsNode(uuid: UUID(), versionID: UUID(), path: "node-path")
        s3.putObjectInputPutObjectInputPutObjectOutputClosure = { _ in
            try await Task.sleep(nanoseconds: 100_000_000) // Pause is necessary for progress to complete emitting

            throw URLError(.notConnectedToInternet)
        }

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node)

        // Then
        await #expect(throws: URLError(.notConnectedToInternet)) {
            _ = try await stream.collect()
        }
    }

    @Test
    func testUploadRegularUpload_whenFileUnreadable() async throws {
        // Given
        let node = WireCellsNode(uuid: UUID(), versionID: UUID(), path: "node-path")
        let unreadableFileURL = URL.temporaryDirectory.appendingPathComponent("unreadable-file")

        // When
        let stream = await sut.uploadFile(path: unreadableFileURL, node: node)

        // Then
        await #expect(throws: (any Error).self) {
            _ = try await stream.collect()
        }
    }
}

private extension ByteStream {
    var stream: (any Smithy.Stream)? {
        switch self {
        case let .stream(stream):
            stream
        default:
            nil
        }
    }
}

private extension AsyncSequence {
    func collect() async throws -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}
