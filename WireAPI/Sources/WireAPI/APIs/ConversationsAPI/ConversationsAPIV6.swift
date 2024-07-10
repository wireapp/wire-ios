//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct UpdateGroupIconParameters: Encodable {
    var color: String?
    var emoji: String?
}

import Foundation

final class ConversationsAPIV6: ConversationsAPIV5 {
    override var apiVersion: APIVersion { .v6 }

    override func updateGroupIcon(for identifier: QualifiedID, hexColor: String?, emoji: String?) async throws {
        let parameters = UpdateGroupIconParameters(color: hexColor, emoji: emoji)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let resourcePath = "\(pathPrefix)/conversations/\(identifier.uuid)/icon"

        let request = HTTPRequest(
            path: resourcePath,
            method: .put,
            body: body
        )
        let response = try await httpClient.executeRequest(request)

        let code = response.code
        switch code {
        case 204:
            break
        default:
            guard let data = response.payload else {
                throw ResponseParserError.missingPayload
            }

            let failure = try JSONDecoder().decode(FailureResponse.self, from: data)
            throw failure
        }
    }
}
