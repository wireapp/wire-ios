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

    // MARK: - Created instances log

    private actor CreatedInstancesTracker {
        private var ids: [String] = []

        func add(_ id: String?) {
            guard let id, !id.isEmpty else { return }
            ids.append(id)
        }

        func drain() -> [String] {
            defer { ids.removeAll() }
            return ids
        }
    }

    private let createdInstances = CreatedInstancesTracker()

    /// Destroys any instances created
    func destroyCreatedInstances() async {
        let ids = await createdInstances.drain()
        guard !ids.isEmpty else { return }
        _ = try? await destroyInstances(instanceIds: ids)
    }

    init() throws {
        let envVariables = try EnvironmentVariables()
        self.callingServiceURL = envVariables.callingServiceURL
        self.callingServiceUsername = envVariables.callingServiceUsername
        self.callingServicePassword = envVariables.callingServicePassword
    }

    enum Constants {
        static let CONNECT_TIMEOUT: TimeInterval = 360
        static let RESPONSE_TIMEOUT: TimeInterval = 360
        static let CALLING_RESPONSE_TIMEOUT: TimeInterval = 600

    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.CONNECT_TIMEOUT
        config.timeoutIntervalForResource = Constants.RESPONSE_TIMEOUT
        return URLSession(configuration: config)
    }()

    private lazy var httpClient = HttpClient(urlSession: session)

    private func basicAuthHeader() -> String? {
        guard !callingServiceUsername.isEmpty,
              !callingServicePassword.isEmpty
        else { return nil }

        let creds = "\(callingServiceUsername):\(callingServicePassword)"
        let encoded = Data(creds.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    func instanceEndpoint(instanceId: String, path: String) -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return callingServiceURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("instance")
            .appendingPathComponent(instanceId)
            .appendingPathComponent(cleanPath)
    }

    func sendHttpRequest(
        endpoint: URL,
        body: (some Encodable)?,
        method: HttpClient.Method
    ) async throws -> (Data, HTTPURLResponse) {
        var headers: [String: String] = [
            HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
            HttpClient.HeaderKey.accept: HttpClient.ContentType.json
        ]

        if let auth = basicAuthHeader() {
            headers[HttpClient.HeaderKey.authorization] = auth
        }

        let jsonBody: Data = if let body {
            try JSONEncoder().encode(body)
        } else {
            Data()
        }

        return try await httpClient.send(
            url: endpoint,
            method: method,
            body: jsonBody,
            headers: headers
        )
    }

    /// Create callingService instance
    /// - Parameters:
    ///   - name: name of instance
    ///   - userInfo: userInfo
    ///   - backend: name of backend for the instance
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

        let (data, code) = try await sendHttpRequest(endpoint: endpoint, body: body, method: .post)

        guard code.statusCode == 200 else {
            throw RuntimeError(
                "CallingService failed to createInstance: HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
        let instance = try JSONDecoder().decode(CallingServiceInstance.self, from: data)
        await createdInstances.add(instance.id)
        return instance
    }

    /// Create multiple callingService instances
    /// - Parameters:
    ///   - users: information of users
    ///   - backend: which backend of calling service is being used
    ///   - beta: true
    ///   - instanceTypeName: InstanceType i.e chrome, firefox etc
    ///   - instanceTypeVersion: Version of Instance
    /// - Returns: created Instances
    func createInstances(
        users: [UserInfo],
        backend: String,
        beta: Bool,
        instanceTypeName: String,
        instanceTypeVersion: String
    ) async throws -> [CallingServiceInstance] {

        guard !users.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: (Int, CallingServiceInstance).self) { group in
            for (index, user) in users.enumerated() {
                group.addTask { [self] in
                    let baseName = user.name.isEmpty ? user.email : user.name
                    let instanceName = if index == 0 {
                        "Owner \(baseName)"
                    } else {
                        "Member\(index) \(baseName)"
                    }
                    let instance = try await createInstance(
                        name: instanceName,
                        userInfo: user,
                        backend: backend,
                        beta: beta,
                        instanceTypeName: instanceTypeName,
                        instanceTypeVersion: instanceTypeVersion
                    )
                    return (index, instance)
                }
            }

            var results = [CallingServiceInstance?](repeating: nil, count: users.count)
            while let (index, instance) = try await group.next() {
                results[index] = instance
            }
            return results.compactMap(\.self)
        }
    }

    /// Fetch callingService instance status
    /// - Parameter instanceId
    /// - Returns: instance id and status
    func getInstanceStatus(instanceIds: [String]) async throws -> [CallingServiceInstance] {
        var results: [CallingServiceInstance] = []

        for id in instanceIds {
            let endpoint = instanceEndpoint(instanceId: id, path: "status")
            let (data, code) = try await sendHttpRequest(
                endpoint: endpoint,
                body: CallingServiceEmptyBody?.none,
                method: .get
            )

            guard code.statusCode == 200 else {
                throw RuntimeError(
                    "CallingService failed to getInstanceStatus for \(id): HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
                )
            }

            let instance = try JSONDecoder().decode(CallingServiceInstance.self, from: data)
            results.append(instance)
        }
        return results
    }

    /// Destroy  instance
    /// - Parameter instanceId
    /// - Returns: Instance id and status
    func destroyInstances(instanceIds: [String]) async throws -> [CallingServiceInstance] {
        var results: [CallingServiceInstance] = []

        for id in instanceIds {
            let endpoint = instanceEndpoint(instanceId: id, path: "destroy")
            let (data, code) = try await sendHttpRequest(
                endpoint: endpoint,
                body: CallingServiceEmptyBody(),
                method: .put
            )

            guard code.statusCode == 200 else {
                throw RuntimeError(
                    "CallingService failed to destroyStatus for \(id): HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
                )
            }

            let instance = try JSONDecoder().decode(CallingServiceInstance.self, from: data)
            results.append(instance)
        }

        return results
    }

    private func performCall(
        instanceId: String,
        path: String,
        request: some Encodable
    ) async throws -> CallResponse {
        let endpoint = instanceEndpoint(instanceId: instanceId, path: path)
        let (data, code) = try await sendHttpRequest(endpoint: endpoint, body: request, method: .post)
        guard code.statusCode == 200 else {
            throw RuntimeError(
                "CallingService call failed: POST \(path) HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
        return try JSONDecoder().decode(CallResponse.self, from: data)
    }

    private func performCallGet(
        instanceId: String,
        path: String
    ) async throws -> CallResponse {
        let endpoint = instanceEndpoint(instanceId: instanceId, path: path)
        let (data, code) = try await sendHttpRequest(
            endpoint: endpoint,
            body: CallingServiceEmptyBody?.none,
            method: .get
        )
        guard code.statusCode == 200 else {
            throw RuntimeError(
                "CallingService call failed: GET \(path) HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
        return try JSONDecoder().decode(CallResponse.self, from: data)
    }

    private func performCallPut(
        instanceId: String,
        path: String
    ) async throws -> CallResponse {
        let endpoint = instanceEndpoint(instanceId: instanceId, path: path)
        let (data, code) = try await sendHttpRequest(endpoint: endpoint, body: CallingServiceEmptyBody(), method: .put)
        guard code.statusCode == 200 else {
            throw RuntimeError(
                "CallingService call failed: PUT \(path) HTTP \(code.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
        return try JSONDecoder().decode(CallResponse.self, from: data)
    }

    func start(instanceId: String, request: StartCallBody) async throws -> CallResponse {
        try await performCall(instanceId: instanceId, path: "/call/start", request: request)
    }

    func startVideo(instanceId: String, request: StartCallBody) async throws -> CallResponse {
        try await performCall(instanceId: instanceId, path: "/call/startVideo", request: request)
    }

    func acceptNext(instanceId: String, request: CallRequest) async throws -> CallResponse {
        try await performCall(instanceId: instanceId, path: "/call/acceptNext", request: request)
    }

    func startCall(
        instanceId: String,
        conversationId: String
    ) async throws -> CallResponse {
        let request = StartCallBody(
            conversationId: conversationId,
            timeout: Constants.CALLING_RESPONSE_TIMEOUT
        )
        return try await start(instanceId: instanceId, request: request)
    }

    func startVideoCall(
        instanceId: String,
        conversationId: String
    ) async throws -> CallResponse {
        let request = StartCallBody(
            conversationId: conversationId,
            timeout: Constants.CALLING_RESPONSE_TIMEOUT
        )
        return try await startVideo(instanceId: instanceId, request: request)
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
                        timeout: Constants.CALLING_RESPONSE_TIMEOUT
                    )
                    let response = try await self.acceptNext(instanceId: instanceId, request: request)
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
}

struct InstanceType: Encodable {
    let name: String
    let version: String
}

struct CallingServiceInstance: Decodable {
    let id: String
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

typealias CallRequest = StartCallBody

struct CallingServiceEmptyBody: Encodable {}

struct CallResponse: Decodable {
    let id: String?
    let status: String?
}
