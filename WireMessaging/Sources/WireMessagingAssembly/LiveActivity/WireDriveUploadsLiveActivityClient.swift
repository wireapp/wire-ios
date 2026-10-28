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
import Foundation
import WireDriveUploadsLiveActivity
import WireLogging

/// How long a finished activity stays on screen.
enum WireDriveUploadsActivityDismissal: Equatable {
    case immediately
    case after(TimeInterval)
    case systemDefault
}

@MainActor
protocol WireDriveUploadsActivityClient: AnyObject {

    /// Whether the user allows Live Activities.
    var areActivitiesEnabled: Bool { get }

    /// Whether an activity is showing, including one that was started before the app was relaunched.
    var hasActivity: Bool { get }

    /// Starts the activity. ActivityKit only allows this while the app is in the foreground.
    func start(with state: WireDriveUploadsActivityState) async throws

    func update(with state: WireDriveUploadsActivityState) async

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async

    /// Immediately removes every uploads activity, including finished results still on the lock screen.
    func endAll() async
}

@MainActor
final class ActivityKitUploadsActivityClient: WireDriveUploadsActivityClient {

    typealias Attributes = WireDriveUploadsActivityAttributes

    private let staleInterval: TimeInterval

    private var activity: Activity<Attributes>? = Activity<Attributes>.activities.first {
        $0.activityState == .active || $0.activityState == .stale
    }

    private var endedActivities: [Activity<Attributes>] = []

    init(staleInterval: TimeInterval = .thirtySeconds) {
        self.staleInterval = staleInterval
    }

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var hasActivity: Bool {
        activity != nil
    }

    func start(with state: WireDriveUploadsActivityState) async throws {
        // A retry or a new batch replaces the previous lock-screen result.
        await endAll()
        activity = try Activity.request(
            attributes: Attributes(),
            content: content(for: state),
            pushType: nil
        )
    }

    func update(with state: WireDriveUploadsActivityState) async {
        guard let activity else { return }
        await dismissActivities(except: activity.id)
        await activity.update(content(for: state))
    }

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async {
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

    func endAll() async {
        await dismissActivities()
    }

    private func dismissActivities(except activityID: String? = nil) async {
        // Discover activities from previous launches too, and retain ended ones so their lock-screen
        // cards can be dismissed even after they are no longer returned by ActivityKit.
        var activities = Dictionary(
            Activity<Attributes>.activities.map { ($0.id, $0) },
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

    private func content(for state: WireDriveUploadsActivityState) -> ActivityContent<WireDriveUploadsActivityState> {
        ActivityContent(state: state, staleDate: Date().addingTimeInterval(staleInterval))
    }
}
