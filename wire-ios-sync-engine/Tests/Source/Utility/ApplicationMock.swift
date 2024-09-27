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
import WireDataModel
@testable import WireSyncEngine

/// A mock of Application that records the calls
@objcMembers
public final class ApplicationMock: NSObject {
    public var applicationState: UIApplication.State = .active
    public var deviceToken: Data?
    public var userSession: ZMUserSession?
    public var pushTokenService: PushTokenServiceInterface?

    /// Records calls to `registerForRemoteNotification`
    public var registerForRemoteNotificationCount = 0

    /// The current badge icon number
    public var applicationIconBadgeNumber = 0

    // Returns YES if the application is currently registered for remote notifications
    public var isRegisteredForRemoteNotifications = false

    /// Records calls to `setMinimumBackgroundFetchInterval`
    public var minimumBackgroundFetchInverval: TimeInterval = UIApplication.backgroundFetchIntervalNever

    /// Callback invoked when `registerUserNotificationSettings` is invoked
    public var registerForRemoteNotificationsCallback: () -> Void = {}
}

// MARK: - Application protocol

extension ApplicationMock: ZMApplication {
    public func registerForRemoteNotifications() {
        registerForRemoteNotificationCount += 1
        registerForRemoteNotificationsCallback()
        updateDeviceToken()
    }

    public func setMinimumBackgroundFetchInterval(_ minimumBackgroundFetchInterval: TimeInterval) {
        minimumBackgroundFetchInverval = minimumBackgroundFetchInterval
    }
}

// MARK: - Observers

extension ApplicationMock {
    public func registerObserverForDidBecomeActive(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    public func registerObserverForWillResignActive(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    public func registerObserverForWillEnterForeground(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    public func registerObserverForDidEnterBackground(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    public func registerObserverForApplicationWillTerminate(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    public func unregisterObserverForStateChange(_ object: NSObject) {
        NotificationCenter.default.removeObserver(object, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(object, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(
            object,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            object,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(object, name: UIApplication.willTerminateNotification, object: nil)
    }
}

// MARK: - Simulate application state change

extension ApplicationMock {
    public func simulateApplicationDidBecomeActive() {
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    public func simulateApplicationWillResignActive() {
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
    }

    public func simulateApplicationWillEnterForeground() {
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public func simulateApplicationDidEnterBackground() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    public func simulateApplicationWillTerminate() {
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
    }

    var isInBackground: Bool {
        applicationState == .background
    }

    @objc
    func setBackground() {
        applicationState = .background
    }

    var isInactive: Bool {
        applicationState == .inactive
    }

    @objc
    func setInactive() {
        applicationState = .inactive
    }

    var isActive: Bool {
        applicationState == .active
    }

    @objc
    func setActive() {
        applicationState = .active
    }

    public func updateDeviceToken() {
        if let token = deviceToken {
            pushTokenService?.storeLocalToken(.createAPNSToken(from: token))
        }
    }
}
