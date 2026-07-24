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

    func waitForCurrentCall(
        instanceId: String,
        timeout: TimeInterval
    ) async throws {
        var currentStatus: String?
        var currentCallId: String?

        for attempt in 0 ... Int(timeout) {
            if let call = try? await client.getCurrentCall(instanceId: instanceId) {
                currentCallId = call.id
                currentStatus = call.status
                if let currentCallId, !currentCallId.isEmpty {
                    return
                }
            }

            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService current call was not found for \(instanceId). Status: \(currentStatus ?? "nil"), callId: \(currentCallId ?? "nil")"
        )
    }

    func switchVideoOn(instanceId: String) async throws -> CallResponse {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        return try await client.switchVideoOn(instanceId: instanceId, callId: callId)
    }

    func switchScreenSharingOn(instanceId: String) async throws -> CallResponse {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        return try await client.switchScreenSharingOn(instanceId: instanceId, callId: callId)
    }

    func switchScreenSharingOff(instanceId: String) async throws -> CallResponse {
        let callId = try await requireCurrentCallId(instanceId: instanceId)
        return try await client.switchScreenSharingOff(instanceId: instanceId, callId: callId)
    }

    func verifyReceiveAudioAndVideo(instanceIds: [String]) async throws {
        try await verifyPositiveFlowChange(
            instanceIds: instanceIds,
            checkAudioSent: false,
            checkAudioReceived: true,
            checkVideoSent: false,
            checkVideoReceived: true,
            timeout: 15
        )
    }

    private func verifyPositiveFlowChange(
        instanceIds: [String],
        checkAudioSent: Bool,
        checkAudioReceived: Bool,
        checkVideoSent: Bool,
        checkVideoReceived: Bool,
        timeout: TimeInterval = 15
    ) async throws {
        for instanceId in instanceIds {
            let flowsBefore = try await waitForFlows(instanceId: instanceId)

            for flowBefore in flowsBefore {
                try await assertPositiveFlowChange(
                    instanceId: instanceId,
                    flowBefore: flowBefore,
                    checkAudioSent: checkAudioSent,
                    checkAudioReceived: checkAudioReceived,
                    checkVideoSent: checkVideoSent,
                    checkVideoReceived: checkVideoReceived,
                    timeout: timeout
                )
            }
        }
    }

    private func waitForFlows(
        instanceId: String,
        minimumCount: Int = 1,
        timeout: TimeInterval = 15
    ) async throws -> [CallFlow] {
        var flows: [CallFlow] = []

        for attempt in 0 ... Int(timeout) {
            flows = try await client.getFlows(instanceId: instanceId)
            if flows.count >= minimumCount {
                return flows
            }
            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService found \(flows.count) flows for \(instanceId), expected at least \(minimumCount)"
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

    private func assertPositiveFlowChange(
        instanceId: String,
        flowBefore: CallFlow,
        checkAudioSent: Bool,
        checkAudioReceived: Bool,
        checkVideoSent: Bool,
        checkVideoReceived: Bool,
        timeout: TimeInterval
    ) async throws {
        var flowAfter: CallFlow?

        for attempt in 0 ... Int(timeout) {
            flowAfter = try await client.getFlows(instanceId: instanceId)
                .first { $0.remoteUserId == flowBefore.remoteUserId }

            if let flowAfter,
               !checkAudioSent || flowAfter.audioPacketsSent > flowBefore.audioPacketsSent,
               !checkAudioReceived || flowAfter.audioPacketsReceived > flowBefore.audioPacketsReceived,
               !checkVideoSent || flowAfter.videoPacketsSent > flowBefore.videoPacketsSent,
               !checkVideoReceived || flowAfter.videoPacketsReceived > flowBefore.videoPacketsReceived {
                return
            }

            guard attempt < Int(timeout) else { break }
            try await Task.sleep(for: .seconds(1))
        }

        throw RuntimeError(
            "CallingService no positive flow change for \(instanceId). Before: \(flowBefore). After: \(String(describing: flowAfter))"
        )
    }
}
