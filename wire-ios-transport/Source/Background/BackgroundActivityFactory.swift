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

import UIKit
import WireUtilities

/// Manages the creation and lifecycle of background tasks.
///
/// To improve the behavior of the app in background contexts, this object starts and stops a single background task,
/// and associates "tokens" to these tasks to keep track of the progress, and handles expiration automatically.
///
/// When you request background activity:
/// - if there is no active activity: we create a new UIKit background task and save a token
/// - if there are current active activities: we reuse the active UIKit task and save a token
///
/// When you end a background activity manually:
/// - if the activity was the last in the list: we tell UIKit that the background task ended and remove the token from
/// the list
/// - if there are still other activities in the list: we remove the token from the list
///
/// When the system sends a background time expiration warning:
/// 1. We notify all the task tokens that they will expire soon, and give them an opportunity to clean up before the app
/// gets suspended
/// 2. We end the active background task and block new activities from starting

@objc
public final class BackgroundActivityFactory: NSObject {
    /// Get the shared instance.
    @objc(sharedFactory) public static let shared = BackgroundActivityFactory()

    // MARK: - Configuration

    /// The activity manager to use to.
    @objc public weak var activityManager: BackgroundActivityManager?

    // MARK: - State

    /// Whether any tasks are active.
    @objc public var isActive: Bool {
        isolationQueue.sync {
            hasValidCurrentBackgroundTask
        }
    }

    private var hasValidCurrentBackgroundTask: Bool {
        currentBackgroundTask != nil && currentBackgroundTask != UIBackgroundTaskIdentifier.invalid
    }

    @objc var mainQueue: DispatchQueue = .main
    private let isolationQueue = DispatchQueue(label: "BackgroundActivityFactory.IsolationQueue")

    var currentBackgroundTask: UIBackgroundTaskIdentifier?
    var activities: Set<BackgroundActivity> = []
    var allTasksEndedHandlers: [() -> Void] = []

    /// The upper limit for how long backgrounds tasks are allowed to run
    public var backgroundTaskTimeout: TimeInterval = 60
    var backgroundTaskTimer: Timer?

    override public init() {
        super.init()
        registerForNotifications()
    }

    // MARK: - Starting Background Activities

    /// Starts a background activity if possible.
    /// - parameter name: The name of the task, for debugging purposes.
    /// - returns: A token representing the activity, if the background execution is available.
    /// - warning: If this method returns `nil`, you should **not** perform the work yu are planning to do.

    @objc(startBackgroundActivityWithName:)
    public func startBackgroundActivity(name: String) -> BackgroundActivity? {
        startActivityIfPossible(name, nil)
    }

    /// Starts a background activity if possible.
    /// - parameter name: The name of the task, for debugging purposes.
    /// - parameter expirationHandler: The code to execute to clean up the state as the app is about to be suspended.
    /// This value can be set later.
    /// - warning: If this method returns `nil`, you should **not** perform the work you are planning to do.

    @objc(startBackgroundActivityWithName:expirationHandler:)
    public func startBackgroundActivity(
        name: String,
        expirationHandler: @escaping (() -> Void)
    ) -> BackgroundActivity? {
        startActivityIfPossible(name, expirationHandler)
    }

    /// Notifies when all background activites have completed or expired.
    /// - parameter completionHandler: The code to exectute when the background activites are completed. The execution
    /// happens on the main queue.
    ///
    /// If there are no running background tasks the completion handler will be called immediately.
    public func notifyWhenAllBackgroundActivitiesEnd(completionHandler: @escaping (() -> Void)) {
        isolationQueue.sync {
            guard hasValidCurrentBackgroundTask else {
                return completionHandler()
            }

            allTasksEndedHandlers.append(completionHandler)
        }
    }

    // MARK: - Management

    /// Call this method when the app resumes from foreground.

    @objc
    public func resume() {
        isolationQueue.sync {
            if currentBackgroundTask == UIBackgroundTaskIdentifier.invalid {
                WireLogger.backgroundActivity.info(
                    "Resume: currentBackgroundTask is invalid, setting it to nil",
                    attributes: .safePublic
                )
                currentBackgroundTask = nil
            }
        }
    }

