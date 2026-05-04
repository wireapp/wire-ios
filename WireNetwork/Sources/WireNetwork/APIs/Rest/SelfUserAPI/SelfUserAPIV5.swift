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

class SelfUserAPIV5: SelfUserAPIV4 {

    override var apiVersion: APIVersion {
        .v5
    }

    override func pushSupportedProtocols(_ supportedProtocols: Set<MessageProtocol>) async throws {
        let encoder = JSONEncoder.defaultEncoder
        let payload =
            SupportedProtocolsPayloadV5(supportedProtocols: Set(supportedProtocols.map { $0.toNetworkModel() }))
        let body = try encoder.encode(payload)
        let path = resourcePath + "/supported-protocols"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (_, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok)
            .parse(code: response.statusCode, data: nil)
    }

}

struct SupportedProtocolsPayloadV5: Encodable {
    let supportedProtocols: Set<MessageProtocolV0>

    enum CodingKeys: String, CodingKey {
        case supportedProtocols = "supported_protocols"
    }
}
