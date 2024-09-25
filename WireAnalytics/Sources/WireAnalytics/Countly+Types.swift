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

public typealias WireCountly = Countly
public typealias WireCountlyConfig = CountlyConfig

public final class Countly {

    public init() {
        fatalError()
    }

    public static func sharedInstance() -> Self {
        fatalError()
    }

    public class func user() -> CountlyUserDetails {
        fatalError()
    }

    public func user() -> Void {
        fatalError()
    }

    public func start(with config: CountlyConfig) {
        fatalError()
    }

    public func recordEvent(_ name: String, segmentation: [String: String]?) {
        fatalError()
    }

    public func changeDeviceID(withMerge id: String) {
        fatalError()
    }

    public func changeDeviceIDWithoutMerge(_ id: String) {
        fatalError()
    }

    public func beginSession() {
        fatalError()
    }

    public func endSession() {
        fatalError()
    }

    public func setNewDeviceID(_ analyticsIdentifier: String, onServer: Bool) {
        fatalError()
    }

    public func updateSession() {
        fatalError()
    }
}

public final class CountlyConfig {
    public var appKey = ""
    public var manualSessionHandling = false
    public var host = ""
    public var deviceID = ""
    public var urlSessionConfiguration: URLSessionConfiguration?

    public init() {}
}

public final class CountlyUserDetails {
    public func set(
        _ key: String,
        value: String
    ){
        fatalError()
    }
    public func unSet(_ key: String) {
        fatalError()
    }
    public func save() {
        fatalError()
    }
}
