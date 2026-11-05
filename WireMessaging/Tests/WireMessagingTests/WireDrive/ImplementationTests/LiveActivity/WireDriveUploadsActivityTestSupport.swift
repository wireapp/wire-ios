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

@testable import WireMessagingDomain

/// Holds a delay until the test lets it pass.
actor UploadsDelayGate {

    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

@MainActor
final class FakeUploadsActivityClient: WireDriveUploadsActivityClient {

    enum Call: Equatable {
        case start(WireDriveUploadsActivityState)
        case update(WireDriveUploadsActivityState)
        case end(WireDriveUploadsActivityState?, WireDriveUploadsActivityDismissal)
        case endAll
    }

    var areActivitiesEnabled = true
    var hasActivity = false
    var startError: (any Error)?
    private(set) var calls: [Call] = []

    func start(with state: WireDriveUploadsActivityState) async throws {
        if let startError { throw startError }
        calls.append(.start(state))
        hasActivity = true
    }

    func update(with state: WireDriveUploadsActivityState) async {
        calls.append(.update(state))
    }

    func end(with state: WireDriveUploadsActivityState?, dismissal: WireDriveUploadsActivityDismissal) async {
        calls.append(.end(state, dismissal))
        hasActivity = false
    }

    func endAll() async {
        calls.append(.endAll)
        hasActivity = false
    }
}
