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

    func sendHttpRequest(url: String, body: [String: Any], requestType: String) async throws -> (Data, URLResponse) {
        guard let requestUrl = URL(string: url) else { fatalError("Invalid URL") }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = requestType
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.timeoutInterval = CONNECT_TIMEOUT
        request.setValue("UTF-8", forHTTPHeaderField: "Accept-Encoding")
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
        deviceName: String?
    ) async throws -> String {

        let url = URL(string: "\(testServiceURL)/api/v1/instance")
        guard let requestUrl = url else { fatalError() }

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name,
            "developmentApiEnabled": true,
            "deviceName": deviceName ?? "device1"
        ]

        let (responseData, response) = try await sendHttpRequest(
            url: String(describing: requestUrl),
            body: body,
            requestType: "PUT"
        )

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let Data: CreateInstaceResponse = try JSONDecoder().decode(CreateInstaceResponse.self, from: responseData)
        return Data.instanceId
    }

    func createConversation(
        owner: UserInfo, member1Id: String, member2Id: String,
    ) async throws -> String {

        let instanceId = try await getInstanceId(
            email: owner.email,
            password: owner.password,
            name: owner.name,
            verificationCode: nil,
            deviceName: nil
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
            url: String(describing: requestUrl),
            body: body,
            requestType: "POST"
        )

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let Data: CreateConversationResponse = try JSONDecoder().decode(
            CreateConversationResponse.self,
            from: responseData
        )
        return Data.conversationId
    }

    func sendText(
        user: UserInfo,
        text: String,
        convoId: UUID,
        domain: String,
        timeoutMillis: Int = 0,
        expectsReadConfirmation: Bool = true,
        buttons: [[String: Any]]? = nil
    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil,
            deviceName: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendText")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        var body: [String: Any] = [
            "conversationId": convoId.uuidString.lowercased(),
            "text": text,
            "legalHoldStatus": 0
        ]

        if domain != "staging.zinfra.io" {
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

        let (responseData, response) = try await sendHttpRequest(
            url: String(describing: requestUrl),
            body: body,
            requestType: "POST"
        )

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }

    func fileToBase64String(filePath: String) throws -> String {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return fileData.base64EncodedString()
    }

    func sendFile(
        type: String,
        user: UserInfo,
        fileName: String,
        filepath: String,
        convoId: UUID,
        domain: String,
        timeoutMillis: Int = 0,

    ) async throws {

        let instanceId = try await getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil,
            deviceName: nil
        )

        let url = URL(string: "\(testServiceURL)/api/v1/instance/\(instanceId)/sendFile")
        guard let requestUrl = url else { fatalError("Invalid URL") }

        var body: [String: Any] = [
            "conversationId": convoId.uuidString.lowercased(),
            "data": try fileToBase64String(filePath: filepath),
            "fileName": fileName,
            "type": type
        ]

        if domain != "staging.zinfra.io" {
            body["conversationDomain"] = domain
        }

        if timeoutMillis > 0 {
            body["messageTimer"] = timeoutMillis
        }

        let (_, response) = try await sendHttpRequest(
            url: String(describing: requestUrl),
            body: body,
            requestType: "POST"
        )

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw RuntimeError("Error \(pureResponse.description)")
        }
    }
}

private struct CreateInstaceResponse: Decodable {
    let instanceId: String
}

private struct CreateConversationResponse: Decodable {
    let conversationId: String
}
