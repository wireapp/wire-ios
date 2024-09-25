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
import WireAnalytics

public class MockCountlyConfigAbstraction: CountlyConfigAbstraction {

    // MARK: - Life cycle

    public required init() {}

    // MARK: - appKey

    public var appKey: String {
        get { underlyingAppKey }
        set(value) { underlyingAppKey = value }
    }

    public var underlyingAppKey: String!

    // MARK: - manualSessionHandling

    public var manualSessionHandling: Bool {
        get { underlyingManualSessionHandling }
        set(value) { underlyingManualSessionHandling = value }
    }

    public var underlyingManualSessionHandling: Bool!

    // MARK: - host

    public var host: String {
        get { underlyingHost }
        set(value) { underlyingHost = value }
    }

    public var underlyingHost: String!

    // MARK: - deviceID

    public var deviceID: String {
        get { underlyingDeviceID }
        set(value) { underlyingDeviceID = value }
    }

    public var underlyingDeviceID: String!

    // MARK: - urlSessionConfiguration

    public var urlSessionConfiguration: URLSessionConfiguration {
        get { underlyingUrlSessionConfiguration }
        set(value) { underlyingUrlSessionConfiguration = value }
    }

    public var underlyingUrlSessionConfiguration: URLSessionConfiguration!
}
