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

/// The AnalyticsSessionConfiguration struct is a configuration object used to initialize and configure an analytics session. 
/// It holds key information required for the analytics system to function, such as the Countly key and the host URL.

public struct AnalyticsSessionConfiguration {

    public let countlyKey: String
    public let host: URL

    public init(countlyKey: String, host: URL) {
        self.countlyKey = countlyKey
        self.host = host
    }
}
