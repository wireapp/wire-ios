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

import WireFoundation

import Foundation

// MARK: - Predefined entries

extension AnalyticsEvent.Segmentation {

    /// Creates a ``Segmentation`` for indicating the device OS version of the user.
    ///
    /// - Parameter value: A string indicating device OS version of the user
    /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

    static func osVersion(_ value: String) -> Self {
        .init(key: "os_version", value: value)
    }

    /// Creates a ``Segmentation`` for indicating the device model of the user
    ///
    /// - Parameter value: A string indicating device model of the user
    /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

    static func deviceModel(_ value: String) -> Self {
        .init(key: "device_model", value: value)
    }

    /// Creates a ``Segmentation`` for the type of contribution in a conversation.
    ///
    /// - Parameter value: The `ContributionType` of the contribution.
    /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

    static func contributionType(_ value: ConversationContributionType) -> Self {
        .init(key: "contribution_type", value: value.analyticsValue)
    }

    /// Creates a ``Segmentation`` for the score of the calling survey
    ///
    /// - Parameter value: The score from 1 to 5.
    /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

    static func callScore(_ value: Int) -> Self {
        .init(key: "score", value: String(value))
    }

    /// Creates a ``Segmentation`` for the label of the calling survey
    /// - Parameter value: The label
    /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

    static func callLabel(_ value: String) -> Self {
        .init(key: "label", value: value)
    }
}
