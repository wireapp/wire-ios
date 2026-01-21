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

    private var callingServiceURL = ProcessInfo.processInfo.environment["CALLINGSERVICE_URL"]!

    let CONNECT_TIMEOUT: TimeInterval = 600_000
    let RESPONSE_TIMEOUT: TimeInterval = 600_000

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = RESPONSE_TIMEOUT
        return URLSession(configuration: config)
    }()

    private var callingServiceUsername = ProcessInfo.processInfo.environment["CALLINGSERVICE_USERNAME"]!

    private var callingServicePassword = ProcessInfo.processInfo.environment["CALLINGSERVICE_PASSWORD"]!

    private(set) var callingServiceServerIdCookieByInstanceId: [String: HTTPCookie] = [:]

    private let userHelper = UserHelper()

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
        body: some Encodable,
        method: String,
        extraHeaders: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {

        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = CONNECT_TIMEOUT

        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let auth = basicAuthHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        for (k, v) in extraHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RuntimeError("Non-HTTP response")
        }

        return (data, http)
    }

    private func callingServiceBaseURL() -> URL {
        let raw = callingServiceURL
        return URL(string: raw)!
    }

    func createInstance(
        id: String = "",
        name: String,
        userInfo: UserInfo,
        backend: String,
        beta: Bool,
        instanceTypeName: String,
        instanceTypeVersion: String? = nil
    ) async throws -> CallingServiceInstance {

        try await userHelper.disableConsentPopup(for: userInfo)

        let endpoint = callingServiceBaseURL().appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("instance").appendingPathComponent("create")

        let body = CreateInstanceBody(
            id: id,
            name: name,
            email: userInfo.email,
            password: userInfo.password,
            backend: backend,
            beta: beta,
            instanceType: .init(
                name: instanceTypeName,
                version: (instanceTypeVersion?.isEmpty == false) ? instanceTypeVersion : nil
            )
        )

        let (data, http) = try await sendHttpRequest(endpoint: endpoint, body: body, method: "POST")

        guard http.statusCode == 200 else {
            throw RuntimeError(
                "CallingService createInstance: HTTP \(http.statusCode). \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let instance = try JSONDecoder().decode(CallingServiceInstance.self, from: data)
        if let instanceId = instance.id {
            let setCookieStrings: [String] = http.allHeaderFields.flatMap { k, v -> [String] in
                guard String(describing: k).lowercased() == "set-cookie" else { return [] }

                if let s = v as? String { return [s] }
                if let arr = v as? [String] { return arr }
                if let arrAny = v as? [Any] {
                    return arrAny.compactMap { $0 as? String }
                }
                return [String(describing: v)]
            }

            for setCookie in setCookieStrings {
                let cookies = HTTPCookie.cookies(
                    withResponseHeaderFields: ["Set-Cookie": setCookie],
                    for: endpoint
                )
                if let serverId = cookies.first(where: { $0.name == "SERVERID" }) {
                    callingServiceServerIdCookieByInstanceId[instanceId] = serverId
                    break
                }
            }
        }

        return instance
    }

    func startCall(
        instanceId: String,
        conversationId: String,
        timeoutMillis: Int = 3_600_000
    ) async throws {

        let endpoint = callingServiceBaseURL()
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("instance")
            .appendingPathComponent(instanceId)
            .appendingPathComponent("call")
            .appendingPathComponent("start")

        struct StartCallBody: Encodable {
            let conversationId: String
            let timeout: Int
        }

        var extraHeaders: [String: String] = [:]

        if let cookie = callingServiceServerIdCookieByInstanceId[instanceId] {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: [cookie])
            for (k, v) in cookieHeaders {
                extraHeaders[k] = v
            }
        }

        let body = StartCallBody(conversationId: conversationId, timeout: timeoutMillis)

        let (data, http) = try await sendHttpRequest(
            endpoint: endpoint,
            body: body,
            method: "POST",
            extraHeaders: extraHeaders
        )

        guard (200 ..< 300).contains(http.statusCode) else {
            throw RuntimeError(
                "RunTimeError-NotImplementedYet"
            )
        }
    }
}

struct InstanceType: Encodable {
    let name: String
    let version: String?
}

struct CallingServiceInstance: Decodable {
    let id: String?
    let status: String?
}

struct CreateInstanceBody: Encodable {
    let id: String
    let name: String
    let email: String
    let password: String
    let backend: String
    let beta: Bool
    let instanceType: InstanceType
}

struct CustomBackend: Codable {
    let webappUrl: String
    let backendUrl: String
    let websocketUrl: String
}
