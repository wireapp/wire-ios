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

final class CallingServiceClient {

    private let userHelper = UserHelper()

    private let callingServiceURL: URL
    private let callingServiceUsername: String
    private let callingServicePassword: String

    init() {
        do {
            let envVariables = try EnvironmentVariables()
            self.callingServiceURL = envVariables.callingServiceURL
            self.callingServiceUsername = envVariables.callingServiceUsername
            self.callingServicePassword = envVariables.callingServicePassword
        } catch {
            preconditionFailure("CallingServiceClient failed to fetch EnvVariables: \(error)")
        }
    }

    private enum Constants {
        static let CONNECT_TIMEOUT: TimeInterval = 600_000
        static let RESPONSE_TIMEOUT: TimeInterval = 600_000
        static let CALLING_RESPONSE_TIMEOUT: TimeInterval = 3_600_000

    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.CONNECT_TIMEOUT
        config.timeoutIntervalForResource = Constants.RESPONSE_TIMEOUT
        return URLSession(configuration: config)
    }()

    private func basicAuthHeader() -> String? {
        guard !callingServiceUsername.isEmpty,
              !callingServicePassword.isEmpty
        else { return nil }

        let creds = "\(callingServiceUsername):\(callingServicePassword)"
        let encoded = Data(creds.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    private func sendHttpRequest(
        endpoint: URL,
        body: (some Encodable)?,
        method: String
    ) async throws -> (Data, HTTPURLResponse) {

        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = Constants.CONNECT_TIMEOUT

        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let auth = basicAuthHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let code = response as? HTTPURLResponse else {
            throw RuntimeError("Non-HTTP response")
        }

        return (data, code)
    }

    /// Creat callingService instance
    /// - Parameters:
    ///   - name: name of instance
    ///   - userInfo: userInfo
    ///   - backend: for which backend
    /// - Returns: instance id and status
    func createInstance(
        name: String,
        userInfo: UserInfo,
        backend: String,
        beta: Bool,
        instanceTypeName: String,
        instanceTypeVersion: String

    ) async throws -> CallingServiceInstance {

        try await userHelper.disableConsentPopup(for: userInfo)

        let endpoint = callingServiceURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("instance")
            .appendingPathComponent("create")

        let body = CreateInstanceBody(
            name: name,
            email: userInfo.email,
            password: userInfo.password,
            backend: backend,
            beta: beta,
            instanceType: .init(
                name: instanceTypeName,
                version: instanceTypeVersion
            ),
            timeout: Constants.RESPONSE_TIMEOUT
        )

        let (data, http) = try await sendHttpRequest(endpoint: endpoint, body: body, method: "POST")

        guard http.statusCode == 200 else {
            throw RuntimeError(
                "CallingService failed to createInstance: HTTP \(http.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        return try JSONDecoder().decode(CallingServiceInstance.self, from: data)
    }

    /// Initiate a call from callingservice
    /// - Parameters:
    ///   - instanceId: instanceId
    ///   - conversationId: conversationId where call need to point
    func startCall(
        instanceId: String,
        conversationId: String
    ) async throws {

        let endpoint = callingServiceURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("instance")
            .appendingPathComponent(instanceId)
            .appendingPathComponent("call")
            .appendingPathComponent("start")

        let body = StartCallBody(conversationId: conversationId, timeout: Constants.CALLING_RESPONSE_TIMEOUT)

        let (_, code) = try await sendHttpRequest(
            endpoint: endpoint,
            body: body,
            method: "POST"
        )

        guard (200 ..< 300).contains(code.statusCode) else {
            throw RuntimeError("CallingService failed to startCall: HTTP \(code.statusCode)")
        }
    }
}

struct InstanceType: Encodable {
    let name: String
    let version: String
}

struct CallingServiceInstance: Decodable {
    let id: String?
    let instanceStatus: String?
}

struct CreateInstanceBody: Encodable {
    let name: String
    let email: String
    let password: String
    let backend: String
    let beta: Bool
    let instanceType: InstanceType
    let timeout: Double
}

struct StartCallBody: Encodable {
    let conversationId: String
    let timeout: Double
}
