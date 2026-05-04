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
public import WireAnalytics
public import Countly

public struct CountlyWrapper: CountlyProtocol {

    var countly: () -> Countly

    public init(countly: @escaping @autoclosure () -> Countly = .sharedInstance()) {
        self.countly = countly
    }

    public func resetInstance() {
        countly().resetInstance()
    }

    public func start(
        appKey: String,
        host: URL
    ) {
        let config = CountlyConfig()
        config.appKey = appKey
        config.manualSessionHandling = true
        config.host = host.absoluteString
        countly().start(with: config)
    }

    public func setUserValue(
        _ value: String?,
        forKey key: String
    ) {
        if let value {
            Countly.user().set(key, value: value)
        } else {
            Countly.user().unSet(key)
        }
    }

    public func changeDeviceID(
        _ id: String,
        mergeData: Bool
    ) {
        if mergeData {
            countly().changeDeviceID(withMerge: id)
        } else {
            countly().changeDeviceIDWithoutMerge(id)
        }
    }

    public func beginSession() {
        countly().beginSession()
    }

    public func endSession() {
        countly().endSession()
    }

    public func deviceID() -> String {
        countly().deviceID()
    }

    public func recordEvent(
        _ key: String,
        segmentation: [String: String]?
    ) {
        countly().recordEvent(key, segmentation: segmentation)
    }

}
