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

import XCTest

@testable import Wire

@MainActor
final class KMPPlatformServicesTests: XCTestCase {

    func testNavigationEffectDispatcherForwardsTypedEffects() {
        // GIVEN
        var dispatchedEffects = [TestNavigationEffect]()
        let sut = AnyKMPNavigationEffectDispatcher<TestNavigationEffect> {
            dispatchedEffects.append($0)
        }

        // WHEN
        sut.dispatch(.showConversation(id: "conversation-1"))
        sut.dispatch(.close)

        // THEN
        XCTAssertEqual(dispatchedEffects, [.showConversation(id: "conversation-1"), .close])
    }

    func testSessionIdentityProviderExposesBoundaryWithoutLegacyTypes() {
        // GIVEN
        let identity = KMPSessionIdentity(
            account: KMPAccountIdentity(
                userID: "user-1",
                domain: "wire.example",
                clientID: "client-1",
                teamID: "team-1"
            ),
            sessionID: "session-1"
        )
        let sut = AnyKMPSessionIdentityProvider {
            identity
        }

        // WHEN / THEN
        XCTAssertEqual(sut.currentSessionIdentity, identity)
    }

    func testStoragePathProviderReceivesStructuredRequests() throws {
        // GIVEN
        let expectedURL = URL(fileURLWithPath: "/tmp/wire/kmp/account/user-1")
        let expectedRequest = KMPStoragePathRequest(
            namespace: .account(KMPAccountIdentity(userID: "user-1")),
            purpose: .applicationSupport,
            component: "kalium"
        )
        let sut = AnyKMPStoragePathProvider { request in
            XCTAssertEqual(request, expectedRequest)
            return expectedURL
        }

        // WHEN
        let url = try sut.url(for: expectedRequest)

        // THEN
        XCTAssertEqual(url, expectedURL)
    }

    func testLoggerForwardsLevelMessageAndContext() {
        // GIVEN
        let context = KMPLogContext(
            category: "kmp-view-model",
            metadata: ["screen": "conversation-list"]
        )
        var logEntries = [TestLogEntry]()
        var messageEvaluationCount = 0
        let sut = AnyKMPLogger { level, message, context, _, _, line in
            logEntries.append(
                TestLogEntry(
                    level: level,
                    message: message,
                    context: context,
                    line: line
                )
            )
        }

        // WHEN
        sut.info(
            makeMessage(evaluationCount: &messageEvaluationCount),
            context: context,
            file: "KMPPlatformServicesTests.swift",
            function: "testLoggerForwardsLevelMessageAndContext()",
            line: 42
        )

        // THEN
        XCTAssertEqual(messageEvaluationCount, 1)
        XCTAssertEqual(
            logEntries,
            [
                TestLogEntry(
                    level: .info,
                    message: "KMP message",
                    context: context,
                    line: 42
                )
            ]
        )
    }

    func testPlatformServicesGroupsIndependentContracts() throws {
        // GIVEN
        var dispatchedEffects = [TestNavigationEffect]()
        var logEntries = [TestLogEntry]()
        let identity = KMPSessionIdentity(account: KMPAccountIdentity(userID: "user-1"))
        let storageURL = URL(fileURLWithPath: "/tmp/wire/kmp/shared")
        let sut = KMPPlatformServices(
            navigationEffectDispatcher: AnyKMPNavigationEffectDispatcher<TestNavigationEffect> {
                dispatchedEffects.append($0)
            },
            sessionIdentityProvider: AnyKMPSessionIdentityProvider {
                identity
            },
            storagePathProvider: AnyKMPStoragePathProvider { _ in
                storageURL
            },
            logger: AnyKMPLogger { level, message, context, _, _, line in
                logEntries.append(
                    TestLogEntry(
                        level: level,
                        message: message,
                        context: context,
                        line: line
                    )
                )
            }
        )

        // WHEN
        sut.navigationEffectDispatcher.dispatch(.close)
        let resolvedIdentity = sut.sessionIdentityProvider.currentSessionIdentity
        let resolvedURL = try sut.storagePathProvider.url(
            for: KMPStoragePathRequest(namespace: .shared, purpose: .cache)
        )
        sut.logger.warning(
            "warning",
            context: KMPLogContext(category: "kmp"),
            file: "KMPPlatformServicesTests.swift",
            function: "testPlatformServicesGroupsIndependentContracts()",
            line: 99
        )

        // THEN
        XCTAssertEqual(dispatchedEffects, [.close])
        XCTAssertEqual(resolvedIdentity, identity)
        XCTAssertEqual(resolvedURL, storageURL)
        XCTAssertEqual(logEntries.first?.level, .warning)
    }

    private func makeMessage(evaluationCount: inout Int) -> String {
        evaluationCount += 1
        return "KMP message"
    }
}

// MARK: - Test Types

private enum TestNavigationEffect: Equatable {
    case showConversation(id: String)
    case close
}

private struct TestLogEntry: Equatable {
    let level: KMPLogLevel
    let message: String
    let context: KMPLogContext
    let line: UInt
}
