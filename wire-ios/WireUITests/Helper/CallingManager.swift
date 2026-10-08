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

import Foundation

/// Test helper that coordinates CallingService instances and call state checks.
/// Owns multi-instance actions and media verification so tests do not call raw endpoints directly.
final class CallingManager {

    private let client: CallingServiceClient

    init(client: CallingServiceClient) {
        self.client = client
    }

    func acceptNextCalls(
        instanceIds: [String],
        conversationId: String
    ) async throws -> [String: CallResponse] {
        precondition(!instanceIds.isEmpty, "No instance IDs provided")

        return try await withThrowingTaskGroup(of: (String, CallResponse).self) { group in
            for instanceId in instanceIds {
                group.addTask {
                    let request = CallRequest(
                        conversationId: conversationId,
                        timeout: CallingServiceClient.Constants.callTimeoutMilliseconds
                    )
                    let response = try await self.client.acceptNext(instanceId: instanceId, request: request)
                    return (instanceId, response)
                }
            }

            var results: [String: CallResponse] = [:]
            for try await (id, response) in group {
                results[id] = response
            }
            return results
        }
    }

    func waitForCurrentCallStatus(
        instanceId: String,
        expectedStatuses: Set<String>,
        timeout: TimeInterval
    ) async throws {
        precondition(!expectedStatuses.isEmpty, "No call statuses provided")

        let expectedStatuses = Set(expectedStatuses.map { $0.uppercased() })
        var currentStatus: String?
        var currentCallId: String?

        for attempt in 0 ... Int(timeout) {
            if let call = try? await client.getCurrentCall(instanceId: instanceId) {
                currentCallId = call.id
                currentStatus = call.status
                if let currentStatus, expectedStatuses.contains(currentStatus.uppercased()) {
                    return
                }
            }

            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService current call did not reach status \(expectedStatuses.sorted()) for \(instanceId). " +
                "Status: \(currentStatus ?? "nil"), callId: \(currentCallId ?? "nil")"
        )
    }

    func switchVideoOn(instanceId: String) async throws {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        try await client.switchVideoOn(instanceId: instanceId, callId: callId)
    }

    func switchScreenSharingOn(instanceId: String) async throws {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        try await client.switchScreenSharingOn(instanceId: instanceId, callId: callId)
    }

    func switchScreenSharingOff(instanceId: String) async throws {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        try await client.switchScreenSharingOff(instanceId: instanceId, callId: callId)
    }

    func stopCurrentCall(instanceId: String) async throws {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        try await client.stopCall(instanceId: instanceId, callId: callId)
    }

    func verifyPeerConnections(
        instanceIds: [String],
        expectedCount: Int,
        timeout: TimeInterval
    ) async throws {
        precondition(expectedCount >= 0, "Expected peer connection count must not be negative")

        var lastRawFlowsByInstanceId: [String: [CallFlow]] = [:]
        var lastValidFlowsByInstanceId: [String: [CallFlow]] = [:]
        var lastFlowErrorByInstanceId: [String: String] = [:]

        for instanceId in instanceIds {
            var didFindExpectedCount = false

            for attempt in 0 ... Int(timeout) {
                do {
                    let rawFlows = try await client.getRawFlows(instanceId: instanceId)
                    let validFlows = rawFlows.filter(\.isValid)
                    lastRawFlowsByInstanceId[instanceId] = rawFlows
                    lastValidFlowsByInstanceId[instanceId] = validFlows

                    if validFlows.count == expectedCount {
                        didFindExpectedCount = true
                        break
                    }
                } catch {
                    lastFlowErrorByInstanceId[instanceId] = "\(error)"
                }

                guard attempt < Int(timeout) else { break }
                try await Task.sleep(for: .seconds(1))
            }

            guard didFindExpectedCount else {
                throw RuntimeError(
                    "CallingService peer connection count did not reach \(expectedCount) for \(instanceId). " +
                        "Raw flows: \(lastRawFlowsByInstanceId). Valid flows: \(lastValidFlowsByInstanceId). " +
                        "Errors: \(lastFlowErrorByInstanceId)"
                )
            }
        }
    }

    private func requireCurrentCallId(instanceId: String) async throws -> String {
        let call = try await client.getCurrentCall(instanceId: instanceId)
        return try requireCallId(call)
    }

    private func requireCallId(_ call: CallResponse) throws -> String {
        guard let callId = call.id, !callId.isEmpty else {
            throw RuntimeError("CallingService call id is nil or empty")
        }
        return callId
    }
}
