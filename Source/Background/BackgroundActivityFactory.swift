//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "background-activity")

/**
 * Manages the creation and lifecycle of background tasks.
 *
 * To improve the behavior of the app in background contexts, this object starts and stops a single background task,
 * and associates "tokens" to these tasks to keep track of the progress, and handles expiration automatically.
 *
 * When you request background activity:
 * - if there is no active activity: we create a new UIKit background task and save a token
 * - if there are current active activities: we reuse the active UIKit task and save a token
 *
 * When you end a background activity manually:
 * - if the activity was the last in the list: we tell UIKit that the background task ended and remove the token from the list
 * - if there are still other activities in the list: we remove the token from the list
 *
 * When the system sends a background time expiration warning:
 * 1. We notify all the task tokens that they will expire soon, and give them an opportunity to clean up before the app gets suspended
 * 2. We end the active background task and block new activities from starting
 */

@objc public final class BackgroundActivityFactory: NSObject {

    /// Get the shared instance.
    @objc(sharedFactory)
    public static let shared: BackgroundActivityFactory = BackgroundActivityFactory()

    // MARK: - Configuration

    /// The activity manager to use to.
    @objc public weak var activityManager: BackgroundActivityManager? = nil

    // MARK: - State

    /// Whether any tasks are active.
    @objc public var isActive: Bool {
        return isolationQueue.sync {
            return self.currentBackgroundTask != nil && self.currentBackgroundTask != UIBackgroundTaskInvalid
        }
    }

    @objc var mainQueue: DispatchQueue = .main
    private let isolationQueue = DispatchQueue(label: "BackgroundActivityFactory.IsolationQueue")

    var currentBackgroundTask: UIBackgroundTaskIdentifier?
    var activities: Set<BackgroundActivity> = []

    // MARK: - Starting Background Activities

    /**
     * Starts a background activity if possible.
     * - parameter name: The name of the task, for debugging purposes.
     * - returns: A token representing the activity, if the background execution is available.
     * - warning: If this method returns `nil`, you should **not** perform the work yu are planning to do.
     */

    @objc(startBackgroundActivityWithName:)
    public func startBackgroundActivity(withName name: String) -> BackgroundActivity? {
        return startActivityIfPossible(name, nil)
    }

    /**
     * Starts a background activity if possible.
     * - parameter name: The name of the task, for debugging purposes.
     * - parameter handler: The code to execute to clean up the state as the app is about to be suspended. This value can be set later.
     * - warning: If this method returns `nil`, you should **not** perform the work yu are planning to do.
     */

    @objc(startBackgroundActivityWithName:expirationHandler:)
    public func startBackgroundActivity(withName name: String, expirationHandler: @escaping (() -> Void)) -> BackgroundActivity? {
        return startActivityIfPossible(name, expirationHandler)
    }

    // MARK: - Management

    /**
     * Call this method when the app resumes from foreground.
     */

    @objc public func resume() {
        isolationQueue.sync {
            if currentBackgroundTask == UIBackgroundTaskInvalid {
                zmLog.debug("Resume: currentBackgroundTask is invalid, setting it to nil")
                currentBackgroundTask = nil
            }
        }
    }

    /**
     * Ends the activity and the active background task if possible.
     * - parameter activity: The activity to end.
     */

    @objc public func endBackgroundActivity(_ activity: BackgroundActivity) {
        isolationQueue.sync {
            guard self.currentBackgroundTask != UIBackgroundTaskInvalid else {
                zmLog.debug("End background activity: current background task is invalid")
                return
            }

            if activities.remove(activity) != nil {
                zmLog.debug("End background activity: removed \(activity), \(activities.count) others left")
            } else {
                zmLog.debug("End background activity: could not remove \(activity), \(activities.count) others left")
            }
            
            if activities.isEmpty {
                zmLog.debug("End background activity: no activities left, finishing")
                finishBackgroundTask()
            }
        }
    }

    // MARK: - Helpers

    /// Starts the background activity of the system allows it.
    private func startActivityIfPossible(_ name: String, _ expirationHandler: (() -> Void)?) -> BackgroundActivity? {
        return isolationQueue.sync {
            // Do not start new tasks if the background timer is running.
            guard currentBackgroundTask != UIBackgroundTaskInvalid else { 
                zmLog.debug("Start activity: failed, currentBackgroundTask is invalid")
                return nil         
            }
            guard let activityManager = activityManager else {
                zmLog.debug("Start activity: failed, activityManager is nil")
                return nil 
            }

            // Try to create the task
            let activity = BackgroundActivity(name: name, expirationHandler: expirationHandler)

            if currentBackgroundTask == nil {
                zmLog.debug("Start activity: no current background task, starting new")
                let task = activityManager.beginBackgroundTask(withName: "BackgroundActivityFactory", expirationHandler: handleExpiration)
                guard task != UIBackgroundTaskInvalid else {
                    zmLog.debug("Start activity: failed to begin new background task")
                    return nil         
                }
                zmLog.debug("Start activity: started new background task")
                currentBackgroundTask = task
            }

            let (inserted, _) = activities.insert(activity)
            if !inserted {
                zmLog.debug("Start activity: could not insert activity \(activity)")
            }
            return activity
        }
    }

    /// Called on main queue when the background timer is about to expire.
    private func handleExpiration() {
        zmLog.debug("Handle expiration")
        let activities = isolationQueue.sync {
            return self.activities
        }
        activities.forEach { activity in
            zmLog.debug("Handle expiration: notifying \(activity)")
            activity.expirationHandler?()
        }
        isolationQueue.sync {
            finishBackgroundTask()
            currentBackgroundTask = UIBackgroundTaskInvalid
        }
    }

    /// Ends the current background task.
    private func finishBackgroundTask() {
        if let currentBackgroundTask = self.currentBackgroundTask {
            if let activityManager = activityManager {
                zmLog.debug("Finishing background task")
                activityManager.endBackgroundTask(currentBackgroundTask)
            } else {
                zmLog.debug("Finishing background task: failed, activityManager is nil")
            }
            self.currentBackgroundTask = nil
        } else {
            zmLog.debug("Finishing background task: no current background task")
        }
    }

}
