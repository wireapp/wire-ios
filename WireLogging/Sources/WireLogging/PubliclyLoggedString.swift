//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

// TODO: [WPB-14297] Remove this file and create `WireLogInterpolation.appendInterpolation` overloads.
/*
/// A type which is only used during migrating to the new logging.
public struct PubliclyLoggedString {

    fileprivate let value: String

    public init(_ value: String) {
        self.value = value
    }
}

public extension WireLogInterpolation {

    @available(*, deprecated, message: "Overload `WireLogInterpolation.appendInterpolation` instead.")
    mutating func appendInterpolation(_ publiclyLoggedString: PubliclyLoggedString) {
        writeText(publiclyLoggedString.value)
    }
}

// MARK: -

// The following extension ensures no WireLogging consuming code needs to be changed for now.

public extension WireLogInterpolation {

    @available(*, deprecated, message: "Overload `WireLogInterpolation.appendInterpolation` instead.")
    mutating func appendInterpolation(_ value: String) {
        writeText(value)
    }
}
*/
