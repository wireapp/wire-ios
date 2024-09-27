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

/// A builder of `PushChannelAPI`.

public struct PushChannelAPIBuilder {
    // MARK: Lifecycle

    /// Create a new builder.
    ///
    /// - Parameter pushChannelService: A push channel service to execute requests.

    public init(pushChannelService: PushChannelService) {
        self.pushChannelService = pushChannelService
    }

    // MARK: Public

    /// Make a `PushChannelAPI`.
    ///
    /// - Returns: A `PushChannelAPI`.

    public func makeAPI() -> any PushChannelAPI {
        PushChannelAPIImpl(pushChannelService: pushChannelService)
    }

    // MARK: Private

    private let pushChannelService: PushChannelService
}
