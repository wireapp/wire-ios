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

public import Foundation

/// Information needed to enable analytics tracking.

public struct AnalyticsServiceConfiguration {

    /// The secret key used to connect to the analytics server.

    public let secretKey: String

    /// The url of the analytics server.

    public let serverHost: URL

    /// Create a new `AnalyticsServiceConfiguration`.
    ///
    /// - Parameters:
    ///   - secretKey: The secret key used to connect to the analytics server.
    ///   - serverHost: The url of the analytics server.

    public init(
        secretKey: String,
        serverHost: URL
    ) {
        self.secretKey = secretKey
        self.serverHost = serverHost
    }

}
