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

/// A configuration for the *Prevent Adminless Groups* feature.

public struct PreventAdminlessGroupsFeatureConfig: Equatable, Sendable, Hashable {

    /// The feature's status.

    public let status: FeatureConfigStatus

    /// How the backend selects an admin candidate when
    /// automatic promotion is needed. (alphabetical / random / all)

    public let promotionStrategy: String

    /// Number of days before a group without an admin is deleted.

    public let deletionTimeout: Int

    /// Days before deletion at which the system sends reminder notifications.

    public let reminderTimeouts: [Int]

    public init(
        status: FeatureConfigStatus,
        promotionStrategy: String,
        deletionTimeout: Int,
        reminderTimeouts: [Int]
    ) {
        self.status = status
        self.promotionStrategy = promotionStrategy
        self.deletionTimeout = deletionTimeout
        self.reminderTimeouts = reminderTimeouts
    }

}
