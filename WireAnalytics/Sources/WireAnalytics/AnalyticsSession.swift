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

import UIKit

// sourcery: AutoMockable
/// Protocol for managing and tracking analytics events within a session.
public protocol AnalyticsSessionProtocol {

    /// Tracks a specific analytics event.
    /// - Parameter event: The `AnalyticsEvent` to be tracked.
    ///
    /// This method logs the given event as part of the current analytics session.
    func trackEvent(_ event: AnalyticsEvent)

}

struct AnalyticsSession: AnalyticsSessionProtocol {

    let isSelfTeamMember: Bool
    let service: any CountlyProtocol

    func trackEvent(_ event: AnalyticsEvent) {
        var segmentation = event.segmentation
        segmentation.insert(.isSelfTeamMember(isSelfTeamMember))
        segmentation.insert(.deviceModel(UIDevice.current.model))
        segmentation.insert(.deviceOS(UIDevice.current.systemVersion))

        let rawSegmentation = Dictionary(uniqueKeysWithValues: event.segmentation.map {
            ($0.key, $0.value)
        })

        service.recordEvent(
            event.name,
            segmentation: rawSegmentation
        )
    }

}
