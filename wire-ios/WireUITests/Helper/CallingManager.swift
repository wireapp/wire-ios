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

    func switchVideoOn(instanceId: String) async throws -> CallResponse {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        return try await client.switchVideoOn(instanceId: instanceId, callId: callId)
    }

    func verifyReceiveAudioAndVideo(instanceIds: [String]) async throws {
        try await verifyPositiveFlowChangeOnAnyInstance(
            instanceIds: instanceIds,
            checkAudioSent: false,
            checkAudioReceived: true,
            checkVideoSent: false,
            checkVideoReceived: false,
            timeout: 60
        )
    }

    private func verifyPositiveFlowChangeOnAnyInstance(
        instanceIds: [String],
        checkAudioSent: Bool,
        checkAudioReceived: Bool,
        checkVideoSent: Bool,
        checkVideoReceived: Bool,
        timeout: TimeInterval
    ) async throws {
        let baseline = try await waitForFlowsOnAnyInstance(
            instanceIds: instanceIds,
            timeout: timeout
        )

        func hasPositiveChange(from flowBefore: CallFlow, to flowAfter: CallFlow) -> Bool {
            (!checkAudioSent || flowAfter.audioPacketsSent > flowBefore.audioPacketsSent) &&
                (!checkAudioReceived || flowAfter.audioPacketsReceived > flowBefore.audioPacketsReceived) &&
                (!checkVideoSent || flowAfter.videoPacketsSent > flowBefore.videoPacketsSent) &&
                (!checkVideoReceived || flowAfter.videoPacketsReceived > flowBefore.videoPacketsReceived)
        }

        var lastRawFlows: [CallFlow] = []
        var lastValidFlows: [CallFlow] = []

        for attempt in 0 ... Int(timeout) {
            lastRawFlows = try await client.getRawFlows(instanceId: baseline.instanceId)
            lastValidFlows = lastRawFlows.filter(\.isValid)

            for flowBefore in baseline.flows {
                if let flowAfter = lastValidFlows.first(where: { $0.remoteUserId == flowBefore.remoteUserId }),
                   hasPositiveChange(from: flowBefore, to: flowAfter) {
                    return
                }
            }

            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService no positive flow change for \(baseline.instanceId). " +
                "Before: \(baseline.flows). After raw: \(lastRawFlows). After valid: \(lastValidFlows)"
        )
    }

    private func waitForFlowsOnAnyInstance(
        instanceIds: [String],
        timeout: TimeInterval
    ) async throws -> (instanceId: String, flows: [CallFlow]) {
        var lastRawFlowsByInstanceId: [String: [CallFlow]] = [:]
        var lastValidFlowsByInstanceId: [String: [CallFlow]] = [:]

        for attempt in 0 ... Int(timeout) {
            for instanceId in instanceIds {
                let rawFlows = try await client.getRawFlows(instanceId: instanceId)
                let validFlows = rawFlows.filter(\.isValid)
                lastRawFlowsByInstanceId[instanceId] = rawFlows
                lastValidFlowsByInstanceId[instanceId] = validFlows

                if !validFlows.isEmpty {
                    return (instanceId, validFlows)
                }
            }

            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService found no valid flows for any instance. " +
                "Raw flows: \(lastRawFlowsByInstanceId). Valid flows: \(lastValidFlowsByInstanceId)"
        )
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
