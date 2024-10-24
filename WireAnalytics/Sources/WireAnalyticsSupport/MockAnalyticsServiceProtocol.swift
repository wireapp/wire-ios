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
import WireAnalytics

// this mock is generated manually because of (any Error)?
// TODO: [WPB-11829] update sourcery
public class MockAnalyticsServiceProtocol: AnalyticsServiceProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isTrackingEnabled

    public var isTrackingEnabled: Bool {
        get { return underlyingIsTrackingEnabled }
        set(value) { underlyingIsTrackingEnabled = value }
    }

    public var underlyingIsTrackingEnabled: Bool!


    // MARK: - enableTracking

    public var enableTracking_Invocations: [Void] = []
    public var enableTracking_MockError: (any Error)?
    public var enableTracking_MockMethod: (() async throws -> Void)?

    public func enableTracking() async throws {
        enableTracking_Invocations.append(())

        if let error = enableTracking_MockError {
            throw error
        }

        guard let mock = enableTracking_MockMethod else {
            fatalError("no mock for `enableTracking`")
        }

        try await mock()
    }

    // MARK: - disableTracking

    public var disableTracking_Invocations: [Void] = []
    public var disableTracking_MockError: (any Error)?
    public var disableTracking_MockMethod: (() throws -> Void)?

    public func disableTracking() throws {
        disableTracking_Invocations.append(())

        if let error = disableTracking_MockError {
            throw error
        }

        guard let mock = disableTracking_MockMethod else {
            fatalError("no mock for `disableTracking`")
        }

        try mock()
    }

    // MARK: - switchUser

    public var switchUser_Invocations: [AnalyticsUser] = []
    public var switchUser_MockError: (any Error)?
    public var switchUser_MockMethod: ((AnalyticsUser) throws -> Void)?

    public func switchUser(_ user: AnalyticsUser) throws {
        switchUser_Invocations.append(user)

        if let error = switchUser_MockError {
            throw error
        }

        guard let mock = switchUser_MockMethod else {
            fatalError("no mock for `switchUser`")
        }

        try mock(user)
    }

    // MARK: - updateCurrentUser

    public var updateCurrentUser_Invocations: [AnalyticsUser] = []
    public var updateCurrentUser_MockError: (any Error)?
    public var updateCurrentUser_MockMethod: ((AnalyticsUser) throws -> Void)?

    public func updateCurrentUser(_ user: AnalyticsUser) throws {
        updateCurrentUser_Invocations.append(user)

        if let error = updateCurrentUser_MockError {
            throw error
        }

        guard let mock = updateCurrentUser_MockMethod else {
            fatalError("no mock for `updateCurrentUser`")
        }

        try mock(user)
    }

    // MARK: - trackEvent

    public var trackEvent_Invocations: [AnalyticsEvent] = []
    public var trackEvent_MockMethod: ((AnalyticsEvent) -> Void)?

    public func trackEvent(_ event: AnalyticsEvent) {
        trackEvent_Invocations.append(event)

        guard let mock = trackEvent_MockMethod else {
            fatalError("no mock for `trackEvent`")
        }

        mock(event)
    }

}
