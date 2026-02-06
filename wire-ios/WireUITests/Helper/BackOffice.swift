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
import WireNetwork

final class BackOffice {

    private let backendURL: URL

    init(backendURL: URL) {
        self.backendURL = backendURL
    }

    private func sendRequest(
        endpoint: URL,
        method: String,
        body: Data,
        basicAuth: String
    ) async throws -> (Data, HTTPURLResponse) {

        var request = URLRequest(url: endpoint)
        request.httpMethod = method

        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(basicAuth, forHTTPHeaderField: "Authorization")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RuntimeError("Non-HTTP response")
        }

        return (data, http)
    }

    func unlockConferenceCallingFeature(teamId: String, basicAuth: String) async throws {

        let trimmed = basicAuth.trimmingCharacters(in: .whitespacesAndNewlines)

        let headerValue: String = if trimmed.lowercased().hasPrefix("basic ") {
            trimmed
        } else {
            "Basic \(trimmed)"
        }

        let endpoint = backendURL
            .appendingPathComponent("i")
            .appendingPathComponent("teams")
            .appendingPathComponent(teamId)
            .appendingPathComponent("features")
            .appendingPathComponent("conferenceCalling")
            .appendingPathComponent("unlocked")

        let (data, http) = try await sendRequest(
            endpoint: endpoint,
            method: "PUT",
            body: Data("{}".utf8),
            basicAuth: headerValue
        )

        guard http.statusCode == 200 else {
            throw RuntimeError(
                "unlockConferenceCallingFeature failed: HTTP \(http.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func enableConferenceCallingFeature(teamId: String, basicAuth: String) async throws {

        let trimmed = basicAuth.trimmingCharacters(in: .whitespacesAndNewlines)

        let headerValue: String = if trimmed.lowercased().hasPrefix("basic ") {
            trimmed
        } else {
            "Basic \(trimmed)"
        }

        let endpoint = backendURL
            .appendingPathComponent("i")
            .appendingPathComponent("teams")
            .appendingPathComponent(teamId)
            .appendingPathComponent("features")
            .appendingPathComponent("conferenceCalling")

        let json = try JSONSerialization.data(withJSONObject: ["status": "enabled"], options: [])
        let (data, http) = try await sendRequest(
            endpoint: endpoint,
            method: "PATCH",
            body: json,
            basicAuth: headerValue
        )

        guard http.statusCode == 200 else {
            throw RuntimeError(
                "enableConferenceCallingBackdoorViaBackendTeam failed: HTTP \(http.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }
}
