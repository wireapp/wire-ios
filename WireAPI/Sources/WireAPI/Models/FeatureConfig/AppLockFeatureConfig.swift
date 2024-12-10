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

/// A configuration for the *App Lock* feature.

public struct AppLockFeatureConfig: Codable, Equatable, Sendable {

    /// The feature's status.

    public let status: FeatureConfigStatus

    /// Whether the app lock is mandatorily enabled.

    public let isMandatory: Bool

    /// The number of seconds in the background before
    /// the app should relock.

    public let inactivityTimeoutInSeconds: UInt

}
