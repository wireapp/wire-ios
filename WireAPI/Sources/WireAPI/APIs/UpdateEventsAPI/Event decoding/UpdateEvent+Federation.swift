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

extension UpdateEvent {

    init(
        eventType: FederationEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: FederationEventCodingKeys.self)

        switch eventType {
        case .connectionRemoved:
            let event = try container.decodeConnectionRemovedEvent()
            self = .federation(.connectionRemoved(event))

        case .delete:
            let event = try container.decodeDeleteEvent()
            self = .federation(.delete(event))
        }
    }

}

private enum FederationEventCodingKeys: String, CodingKey {

    case payload = "data"

}

// MARK: - Federation connection removed

private extension KeyedDecodingContainer<FederationEventCodingKeys> {

    func decodeConnectionRemovedEvent() throws -> FederationConnectionRemovedEvent {
        let payload = try decode(FederationConnectionRemovedEventPayload.self, forKey: .payload)
        return FederationConnectionRemovedEvent(domains: payload.domains)
    }

    private struct FederationConnectionRemovedEventPayload: Decodable {

        let domains: Set<String>

    }

}

// MARK: - Federation delete

private extension KeyedDecodingContainer<FederationEventCodingKeys> {

    func decodeDeleteEvent() throws -> FederationDeleteEvent {
        let payload = try decode(FederationDeleteEventPayload.self, forKey: .payload)
        return FederationDeleteEvent(domain: payload.domain)
    }

    private struct FederationDeleteEventPayload: Decodable {

        let domain: String

    }

}
