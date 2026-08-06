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
    private let httpClient: HttpClient

    init(backendURL: URL) {
        self.backendURL = backendURL
        self.httpClient = HttpClient()
    }

    private init(backendURL: URL, httpClient: HttpClient) {
        self.backendURL = backendURL
        self.httpClient = httpClient
    }

    private func sendRequest(
        endpoint: URL,
        method: HttpClient.Method,
        body: Data,
        basicAuth: String
    ) async throws -> (Data, HTTPURLResponse) {

        try await httpClient.send(
            url: endpoint,
            method: method,
            body: body,
            headers: [
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.authorization: basicAuth
            ]
        )
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

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: Data("{}".utf8),
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "unlockConferenceCallingFeature failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
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
        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .patch,
            body: json,
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "enableConferenceCallingBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    private func getCellsFeature(teamId: String, basicAuth: String) async throws -> CellsFeatureResponse {

        let endpoint = backendURL
            .appendingPathComponent("i")
            .appendingPathComponent("teams")
            .appendingPathComponent(teamId)
            .appendingPathComponent("features")
            .appendingPathComponent("cells")

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .get,
            body: Data(),
            basicAuth: basicAuth
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "getCellsFeature failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        do {
            return try JSONDecoder().decode(CellsFeatureResponse.self, from: data)
        } catch {
            throw RuntimeError(
                "getCellsFeature decode failed: \(error). Raw: \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func getCellsInternal(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("cellsInternal")

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .get,
            body: Data(),
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "getCellsInternalBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func unlockCellsFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("cells")
            .appendingPathComponent("unlocked")

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: Data("{}".utf8),
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "unlockCellsFeature failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func enableCellsFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("cells")

        let current = try await getCellsFeature(teamId: teamId, basicAuth: headerValue)
        let payload = CellsFeaturePayload(
            config: current.config,
            status: "enabled",
            ttl: current.ttl
        )
        let json = try JSONEncoder().encode(payload)
        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: json,
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "enableCellsBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func unlockChannelFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("channels")
            .appendingPathComponent("unlocked")

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: Data("{}".utf8),
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "unlockCellsFeature failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func enableChannelFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("channels")

        let payload: [String: Any] = [
            "config": [
                "allowed_to_create_channels": "team-members",
                "allowed_to_open_channels": "team-members"
            ],
            "status": "enabled",
            "ttl": "unlimited"
        ]

        let json = try JSONSerialization.data(withJSONObject: payload, options: [])
        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: json,
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "enableCellsBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func unlockPreventAdminlessGroupsFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("preventAdminlessGroups")
            .appendingPathComponent("unlocked")

        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: Data("{}".utf8),
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "preventAdminlessGroups feature failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func enablePreventAdminlessGroupsFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("preventAdminlessGroups")

        let payload: [String: Any] = [
            "config": [
                "deletionTimeoutDuration": "7d",
                "promotionStrategy": "alphabetical",
                "reminderTimeoutDurations": [
                    "2d",
                    "4d",
                    "6d"
                ]
            ],
            "status": "enabled"
        ]

        let json = try JSONSerialization.data(withJSONObject: payload, options: [])
        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .put,
            body: json,
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "preventAdminlessGroupsBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func enableSSOFeature(teamId: String, basicAuth: String) async throws {

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
            .appendingPathComponent("sso")

        let json = try JSONSerialization.data(withJSONObject: ["status": "enabled"], options: [])
        let (data, code) = try await sendRequest(
            endpoint: endpoint,
            method: .patch,
            body: json,
            basicAuth: headerValue
        )

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "enableSSOBackdoorViaBackendTeam failed: HTTP \(code.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    // MARK: - models - Cells Feature

    private struct CellsFeaturePayload: Codable {
        let config: CellsConfig
        let status: String
        let ttl: String
    }

    private struct CellsFeatureResponse: Codable {
        let config: CellsConfig
        let lockStatus: String
        let status: String
        let ttl: String
    }

    private struct CellsConfig: Codable {
        let channels: ToggleDefault
        let collabora: Toggle
        let groups: ToggleDefault
        let metadata: Metadata
        let one2one: ToggleDefault
        let publicLinks: PublicLinks
        let storage: Storage
        let users: Users
    }

    private struct ToggleDefault: Codable {
        let `default`: String
        let enabled: Bool
    }

    private struct Toggle: Codable {
        let enabled: Bool
    }

    private struct Metadata: Codable {
        let namespaces: Namespaces
    }

    private struct Namespaces: Codable {
        let usermetaTags: UsermetaTags
    }

    private struct UsermetaTags: Codable {
        let allowFreeValues: Bool
        let defaultValues: [String]
    }

    private struct PublicLinks: Codable {
        let enableFiles: Bool
        let enableFolders: Bool
        let enforceExpirationDefault: Int
        let enforceExpirationMax: Int
        let enforcePassword: Bool
    }

    private struct Storage: Codable {
        let perFileQuotaBytes: String
        let recycle: Recycle
    }

    private struct Recycle: Codable {
        let allowSkip: Bool
        let autoPurgeDays: Int
        let disable: Bool
    }

    private struct Users: Codable {
        let externals: Bool
        let guests: Bool
    }
}
