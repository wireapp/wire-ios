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

class BackendClient {
    static func loginViaAPI(email: String, password: String) async throws -> String {
        let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
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

        let message: LoginMessage = try! JSONDecoder().decode(LoginMessage.self, from: responseData)
        return message.access_token
    }

    static func deletePersonalUser(access_token: String, password: String) async throws {
        let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
        let url = URL(string: "\(backendURL)/self")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "DELETE"
        let body: [String: Any] = ["password": "\(password)"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        let pureResponse = response as! HTTPURLResponse
        if pureResponse.statusCode != 200 {
            throw (RuntimeError("Error \(pureResponse.description)"))
        }
    }
}

struct LoginMessage: Decodable {
    let access_token: String
}
