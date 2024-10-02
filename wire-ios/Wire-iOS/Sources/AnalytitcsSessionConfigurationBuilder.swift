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

import WireSyncEngine

/// A builder struct for creating an `AnalyticsSessionConfiguration` instance.
///
/// This struct helps in constructing an instance of `AnalyticsSessionConfiguration`
/// by fetching the required properties (`countlyKey` and `host`) from the appropriate sources.
/// If either of these properties is unavailable, the builder returns `nil`.
struct AnalyticsSessionConfigurationBuilder {

    func build() -> AnalyticsSessionConfiguration? {
        let countlyKey = Bundle.countlyAppKey
        let host = BackendEnvironment.shared.countlyURL

        if let countlyKey, let host {
            return AnalyticsSessionConfiguration(
                countlyKey: countlyKey,
                host: host
            )
        } else {
            return nil
        }
    }
}
