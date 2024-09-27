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

// MARK: - URLSessionsDirectory

@objc
public protocol URLSessionsDirectory: NSObjectProtocol {
    @objc var foregroundSession: ZMURLSession { get }
    @objc var backgroundSession: ZMURLSession { get }
    @objc var allSessions: [ZMURLSession] { get }
}

// MARK: - CurrentURLSessionsDirectory

@objcMembers
public final class CurrentURLSessionsDirectory: NSObject, URLSessionsDirectory {
    // MARK: Lifecycle

    public init(foregroundSession: ZMURLSession, backgroundSession: ZMURLSession) {
        self.foregroundSession = foregroundSession
        self.backgroundSession = backgroundSession
    }

    // MARK: Public

    public var foregroundSession: ZMURLSession
    public var backgroundSession: ZMURLSession

    public var allSessions: [ZMURLSession] {
        [foregroundSession, backgroundSession]
    }
}

// MARK: TearDownCapable

extension CurrentURLSessionsDirectory: TearDownCapable {
    public func tearDown() {
        foregroundSession.tearDown()
        backgroundSession.tearDown()
    }
}
