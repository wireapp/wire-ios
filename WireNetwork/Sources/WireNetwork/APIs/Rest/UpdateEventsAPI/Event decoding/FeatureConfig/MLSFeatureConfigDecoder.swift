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

struct MLSFeatureConfigDecoder {

    func decode(
        from container: KeyedDecodingContainer<FeatureConfigEventCodingKeys>
    ) throws -> MLSFeatureConfig {
        let payload = try container.decode(
            FeatureWithConfig<Payload>.self,
            forKey: .payload
        )

        let supportedProtocols = payload.config.supportedProtocols.map { $0.toAPIModel() }

        return MLSFeatureConfig(
            status: payload.status.toAPIModel(),
            protocolToggleUsers: payload.config.protocolToggleUsers,
            defaultProtocol: payload.config.defaultProtocol.toAPIModel(),
            allowedCipherSuites: payload.config.allowedCipherSuites.map { $0.toAPIModel() },
            defaultCipherSuite: payload.config.defaultCipherSuite.toAPIModel(),
            supportedProtocols: Set(supportedProtocols)
        )
    }

    private struct Payload: Decodable {

        let protocolToggleUsers: Set<UUID>
        let defaultProtocol: MessageProtocolV0
        let allowedCipherSuites: [MLSCipherSuiteV0]
        let defaultCipherSuite: MLSCipherSuiteV0
        let supportedProtocols: Set<MessageProtocolV0>

    }

}
