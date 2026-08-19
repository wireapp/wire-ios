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

class TestServicesClient {

    let testServiceURL = "http://localhost:8080"
    let CONNECT_TIMEOUT: TimeInterval = 120
    let RESPONSE_TIMEOUT: TimeInterval = 120
    private var instanceCache: [String: String] = [:]

    // MARK: - Created instances log

    private actor CreatedInstancesTracker {
        private var ids: Set<String> = []

        func add(_ id: String?) {
            guard let id, !id.isEmpty else { return }
            ids.insert(id)
        }

        func drain() -> [String] {
            defer { ids.removeAll() }
            return Array(ids)
        }
    }

    private let createdInstances = CreatedInstancesTracker()

    func sendHttpRequest(
        url: String,
        body: [String: Any]? = nil,
        requestType: String
    ) async throws -> (Data, URLResponse) {
        guard let requestUrl = URL(string: url) else { fatalError("Invalid URL") }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = requestType
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        request.timeoutInterval = CONNECT_TIMEOUT
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = RESPONSE_TIMEOUT
        let session = URLSession(configuration: config)

        let (responseData, response) = try await session.data(for: request)

        return (responseData, response)
    }

    func getInstanceId(
        email: String,
        password: String,
        name: String,
        verificationCode: String?,
        deviceName: String = "device\(Int.random(in: 10_000 ... 99_999))",
        useCache: Bool = true
    ) async throws -> String {

        if useCache, let cachedInstanceId = instanceCache[email] {
            return cachedInstanceId
        }

        let url = URL(string: "\(testServiceURL)/api/v1/instance")
        guard let requestUrl = url else { fatalError() }

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name,
            "developmentApiEnabled": true,
            "deviceName": deviceName
        ]

        let (responseData, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "PUT"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let instanceResponse: CreateInstanceResponse = try JSONDecoder().decode(
            CreateInstanceResponse.self,
            from: responseData
        )
        if useCache {
            instanceCache[email] = instanceResponse.instanceId
        }
        await createdInstances.add(instanceResponse.instanceId)
        return instanceResponse.instanceId
    }

    func deleteInstances() async {
        let instanceIds = await createdInstances.drain()
        guard !instanceIds.isEmpty else { return }

        for instanceId in instanceIds {
            let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)")
            guard let requestUrl = url else { continue }

            do {
                print("Deleting Kalium Testservice instance \(instanceId)")
                let (responseData, response) = try await sendHttpRequest(
                    url: requestUrl.absoluteString,
                    requestType: "DELETE"
                )

                guard let pureResponse = response as? HTTPURLResponse else {
                    print("Failed to delete instance \(instanceId): Invalid response")
                    continue
                }
                if (200 ..< 300).contains(pureResponse.statusCode) {
                    print("Deleted Kalium Testservice instance \(instanceId)")
                } else {
                    var message = "HTTP \(pureResponse.statusCode): \(pureResponse.description)"
                    if let body = String(data: responseData, encoding: .utf8), !body.isEmpty {
                        message += " Body: \(body)"
                    }
                    print("Failed to delete Kalium Testservice instance \(instanceId): \(message)")
                }
            } catch {
                print("Failed to delete Kalium Testservice instance \(instanceId): \(error)")
            }
        }

