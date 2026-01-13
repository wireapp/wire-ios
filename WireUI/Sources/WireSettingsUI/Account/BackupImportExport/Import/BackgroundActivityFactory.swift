//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public import UIKit


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

public final class BackgroundActivityFactory: NSObject {

    /// Get the shared instance.
    nonisolated(unsafe) public static let shared: BackgroundActivityFactory = .init()

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
    public var backgroundTaskTimeout: TimeInterval = 5
    var backgroundTaskTimer: Timer?

    public override init() {
        super.init()
        registerForNotifications()
    }

    // MARK: - Starting Background Activities

    /// Starts a background activity if possible.
    /// - parameter name: The name of the task, for debugging purposes.
    /// - returns: A token representing the activity, if the background execution is available.
    /// - warning: If this method returns `nil`, you should **not** perform the work you are planning to do.

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
        guard activityManager != nil else {
            return
        }

        let activities = isolationQueue.sync {
            self.activities
        }
        activities.forEach { activity in
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
            allTasksEndedHandlers.forEach { handler in
                handler()
            }
        }

        // No need to keep any activities after finishing
        activities.removeAll()
        if let currentBackgroundTask {
            if let activityManager {

                activityManager.endBackgroundTask(currentBackgroundTask)
            } else {
                // no-op
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

// MARK: --------------------

/// A token that represents an active background task.

nonisolated(unsafe) private var activityCounter = 0
private let activityCounterQueue = DispatchQueue(label: "wire-transport.background-activity-counter")

public final class BackgroundActivity: NSObject {

    /// The name of the task, used for debugging purposes.
    @objc public let name: String
    /// Globally unique index of background activity
    public let index: Int

    /// The block of code called from the main thead when the background timer is about to expire.
    @objc public var expirationHandler: (() -> Void)?

    init(name: String, expirationHandler: (() -> Void)?) {
        self.name = name
        self.expirationHandler = expirationHandler
        // Increment counter with overflow (used in .description)
        self.index = activityCounterQueue.sync {
            activityCounter &+= 1
            return activityCounter
        }
    }

    // MARK: - Execution

    /// Executes the task.
    /// - parameter block: The block to execute with extended lifetime.
    /// - parameter activity: A reference to the current activity, so you can stop it before your block returns.
    ///
    /// You can take advantage of this method to make sure you don't execute code when background execution
    /// is no longer available, with nil-coleascing.
    ///
    /// For example, when you request:
    ///
    /// ~~~swift
    /// BackgroundActivityFactory.shared.startBackgroundActivity(name: "Test")?.execute {
    ///     defer { BackgroundActivityFactory.shared.endBackgroundActivity($0) }
    ///     // perform the long task
    ///     print("Hello background world")
    /// }
    /// ~~~
    ///
    /// If the app is being suspended, the code will not be executed at all.

    @objc(executeBlock:)
    public func execute(block: @escaping (_ activity: BackgroundActivity) -> Void) {
        block(self)
    }

    // MARK: - Hashable

    public override var hash: Int {
        ObjectIdentifier(self).hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherActivity = object as? BackgroundActivity else {
            return false
        }

        return ObjectIdentifier(self) == ObjectIdentifier(otherActivity)
    }

    public override var description: String {
        "<BackgroundActivity [\(index)]: \(name)>"
    }
}

// MARK: -----------

/// A protocol for objects that can start and end background activities.

@objc
public protocol BackgroundActivityManager: NSObjectProtocol {
    /// Begin a background task.
    func beginBackgroundTask(withName name: String?, expirationHandler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier

    /// End the background task.
    func endBackgroundTask(_ task: UIBackgroundTaskIdentifier)

    // Make sure to only access this from main thread!
    var backgroundTimeRemaining: TimeInterval { get }
    var applicationState: UIApplication.State { get }
}

extension BackgroundActivityManager {
    /// Returns application state and background time remaining
    /// This code should be called from main queue only!
    var stateDescription: String {
        if applicationState == .background {
            // Sometimes time remaining is very large even if we run in background
            let time = backgroundTimeRemaining > 100_000 ? "No Limit" : String(format: "%.2f", backgroundTimeRemaining)
            return "App state: \(applicationState), time remaining: \(time)"
        } else {
            return "App state: \(applicationState)"
        }
    }
}


// TODO: Check if @MainActor is ok to be applied here
extension UIApplication: @MainActor BackgroundActivityManager {

}
