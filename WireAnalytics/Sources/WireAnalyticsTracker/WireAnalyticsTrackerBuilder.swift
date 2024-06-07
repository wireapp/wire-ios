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

import DatadogLogs
import Foundation

public struct WireAnalyticsTrackerBuilder {

    private let bundle: Bundle
    // private let environment: BackendEnvironment
    private let level: LogLevel

    public init(
        bundle: Bundle = .main,// .wireCommonComponents,
        // environment: BackendEnvironment = .shared,
        level: LogLevel = .debug
    ) {
        self.bundle = bundle
        // self.environment = environment
        self.level = level
    }

    public func build() -> WireAnalyticsTracker? {
//        guard
//            let appID = bundle.infoForKey("DatadogAppId"),
//            let clientToken = bundle.infoForKey("DatadogClientToken")
//        else {
//            assertionFailure("missing Datadog appID and clientToken - logging disabled")
//            return nil
//        }

        return WireAnalyticsTracker(
            appID: "",
            clientToken: "",
            // environment: environment,
            level: level
        )
    }
}
