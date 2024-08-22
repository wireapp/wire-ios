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

struct EndToEndIdentityFeatureConfigDecoder {

    func decode(
        from container: KeyedDecodingContainer<FeatureConfigEventCodingKeys>
    ) throws -> EndToEndIdentityFeatureConfig {
        let payload = try container.decode(
            FeatureWithConfig<Payload>.self,
            forKey: .payload
        )

        return EndToEndIdentityFeatureConfig(
            status: payload.status,
            acmeDiscoveryURL: payload.config.acmeDiscoveryURL,
            verificationExpiration: payload.config.verificationExpiration,
            crlProxy: nil,
            useProxyOnMobile: false
        )
    }

    private struct Payload: Decodable {

        let acmeDiscoveryURL: String?
        let verificationExpiration: UInt

        enum CodingKeys: String, CodingKey {
            case acmeDiscoveryURL = "acmeDiscoveryUrl"
            case verificationExpiration
        }

    }

}
