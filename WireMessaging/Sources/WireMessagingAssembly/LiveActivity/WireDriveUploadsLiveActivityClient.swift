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
    func start(with state: WireDriveUploadsActivityState) throws

    func update(with state: WireDriveUploadsActivityState) async

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async
}

@MainActor
final class ActivityKitUploadsActivityClient: WireDriveUploadsActivityClient {

    typealias Attributes = WireDriveUploadsActivityAttributes

    private let staleInterval: TimeInterval
    private var activity: Activity<Attributes>? = Activity<Attributes>.activities.first

    init(staleInterval: TimeInterval = 5 * 60) {
        self.staleInterval = staleInterval
    }

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var hasActivity: Bool {
        activity != nil
    }

    func start(with state: WireDriveUploadsActivityState) throws {
        activity = try Activity.request(
            attributes: Attributes(),
            content: content(for: state),
            pushType: nil
        )
    }

    func update(with state: WireDriveUploadsActivityState) async {
        await activity?.update(content(for: state))
    }

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async {
        let policy: ActivityUIDismissalPolicy = switch dismissal {
        case .immediately: .immediate
        case let .after(interval): .after(Date().addingTimeInterval(interval))
        case .systemDefault: .default
        }

        await activity?.end(state.map { ActivityContent(state: $0, staleDate: nil) }, dismissalPolicy: policy)
        activity = nil
    }

    private func content(for state: WireDriveUploadsActivityState) -> ActivityContent<WireDriveUploadsActivityState> {
        ActivityContent(state: state, staleDate: Date().addingTimeInterval(staleInterval))
    }
}
