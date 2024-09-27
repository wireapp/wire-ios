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

struct UserClientAddEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserClientAddEvent {
        let payload = try container.decode(
            Payload.self,
            forKey: .client
        )

        return UserClientAddEvent(
            client: UserClient(
                id: payload.id,
                type: payload.type,
                activationDate: payload.activationDate.date,
                label: payload.label,
                model: payload.model,
                deviceClass: payload.deviceClass,
                lastActiveDate: payload.lastActiveDate?.date,
                mlsPublicKeys: payload.mlsPublicKeys,
                cookie: payload.cookie,
                capabilities: payload.capabilities?.capabilities ?? []
            )
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case activationDate = "time"
            case label
            case model
            case deviceClass = "class"
            case lastActiveDate = "last_active"
            case mlsPublicKeys = "mls_public_keys"
            case cookie
            case capabilities
        }

        let id: String
        let type: UserClientType
        let activationDate: UTCTimeMillis
        let label: String?
        let model: String?
        let deviceClass: DeviceClass?
        let lastActiveDate: UTCTime?
        let mlsPublicKeys: MLSPublicKeys?
        let cookie: String?
        let capabilities: CapabilitiesList?
    }

    private struct CapabilitiesList: Decodable {
        let capabilities: [UserClientCapability]
    }
}