    /// Ends the activity and the active background task if possible.
    /// - parameter activity: The activity to end.

    @objc
    public func endBackgroundActivity(_ activity: BackgroundActivity) {
        isolationQueue.sync {
            guard currentBackgroundTask != UIBackgroundTaskIdentifier.invalid else {
                return
            }

            activities.remove(activity)
            if activities.isEmpty {
                finishBackgroundTask()
            }
        }
    }

    // MARK: - Helpers

    /// Starts the background activity of the system allows it.
    private func startActivityIfPossible(_ name: String, _ expirationHandler: (() -> Void)?) -> BackgroundActivity? {
        isolationQueue.sync {
            let activityName = ActivityName(name: name)
            guard let activityManager else {
                return nil
            }

            // Do not start new tasks if the background timer is running.
            guard currentBackgroundTask != UIBackgroundTaskIdentifier.invalid else {
                return nil
            }

            // Try to create the task
            let activity = BackgroundActivity(name: name, expirationHandler: expirationHandler)

            if currentBackgroundTask == nil {
                let task = activityManager.beginBackgroundTask(withName: name, expirationHandler: handleExpiration)
                guard task != UIBackgroundTaskIdentifier.invalid else {
                    WireLogger.backgroundActivity.info(
                        "Start activity <\(activityName)>: failed to begin new background task",
                        attributes: .safePublic
                    )
                    return nil
                }
                currentBackgroundTask = task
            }

            activities.insert(activity)
            return activity
        }
    }

    /// Called on main queue when the background timer is about to expire.
    private func handleExpiration() {
        guard let activityManager else {
            WireLogger.backgroundActivity.warn(
                "Handle expiration: failed, activityManager is nil",
                attributes: .safePublic
            )
            return
        }

        let activities = isolationQueue.sync {
            self.activities
        }
        for activity in activities {
            activity.expirationHandler?()
        }
        isolationQueue.sync {
            finishBackgroundTask()
            currentBackgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    /// Ends the current background task.
    private func finishBackgroundTask() {
        let allTasksEndedHandlers = allTasksEndedHandlers
        self.allTasksEndedHandlers.removeAll()
        mainQueue.async {
            for handler in allTasksEndedHandlers {
                handler()
            }
        }

        // No need to keep any activities after finishing
        activities.removeAll()
        if let currentBackgroundTask {
            if let activityManager {
                // We might get killed pretty soon, let's flush the logs
                ZMSLog.sync()
                activityManager.endBackgroundTask(currentBackgroundTask)
            } else {
                WireLogger.backgroundActivity.warn(
                    "Finishing background task: failed, activityManager is nil",
                    attributes: .safePublic
                )
            }
            self.currentBackgroundTask = nil
        }
        stopTimer()
    }

    // MARK: - Change in application state

    /// Register for change in application state: didEnterBackground
    func registerObserverForDidEnterBackground(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    /// Register for change in application state: willEnterForeground
    func registerObserverForWillEnterForeground(_ object: NSObject, selector: Selector) {
        NotificationCenter.default.addObserver(
            object,
            selector: selector,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func registerForNotifications() {
        registerObserverForDidEnterBackground(self, selector: #selector(startTimer))
        registerObserverForWillEnterForeground(self, selector: #selector(stopTimer))
    }

    @objc
    private func startTimer() {
        guard backgroundTaskTimer == nil else { return }

        backgroundTaskTimer = Timer.scheduledTimer(
            withTimeInterval: backgroundTaskTimeout,
            repeats: false,
            block: { [weak self] timer in
                self?.mainQueue.async { [weak self] in
                    WireLogger.backgroundActivity.info(
                        "Handle expiration when the background task has timed out",
                        attributes: .safePublic
                    )
                    self?.handleExpiration()
                    timer.invalidate()
                }
            }
        )
    }

    @objc
    private func stopTimer() {
        backgroundTaskTimer?.invalidate()
        backgroundTaskTimer = nil
    }
}
