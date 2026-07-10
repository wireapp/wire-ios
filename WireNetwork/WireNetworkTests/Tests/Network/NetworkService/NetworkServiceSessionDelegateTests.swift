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

import WireFoundationSupport
import XCTest

@testable import WireNetwork

final class NetworkServiceSessionDelegateTests: XCTestCase {

    private var webSocketStore: WebSocketStore!
    private var session: URLSession!
    private var sut: NetworkServiceSessionDelegate!
    private var mockDateProvider: CurrentDateProvidingMock!

    override func setUpWithError() throws {

        mockDateProvider = .init()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T23:59:59Z")
        webSocketStore = .init()
        session = URLSession(configuration: .mock)

        let serverTrustValidator = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(rawKey: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ],
            currentDateProvider: mockDateProvider
        )
        sut = .init(
            serverTrustValidator: serverTrustValidator,
            webSocketStore: webSocketStore
        )

    }

    override func tearDownWithError() throws {
        sut = nil
        session = nil
        webSocketStore = nil
        mockDateProvider = nil
    }

    // MARK: - URLAuthenticationChallenge

    func testUserSessionDidReceiveChallenge_whenNotServerTrustAuthenticationMethod() async throws {
        let methods = [
            NSURLAuthenticationMethodClientCertificate,
            NSURLAuthenticationMethodNegotiate,
            NSURLAuthenticationMethodNTLM,
            NSURLAuthenticationMethodHTMLForm,
            NSURLAuthenticationMethodHTTPDigest,
            NSURLAuthenticationMethodHTTPBasic,
            NSURLAuthenticationMethodDefault
        ]

        for method in methods {
            // Given
            let challenge = try Scaffolding.makeAuthenticationChallenge(
                authenticationMethod: method,
                serverTrust: .invalid
            )
            let task = session.dataTask(with: Scaffolding.getRequest)

            // When
            let result = await sut.urlSession(session, task: task, didReceive: challenge)

            // Then
            XCTAssertEqual(result.0, .performDefaultHandling)
            XCTAssertEqual(result.1, Scaffolding.makeCredential())
        }
    }

    func testUserSessionDidReceiveChallenge_whenServerTrustValid() async throws {
        let challenge = try Scaffolding.makeAuthenticationChallenge(
            authenticationMethod: NSURLAuthenticationMethodServerTrust,
            serverTrust: .wire
        )
        let task = session.dataTask(with: Scaffolding.getRequest)

        // When
        let result = await sut.urlSession(session, task: task, didReceive: challenge)

        // Then
        XCTAssertEqual(result.0, .performDefaultHandling)
        XCTAssertEqual(result.1, Scaffolding.makeCredential())
    }

    func testUserSessionDidReceiveChallenge_whenServerTrustInvalid() async throws {
        let challenge = try Scaffolding.makeAuthenticationChallenge(
            authenticationMethod: NSURLAuthenticationMethodServerTrust,
            serverTrust: .invalid
        )
        let task = session.dataTask(with: Scaffolding.getRequest)

        // When
        let result = await sut.urlSession(session, task: task, didReceive: challenge)

        // Then
        XCTAssertEqual(result.0, .cancelAuthenticationChallenge)
        XCTAssertNil(result.1)
    }

    // MARK: - WebSocket Data Race Test

    func testWebSocketsByTask_ConcurrentAccessDoesNotCrash() async throws {
        // This test tries to reproduce the crash from the production crash report
        // where concurrent access to webSocketsByTask causes memory corruption

        let iterations = 100
        guard let session, let webSocketStore, let sut else { return XCTFail() }

        // Create multiple web socket requests concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< iterations {
                // Simulate executeWebSocketRequest (writes to dictionary)
                group.addTask { [webSocketStore] in
                    do {
                        let url = try XCTUnwrap(URL(string: "https://www.example.com/websocket-\(i)"))
                        let request = URLRequest(url: url)
                        let task = session.webSocketTask(with: request)
                        let webSocket = WebSocket(connection: task)
                        await webSocketStore.store(webSocket, for: task)

                    } catch {
                        // Ignore errors - we're just testing for crashes
                    }
                }

                // Simulate delegate callback (reads/writes to dictionary)
                group.addTask { [sut, session] in
                    // Create a mock web socket task
                    let mockTask = session.webSocketTask(with: URLRequest(url: URL(string: "wss://example.com")!))

                    // Simulate the delegate callback that accesses webSocketsByTask
                    sut.urlSession(
                        session,
                        webSocketTask: mockTask,
                        didCloseWith: .normalClosure,
                        reason: nil
                    )
                }
            }
        }

        // If we get here without crashing, the implementation is now correct
    }

}

private enum Scaffolding {

    static let getRequest = try! URLRequestBuilder(path: "/foo")
        .withMethod(.get)
        .withAcceptType(.json)
        .build()

    static func makeCredential() -> URLCredential {
        URLCredential(user: "user", password: "password", persistence: .none)
    }

    static func makeAuthenticationChallenge(
        authenticationMethod: String,
        serverTrust: SecTrust
    ) throws -> URLAuthenticationChallenge {
        let protectionSpace = MockURLProtectionSpace(
            host: "prod-nginz-https.wire.com",
            port: 8080,
            protocol: nil,
            realm: nil,
            authenticationMethod: authenticationMethod
        )

        protectionSpace.mockServerTrust = serverTrust

        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: Scaffolding.makeCredential(),
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockURLAuthenticationChallengeSender()
        )
    }

}
