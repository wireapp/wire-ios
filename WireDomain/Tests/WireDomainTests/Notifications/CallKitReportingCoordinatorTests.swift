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

import WireTestingPackage
import XCTest
@testable import WireDomain

final class CallKitReportingCoordinatorTests: XCTestCase {

    private var callingService: MockAVSCallingEventService!
    private var callKitReporter: MockCallKitReporter!
    private var sut: CallKitReportingCoordinator!

    override func setUp() async throws {
        callingService = MockAVSCallingEventService()
        callKitReporter = MockCallKitReporter()
        sut = CallKitReportingCoordinator(
            accountID: .mockID1,
            avsService: callingService,
            callKitReporter: callKitReporter
        )
    }

    override func tearDown() async throws {
        callingService = nil
        callKitReporter = nil
        sut = nil
    }

    // MARK: - waitForCompletion

    func test_waitForCompletion_waitsForPendingReport() async throws {
        // Given
        callKitReporter.setShouldSuspendReports(true)

        // When
        callingService.onIncomingCall?(Scaffolding.conversationID, Scaffolding.userID, true, false)
        await callKitReporter.waitForPayloadCount(1)

        let completionProbe = CompletionProbe()
        let task = Task {
            try await self.sut.waitForCompletion()
            await completionProbe.complete()
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        let didCompleteBeforeReportFinished = await completionProbe.isCompleted

        // Then
        XCTAssertFalse(didCompleteBeforeReportFinished)

        callKitReporter.resumeReports()
        try await task.value
        let didCompleteAfterReportFinished = await completionProbe.isCompleted
        XCTAssertTrue(didCompleteAfterReportFinished)
    }

    // MARK: - onCallClosed

    func test_onCallClosed_withoutPriorIncoming_doesNotReportCallKitPayload() async throws {
        // When
        callingService.onCallClosed?(.canceled, Scaffolding.conversationID)
        try await sut.waitForCompletion()

        // Then
        XCTAssertTrue(callKitReporter.payloads.isEmpty)
    }

    func test_onCallClosed_afterRingingIncoming_reportsStopRingingPayload() async throws {
        // Given
        callingService.onIncomingCall?(Scaffolding.conversationID, Scaffolding.userID, true, false)
        try await sut.waitForCompletion()

        // When
        callingService.onCallClosed?(.canceled, Scaffolding.conversationID)
        try await sut.waitForCompletion()

        // Then
        let payloads = callKitReporter.payloads
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads[1]["accountID"] as? String, UUID.mockID1.uuidString)
        XCTAssertEqual(payloads[1]["conversationID"] as? String, UUID.mockID1.uuidString)
        XCTAssertEqual(payloads[1]["shouldRing"] as? Bool, false)
        XCTAssertNil(payloads[1]["hasVideo"])
        XCTAssertNil(payloads[1]["callerName"])
    }

    func test_onCallClosed_afterAlreadyClosedCall_doesNotReportAgain() async throws {
        // Given
        callingService.onIncomingCall?(Scaffolding.conversationID, Scaffolding.userID, true, false)
        try await sut.waitForCompletion()

        callingService.onCallClosed?(.canceled, Scaffolding.conversationID)
        try await sut.waitForCompletion()

        // When
        callingService.onCallClosed?(.canceled, Scaffolding.conversationID)
        try await sut.waitForCompletion()

        // Then
        XCTAssertEqual(callKitReporter.payloads.count, 2)
    }

    // MARK: - onMissedCall

    func test_onMissedCall_withoutPriorIncoming_doesNotReportCallKitPayload() async throws {
        // When
        callingService.onMissedCall?(Scaffolding.conversationID, Date(), false)
        try await sut.waitForCompletion()

        // Then
        XCTAssertTrue(callKitReporter.payloads.isEmpty)
    }

    // MARK: - onIncomingCall

    func test_onIncomingCall_reportsIncomingCallPayload() async throws {
        // Given
        await sut.setCallerName("Alice", for: Scaffolding.conversationID)

        // When
        callingService.onIncomingCall?(Scaffolding.conversationID, Scaffolding.userID, true, true)
        try await sut.waitForCompletion()

        // Then
        let payloads = callKitReporter.payloads
        XCTAssertEqual(payloads.count, 1)
        XCTAssertEqual(payloads[0]["accountID"] as? String, UUID.mockID1.uuidString)
        XCTAssertEqual(payloads[0]["conversationID"] as? String, UUID.mockID1.uuidString)
        XCTAssertEqual(payloads[0]["shouldRing"] as? Bool, true)
        XCTAssertEqual(payloads[0]["hasVideo"] as? Bool, true)
        XCTAssertEqual(payloads[0]["callerName"] as? String, "Alice")
    }

    func test_onIncomingCall_withInvalidConversationID_doesNotReportCallKitPayload() async throws {
        // When
        callingService.onIncomingCall?("invalid", Scaffolding.userID, true, false)
        try await sut.waitForCompletion()

        // Then
        XCTAssertTrue(callKitReporter.payloads.isEmpty)
    }
}

private extension CallKitReportingCoordinatorTests {
    enum Scaffolding {
        static let conversationID = "\(UUID.mockID1.uuidString)@wire.com"
        static let userID = "\(UUID.mockID2.uuidString)@wire.com"
    }
}

private final class MockCallKitReporter: CallKitReporterProtocol, @unchecked Sendable {

    private let lock = NSLock()
    private var payloadStorage: [[String: Any]] = []
    private var shouldSuspendReports = false
    private var reportContinuations: [CheckedContinuation<Void, Never>] = []
    private var payloadWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    var payloads: [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return payloadStorage
    }

    func reportNewIncomingVoIPPushPayload(_ payload: [String: Any]) async throws {
        lock.lock()
        payloadStorage.append(payload)
        let shouldSuspend = shouldSuspendReports
        let readyWaiters = payloadWaiters
            .filter { payloadStorage.count >= $0.count }
            .map(\.continuation)
        payloadWaiters.removeAll { payloadStorage.count >= $0.count }
        lock.unlock()

        readyWaiters.forEach { $0.resume() }

        guard shouldSuspend else { return }

        await withCheckedContinuation { continuation in
            lock.lock()
            reportContinuations.append(continuation)
            lock.unlock()
        }
    }

    func setShouldSuspendReports(_ shouldSuspendReports: Bool) {
        lock.lock()
        self.shouldSuspendReports = shouldSuspendReports
        lock.unlock()
    }

    func resumeReports() {
        lock.lock()
        shouldSuspendReports = false
        let continuations = reportContinuations
        reportContinuations.removeAll()
        lock.unlock()

        continuations.forEach { $0.resume() }
    }

    func waitForPayloadCount(_ count: Int) async {
        lock.lock()
        guard payloadStorage.count < count else {
            lock.unlock()
            return
        }
        lock.unlock()

        await withCheckedContinuation { continuation in
            lock.lock()
            if payloadStorage.count >= count {
                lock.unlock()
                continuation.resume()
            } else {
                payloadWaiters.append((count, continuation))
                lock.unlock()
            }
        }
    }
}

private actor CompletionProbe {

    private(set) var isCompleted = false

    func complete() {
        isCompleted = true
    }
}
