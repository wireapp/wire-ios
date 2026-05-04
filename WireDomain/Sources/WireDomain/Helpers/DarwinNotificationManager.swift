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

public enum DarwinNotification {
    public static let didRequestPushChannelAccess = "com.wire.didRequestPushChannelAccess"
    public static let didReleasePushChannelAccess = "com.wire.didReleasePushChannelAccess"
}

public class DarwinNotificationManager {
    public init() {}

    private var callbacks: [String: () -> Void] = [:]

    /// Post an in inter-process Darwin notification.
    ///
    /// You can post this notification in one process (such as the main app) observe observe
    /// it from another process (such as an app extension).
    public func postNotification(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(notificationCenter, CFNotificationName(name as CFString), nil, nil, true)
    }

    /// Observe inter-process Darwin notification.
    /// - Parameters:
    ///   - name: name of the notification
    ///   - callback: block to execute when notification is received
    /// - Note: setting the callback will remove previous callbacks for the same notification
    public func startObserving(name: String, callback: @escaping () -> Void) {
        callbacks[name] = callback

        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

        CFNotificationCenterAddObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            DarwinNotificationManager.notificationCallback,
            name as CFString,
            nil,
            .deliverImmediately
        )
    }

    public func stopObserving(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(name as CFString),
            nil
        )
        callbacks.removeValue(forKey: name)
    }

    private static let notificationCallback: CFNotificationCallback = { _, observer, name, _, _ in
        guard let observer else { return }
        let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()

        if let name = name?.rawValue as String?, let callback = manager.callbacks[name] {
            callback()
        }
    }
}
