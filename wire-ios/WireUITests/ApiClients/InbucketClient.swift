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

class InbucketClient {
    static func getVerificationCode(email: String) async throws -> String {
        let inbucketURL = "https://\(ProcessInfo.processInfo.environment["INBUCKET_URL"]!)"
        let inbucketUsername = ProcessInfo.processInfo.environment["INBUCKET_USERNAME"]!
        let inbucketPassword = ProcessInfo.processInfo.environment["INBUCKET_PASSWORD"]!
        var verificationCode = ""
        let url = URL(string: "\(inbucketURL)api/v1/mailbox/\(email)/latest")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let loginString = String(format: "%@:%@", inbucketUsername, inbucketPassword)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        var (inbucketData, response) = try await URLSession.shared.data(for: request)
        var pureResponse = response as! HTTPURLResponse
        while pureResponse.statusCode != 200 {
            (inbucketData, response) = try await URLSession.shared.data(for: request)
            pureResponse = response as! HTTPURLResponse
        }

        // Convert HTTP Response Data to a simple String
        let message: InbucketMessage = try! JSONDecoder().decode(InbucketMessage.self, from: inbucketData)
        let subject: String = message.subject
        verificationCode = String(subject.prefix(6))

        print("Verification Code Found: \(verificationCode) for \(email)")
        return verificationCode
    }
}

struct InbucketMessage: Decodable {
    let subject: String
}
