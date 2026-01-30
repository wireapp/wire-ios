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

import AWSS3
import Foundation
import Smithy
import SmithyStreams
import Testing
import WireMessagingDomain

@testable import WireMessagingData
@testable import WireMessagingDomainSupport

final class NodesAPITests {

    private let smallFileURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let smallFileHandle: FileHandle
    private let s3: MockS3ClientProtocol
    private let sut: NodesAPI

    init() throws {
        let smallFile = Data(repeating: 0, count: 100)
        try smallFile.write(to: smallFileURL)

        self.s3 = MockS3ClientProtocol()
        let localStore = MockWireDriveConversationsLocalStoreProtocol()
        localStore.fetchDriveConversations_MockValue = []

        self.smallFileHandle = try FileHandle(forReadingFrom: smallFileURL)
        self.sut = NodesAPI(
            awsClient: AWSClient(
                s3: s3,
                makeStream: { ObservableStream($0, bufferingPolicy: .unbounded) }
            ),
            localStore: localStore,
            restAPI: RestAPI(
                serverURLResolver: { URL(string: "example.com")! },
                accessToken: MockAccessTokenProvider()
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
        let versionID = UUID()
        let node = WireDriveNode(uuid: UUID(), path: "node-path")
        s3.putObjectInput_MockValue = PutObjectOutput()

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node, versionID: versionID)
        _ = try await stream.collect() // Wait for upload to complete

        // Then
        let inputPutObject = try #require(s3.putObjectInput_Invocations.first)
        #expect(inputPutObject.body?.stream != nil)
        #expect(inputPutObject.bucket == "io")
        #expect(inputPutObject.key == "node-path")
        #expect(inputPutObject.metadata == [
            "Draft-Mode": "true",
            "Create-Resource-UUID": node.id.transportString(),
            "Create-Version-ID": versionID.transportString()
        ])
    }

    @Test
    func testUploadRegularUpload_whenSuccess() async throws {
        // Given
        let node = WireDriveNode(uuid: UUID(), path: "node-path")
        s3.putObjectInput_MockMethod = { input in
            let stream = try #require(input.body?.stream)
            _ = try stream.read(upToCount: 1)
            _ = try stream.read(upToCount: 1)
            _ = try stream.readToEnd()

            try await Task.sleep(nanoseconds: 100_000_000) // Pause is necessary for progress to complete emitting

            return PutObjectOutput()
        }

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node, versionID: UUID())

        // Then
        let progresses = try await stream.collect()
        #expect(progresses == [1, 2, 100])
    }

    @Test
    func testUploadRegularUpload_whenUploadFailure() async throws {
        // Given
        let node = WireDriveNode(uuid: UUID(), path: "node-path")
        s3.putObjectInput_MockMethod = { _ in
            try await Task.sleep(nanoseconds: 100_000_000) // Pause is necessary for progress to complete emitting

            throw URLError(.notConnectedToInternet)
        }

        // When
        let stream = await sut.uploadFile(path: smallFileURL, node: node, versionID: UUID())

        // Then
        await #expect(throws: URLError(.notConnectedToInternet)) {
            _ = try await stream.collect()
        }
    }

    @Test
    func testUploadRegularUpload_whenFileUnreadable() async throws {
        // Given
        let node = WireDriveNode(uuid: UUID(), path: "node-path")
        let unreadableFileURL = URL.temporaryDirectory.appendingPathComponent("unreadable-file")

        // When
        let stream = await sut.uploadFile(path: unreadableFileURL, node: node, versionID: UUID())

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
