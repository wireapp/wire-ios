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

enum InbucketClient {

    static func getVerificationCode(email: String) async throws -> String {
        let envVariables = try EnvironmentVariables()

        var verificationCode = ""
        let baseURL: URL = envVariables.inbucketURL
        let requestUrl = baseURL.appending(path: "api/v1/mailbox/\(email)/latest")

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let loginString = String(format: "%@:%@", envVariables.inbucketUsername, envVariables.inbucketPassword)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        enum EmailFetchError: Error {
            case unableToRetrieveLatestMessage(email: String, statusCode: Int)
        }
        var (inbucketData, response) = try await URLSession.shared.data(for: request)
        var pureResponse = response as! HTTPURLResponse
        var timeout = 0
        while pureResponse.statusCode != 200, timeout < 100 {
            (inbucketData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmailFetchError.unableToRetrieveLatestMessage(email: email, statusCode: -1)
            }
            pureResponse = httpResponse
            timeout += 1
            if timeout == 100, pureResponse.statusCode != 200 {

                throw EmailFetchError.unableToRetrieveLatestMessage(email: email, statusCode: pureResponse.statusCode)

            }
        }

        // Convert HTTP Response Data to a simple String
        let message: InbucketMessage = try JSONDecoder().decode(InbucketMessage.self, from: inbucketData)
        let subject: String = message.subject
        verificationCode = String(subject.prefix(6))

        print("Verification Code Found: \(verificationCode) for \(email)")
        return verificationCode
    }

}

private struct InbucketMessage: Decodable {
    let subject: String
}
