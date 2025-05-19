//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

enum BackendClient {
    
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
    
    static func loginViaAPI(email: String, password: String) async throws -> String {
        let url = URL(string: "\(backendURL)/v8/login")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        let body: [String: Any] = ["email": "\(email)", "password": "\(password)"]
        print(body)
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let (responseData, response) = try await URLSession.shared.data(for: request)

        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            print("Error! got status code \(pureResponse.statusCode)")
            print("Response: \(pureResponse.description)")
            throw (RuntimeError("Error \(pureResponse.description)"))
        }

        let message: LoginMessage = try JSONDecoder().decode(LoginMessage.self, from: responseData)
        return message.access_token
    }

    static func deletePersonalUser(access_token: String, password: String) async throws {
        let url = URL(string: "\(backendURL)/self")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "DELETE"
        let body: [String: Any] = ["password": "\(password)"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }
    }
    
    static func registerPersonalUser(_ user: UserInfo) async throws -> UserInfo {
        var body: [String: Any] = [
            "email": user.email,
            "password": user.password,
            "name": user.name
        ]
        let response = try await httpPostRequest(url: "\(backendURL)/register", body: body)
        var updatedUser = UserInfo()
        updatedUser.name = response.value(forKey: "name") as! String
        updatedUser.email = response.value(forKey: "email") as! String
        updatedUser.id = response.value(forKey: "id") as! String
        updatedUser.backend_domain = response.value(forKeyPath: "qualified_id.domain") as! String
        return user
    }
    
    private static func httpPostRequest(url: String, body: [String: Any]) async throws -> HTTPURLResponse {
        guard let requestUrl = URL(string: url) else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "DELETE"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }
        return pureResponse
    }
}

private struct LoginMessage: Decodable {
    let access_token: String
}
