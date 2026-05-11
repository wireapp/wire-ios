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

import Foundation
public import UIKit

/// A abstraction around UIApplication's background tasks
/// methods.
///
/// This is intented to be used only within the main app target
/// (via UIApplication) and not the app extensions (use
/// `NoOpBackgroundTaskManager` instead.)
public protocol BackgroundTaskManager {

    func beginBackgroundTask(
        withName: String?,
        expirationHandler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)

}

public extension BackgroundTaskManager {

    func beginBackgroundTask(
        withName: String?
    ) -> UIBackgroundTaskIdentifier {
        beginBackgroundTask(
            withName: withName,
            expirationHandler: nil
        )
    }

}

extension UIApplication: BackgroundTaskManager {}

/// A background task manager that does nothing.
///
/// Since the BackgroundTaskManager is only intended to be
/// used from a main app target, this implementation can be used
/// when running in an app extension.
public struct NoOpBackgroundTaskManager: BackgroundTaskManager {

    public init() {}

    public func beginBackgroundTask(
        withName: String?,
        expirationHandler: (@MainActor () -> Void)?
    ) -> UIBackgroundTaskIdentifier {
        UIBackgroundTaskIdentifier.invalid
    }

    public func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        // No op
    }

}
