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

public struct AVSVideoStreams: Encodable, Equatable {
    let conversationId: String
    let clients: [AVSClientVideoStream]

    enum CodingKeys: String, CodingKey {
        case conversationId = "convid"
        case clients
    }
}

public enum AVSStreamQuality: Int, Codable {
    case any = 0 // any resolution (avs decides)
    case low = 1 // low quality resolution
    case high = 2 // high quality resolution

    var debugDescription: String {
        String(describing: self)
    }
}

public struct AVSClientVideoStream: Encodable, Equatable, Hashable {
    public let userId: String
    public let clientId: String
    public let quality: AVSStreamQuality

    enum CodingKeys: String, CodingKey {
        case userId = "userid"
        case clientId = "clientid"
        case streamQuality = "quality"
    }

    public init(
        client: AVSClient,
        quality: AVSStreamQuality = .any
    ) {
        self.userId = client.userId
        self.clientId = client.clientId
        self.quality = quality
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(quality.rawValue, forKey: .streamQuality)
    }
}
