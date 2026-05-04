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

public struct NetworkQualityPayload: Decodable {

    enum CandidateType: String, Decodable {
        case relay = "Relay"
        case host = "Host"
        case srflx = "Srflx"
        case prflx = "Prflx"
        case unknown = "Unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = CandidateType(rawValue: value) ?? .unknown
        }
    }

    enum ProtocolType: String, Decodable {
        case udp = "UDP"
        case tcp = "TCP"
        case unknown = "Unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = ProtocolType(rawValue: value) ?? .unknown
        }
    }

    enum PeerType: String, Decodable {
        case server = "Server"
        case user = "User"
        case unknown = "Unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = PeerType(rawValue: value) ?? .unknown
        }
    }

    struct PacketLoss: Decodable {
        let tx: Double?
        let rx: Double?
    }

    struct StreamJitter: Decodable {
        let tx: Double?
        let rx: Double?
    }

    struct Jitter: Decodable {
        let audio: StreamJitter?
        let video: StreamJitter?
    }

    struct Connection: Decodable {
        let candidate: CandidateType?
        let protocolType: ProtocolType?

        private enum CodingKeys: String, CodingKey {
            case candidate
            case protocolType = "protocol"
        }
    }

    let quality: Int32
    let rtt: Double?
    let loss: PacketLoss?
    let jitter: Jitter?
    let connection: Connection?
    let peer: PeerType?

}
