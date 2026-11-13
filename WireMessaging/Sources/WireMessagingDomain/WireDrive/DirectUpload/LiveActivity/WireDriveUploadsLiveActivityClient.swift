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

@preconcurrency import ActivityKit
package import Foundation
import WireLogging

/// How long a finished activity stays on screen.
package enum WireDriveUploadsActivityDismissal: Equatable {
    case immediately
    case after(TimeInterval)
    case systemDefault
}

@MainActor
package protocol WireDriveUploadsActivityClient: AnyObject {

    /// Whether the user allows Live Activities.
    var areActivitiesEnabled: Bool { get }

    /// Whether an activity is showing, including one that was started before the app was relaunched.
    var hasActivity: Bool { get }

    /// Starts the activity. ActivityKit only allows this while the app is in the foreground.
    func start(with state: WireDriveUploadsActivityState) async throws

    func update(with state: WireDriveUploadsActivityState) async

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async

    /// Immediately removes the account's uploads activities, including finished lock-screen results.
    func endAll() async
}

/// The ActivityKit operations used by the account-scoped client.
@MainActor
protocol WireDriveUploadsActivity: AnyObject {
    var id: String { get }
    var attributes: WireDriveUploadsActivityAttributes { get }
    var activityState: ActivityState { get }

    func update(_ content: ActivityContent<WireDriveUploadsActivityState>) async
    func end(
        _ content: ActivityContent<WireDriveUploadsActivityState>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async
}

@MainActor
private final class ActivityKitUploadsActivity: WireDriveUploadsActivity {

    private let activity: Activity<WireDriveUploadsActivityAttributes>

    init(_ activity: Activity<WireDriveUploadsActivityAttributes>) {
        self.activity = activity
    }

    var id: String { activity.id }
    var attributes: WireDriveUploadsActivityAttributes { activity.attributes }
    var activityState: ActivityState { activity.activityState }

    func update(_ content: ActivityContent<WireDriveUploadsActivityState>) async {
        await activity.update(content)
    }

    func end(
        _ content: ActivityContent<WireDriveUploadsActivityState>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        await activity.end(content, dismissalPolicy: dismissalPolicy)
    }
}

@MainActor
package final class ActivityKitUploadsActivityClient: WireDriveUploadsActivityClient {

    typealias Attributes = WireDriveUploadsActivityAttributes

    private let accountInfo: WireDriveAccountInfo
    private let attributes: Attributes
    private let staleInterval: TimeInterval
    private let activities: () -> [any WireDriveUploadsActivity]
    private let requestActivity: (
        Attributes,
        ActivityContent<WireDriveUploadsActivityState>
    ) throws -> any WireDriveUploadsActivity

    private var activity: (any WireDriveUploadsActivity)?

    private var endedActivities: [any WireDriveUploadsActivity] = []

    package convenience init(accountInfo: WireDriveAccountInfo) {
        self.init(accountInfo: accountInfo, staleInterval: .thirtySeconds)
    }

    init(
        accountInfo: WireDriveAccountInfo,
        staleInterval: TimeInterval = .thirtySeconds,
        activities: @escaping () -> [any WireDriveUploadsActivity] = {
            Activity<Attributes>.activities.map { ActivityKitUploadsActivity($0) }
        },
        requestActivity: @escaping (
            Attributes,
            ActivityContent<WireDriveUploadsActivityState>
        ) throws -> any WireDriveUploadsActivity = {
            try ActivityKitUploadsActivity(Activity<Attributes>.request(attributes: $0, content: $1, pushType: nil))
        }
    ) {
        self.accountInfo = accountInfo
        self.attributes = Attributes(accountInfo: accountInfo)
        self.staleInterval = staleInterval
        self.activities = activities
        self.requestActivity = requestActivity
        self.activity = activities().first {
            $0.attributes.userID == accountInfo
                .userID && ($0.activityState == .active || $0.activityState == .stale)
        }
    }

    package var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    package var hasActivity: Bool {
        guard let activity else { return false }
        return activity.activityState == .active || activity.activityState == .stale
    }

    package func start(with state: WireDriveUploadsActivityState) async throws {
        // A retry or a new batch replaces the previous lock-screen result.
        await endAll()
        activity = try requestActivity(attributes, content(for: state))
    }

    package func update(with state: WireDriveUploadsActivityState) async {
        guard let activity else { return }
        await dismissActivities(except: activity.id)
        await activity.update(content(for: state))
    }

    package func end(
        with state: WireDriveUploadsActivityState?,
        dismissal: WireDriveUploadsActivityDismissal
    ) async {
        let policy: ActivityUIDismissalPolicy = switch dismissal {
        case .immediately: .immediate
        case let .after(interval): .after(Date().addingTimeInterval(interval))
        case .systemDefault: .default
        }

        guard let activity else { return }
        await activity.end(state.map { ActivityContent(state: $0, staleDate: nil) }, dismissalPolicy: policy)
        if dismissal != .immediately {
            endedActivities.append(activity)
        }
        self.activity = nil
    }

    package func endAll() async {
        await dismissActivities()
    }

    private func dismissActivities(except activityID: String? = nil) async {
        // Discover activities from previous launches too, and retain ended ones so their lock-screen
        // cards can be dismissed even after they are no longer returned by ActivityKit.
        var activities = Dictionary(
            activities().filter { $0.attributes.userID == accountInfo.userID }.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for activity in endedActivities {
            activities[activity.id] = activity
        }
        if let activity {
            activities[activity.id] = activity
        }
        if activity?.id != activityID {
            activity = nil
        }
        endedActivities = []

        for activity in activities.values where activity.id != activityID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func content(for state: WireDriveUploadsActivityState)
        -> ActivityContent<WireDriveUploadsActivityState> {
        ActivityContent(state: state, staleDate: Date().addingTimeInterval(staleInterval))
    }
}
