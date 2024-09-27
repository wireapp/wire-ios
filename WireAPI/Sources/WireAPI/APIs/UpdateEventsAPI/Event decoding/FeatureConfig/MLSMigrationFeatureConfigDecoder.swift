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

struct MLSMigrationFeatureConfigDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<FeatureConfigEventCodingKeys>
    ) throws -> MLSMigrationFeatureConfig {
        let payload = try container.decode(
            FeatureWithConfig<Payload>.self,
            forKey: .payload
        )

        return MLSMigrationFeatureConfig(
            status: payload.status,
            startTime: payload.config.startTime?.date,
            finaliseRegardlessAfter: payload.config.finaliseRegardlessAfter?.date
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        let startTime: UTCTime?
        let finaliseRegardlessAfter: UTCTime?
    }
}
