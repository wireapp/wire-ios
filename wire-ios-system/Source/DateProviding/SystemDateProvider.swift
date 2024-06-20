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

extension CurrentDateProviding where Self == SystemDateProvider {

    /// Returns a new instance of `SystemDateProvider`.
    public static var system: Self { .init() }
}

/// Provides date values based on the system clock.
public struct SystemDateProvider: CurrentDateProviding {

    public var now: Date { .now }

    public init() {}
}
