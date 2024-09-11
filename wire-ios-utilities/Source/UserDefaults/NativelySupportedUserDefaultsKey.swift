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

/// With this protocol and the extension to `UserDefaults` we can have "typed" user defaults values.
/// Based on the `ValueType` associated type the implementation in the extension prevents storing other types then the
/// designated one and casts values on reading.
public protocol NativelySupportedUserDefaultsKey {
    associatedtype ValueType // a constraint could be added to only allow supported types
    /*
     From the documentation:
     A default object must be a property list—that is, an instance of (or for collections, a combination of instances of) NSData, NSString, NSNumber, NSDate, NSArray, or NSDictionary. If you want to store any other type of object, you should typically archive it to create an instance of NSData.
     */
    var rawValue: String { get set }
}

// MARK: - UserDefaultsDateValueKey

/// Used to store `Date` values in `UserDefaults`.
public struct UserDefaultsDateValueKey: NativelySupportedUserDefaultsKey {
    public typealias ValueType = Date

    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