        instanceCache.removeAll()
    }

    func createConversation(
        owner: UserInfo, member1Id: String, member2Id: String,
    ) async throws -> String {

        let instanceId = try await getInstanceId(
            email: owner.email,
            password: owner.password,
            name: owner.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/conversation")
        guard let requestUrl = url else { fatalError() }

        let body: [String: Any] = [
            "name": "demo chat",
            "userIds": [
                member1Id, member2Id
            ]
        ]

        let (responseData, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let conversationResponse: CreateConversationResponse = try JSONDecoder().decode(
            CreateConversationResponse.self,
            from: responseData
        )
        return conversationResponse.conversationId
    }

    func sendText(
        user: UserInfo,
        text: String,
        conversationId: UUID,
        domain: String,
        timeoutMillis: Int = 0,
        expectsReadConfirmation: Bool = true,
        buttons: [[String: Any]]? = nil
    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendText")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        var body: [String: Any] = [
            "conversationId": conversationId.uuidString.lowercased(),
            "text": text,
            "legalHoldStatus": 0,
            "expectsReadConfirmation": true
        ]

        if domain != BackendTarget.staging.domainInfo {
            body["conversationDomain"] = domain
        }

        if timeoutMillis > 0 {
            body["messageTimer"] = timeoutMillis
        }

        if expectsReadConfirmation {
            body["expectsReadConfirmation"] = true
        }

        if let buttons {
            body["buttons"] = buttons
        }

        let (_, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

    func fileToBase64String(fileURL: URL) throws -> String {
        let fileData = try Data(contentsOf: fileURL)
        return fileData.base64EncodedString()
    }

    func sendFile(
        type: String,
        user: UserInfo,
        fileName: String,
        filepath: String?,
        convoId: UUID,
        domain: String,
        timeoutMillis: Int = 0,
        audio: [String: Any]? = nil

    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendFile")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        var body: [String: Any] = [
            "conversationId": convoId.uuidString.lowercased(),
            "fileName": fileName,
            "type": type,
            "legalHoldStatus": 0,
            "expectsReadConfirmation": true
        ]

        if let filepath, !filepath.isEmpty {
            body["data"] = try fileToBase64String(fileURL: URL(fileURLWithPath: filepath))
        }

        if let audio {
            body["audio"] = audio
        }

        if domain != BackendTarget.staging.domainInfo {
            body["conversationDomain"] = domain
        }

        if timeoutMillis > 0 {
            body["messageTimer"] = timeoutMillis
        }

        let (_, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

    func sendImage(
        user: UserInfo,
        fileURL: URL,
        type: String,
        conversationId: UUID,
        domain: String,
    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendImage")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        let body: [String: Any] = [
            "conversationId": conversationId.uuidString.lowercased(),
            "data": try fileToBase64String(fileURL: fileURL),
            "conversationDomain": domain,
            "type": type
        ]

        let (_, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

    func sendLocation(
        user: UserInfo,
        conversationId: UUID,
        domain: String,
        latitude: Double,
        longitude: Double,
        locationName: String,
        zoom: Int = 15,
        timeoutMillis: Int = 0
    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendLocation")
        guard let requestUrl = url else {
            throw RuntimeError("Invalid URL")
        }

        var body: [String: Any] = [
            "conversationId": conversationId.uuidString.lowercased(),
            "conversationDomain": domain,
            "latitude": latitude,
            "longitude": longitude,
            "locationName": locationName,
            "zoom": zoom
        ]

        if timeoutMillis > 0 {
            body["messageTimer"] = timeoutMillis
        }

        let (_, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

    func getMyMessages(
        user: UserInfo,
        convoId: UUID,
        domain: String,
    ) async throws -> Data {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/getMessages")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        let body: [String: Any] = [
            "conversationId": convoId.uuidString.lowercased(),
            "conversationDomain": domain
        ]

        let (responseData, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
        return responseData
    }

    func sendPing(
        user: UserInfo,
        conversationId: UUID,
        domain: String,
    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendPing")
        guard let requestUrl = url else {
            throw RuntimeError("Invalid URL")
        }

        let body: [String: Any] = [
            "conversationId": conversationId.uuidString.lowercased(),
            "conversationDomain": domain
        ]

        let (_, response) = try await sendHttpRequest(
            url: requestUrl.absoluteString,
            body: body,
            requestType: "POST"
        )

        guard let pureResponse = response as? HTTPURLResponse else {
            throw RuntimeError("Invalid response")
        }

        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

}

private struct CreateInstanceResponse: Decodable {
    let instanceId: String
}

private struct CreateConversationResponse: Decodable {
    let conversationId: String
}
