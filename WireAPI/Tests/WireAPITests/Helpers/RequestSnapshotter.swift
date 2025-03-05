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
import SnapshotTesting
import XCTest
@testable import WireAPI
@testable import WireAPISupport

@MainActor
final class RequestSnapshotter {

    private let networkService: NetworkService
    private let apiService: APIService
    private var receivedRequests = [URLRequest]()

    init() {
        self.networkService = NetworkService(
            baseURL: URL(string: "https://www.wire.com")!,
            serverTrustValidator: ServerTrustValidator(pinnedKeys: [])
        )
        networkService.configure(with: .mockURLSession())

        let authenticationManager = MockAuthenticationManagerProtocol()
        authenticationManager.getValidAccessToken_MockValue = AccessToken(
            userID: UUID(),
            token: "a-valid-token",
            type: "Bearer",
            expirationDate: .distantFuture
        )

        self.apiService = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        URLProtocolMock.mockHandler = { request in
            self.receivedRequests.append(request)
            throw "request handling irrelevant"
        }
    }

    func verifyRequest(
        when block: (APIService, NetworkService) async throws -> Void,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) async throws {
        receivedRequests.removeAll()

        try? await block(apiService, networkService)

        guard !receivedRequests.isEmpty else {
            throw "no request to snapshot"
        }

        for (index, request) in receivedRequests.enumerated() {
            snapshotRequest(
                request,
                name: "request-\(index)",
                file: file,
                function: function,
                line: line
            )
        }
    }

    func verifyRequest(
        apiVersion: APIVersion,
        when block: (APIService, NetworkService, APIVersion) async throws -> Void,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) async throws {
        receivedRequests.removeAll()

        try? await block(apiService, networkService, apiVersion)

        guard !receivedRequests.isEmpty else {
            throw "no request to snapshot"
        }

        for (index, request) in receivedRequests.enumerated() {
            snapshotRequest(
                request,
                name: "request-\(index)-v\(apiVersion.rawValue)",
                file: file,
                function: function,
                line: line
            )
        }
    }

    private func snapshotRequest(
        _ request: URLRequest,
        name: String,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        withSnapshotTesting(record: defaultRecordMode) {
            let errorMessage = verifySnapshot(
                of: request,
                as: .curl,
                named: name,
                record: nil,
                file: file,
                testName: function,
                line: line
            )

            if let errorMessage {
                XCTFail(errorMessage, file: file, line: line)
            }
        }
    }

    private var defaultRecordMode: SnapshotTestingConfiguration.Record? {
        let ci = ProcessInfo.processInfo.environment["CI"]
        return (ci == nil || ci?.isEmpty == true) ? .missing : .never
    }

}
