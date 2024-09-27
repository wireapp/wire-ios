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

import Foundation

// MARK: - SelfUserAPIV5

class SelfUserAPIV5: SelfUserAPIV4 {
    override var apiVersion: APIVersion {
        .v5
    }

    override func pushSupportedProtocols(_ supportedProtocols: Set<MessageProtocol>) async throws {
        let encoder = JSONEncoder.defaultEncoder
        let payload = SupportedProtocolsPayloadV5(supportedProtocols: supportedProtocols)
        let body = try encoder.encode(payload)

        let request = HTTPRequest(
            path: "\(pathPrefix)/self/supported-protocols",
            method: .put,
            body: body
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200)
            .parse(response)
    }
}

// MARK: - SupportedProtocolsPayloadV5

struct SupportedProtocolsPayloadV5: Encodable {
    let supportedProtocols: Set<MessageProtocol>

    enum CodingKeys: String, CodingKey {
        case supportedProtocols = "supported_protocols"
    }
}
