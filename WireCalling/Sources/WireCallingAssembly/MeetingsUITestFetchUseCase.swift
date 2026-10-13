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

#if DEBUG
    import Foundation
    import notify
    import WireCallingDomain
    import WireFoundation

    /// TC-11947 uses Darwin notification state to control fetches from the separate UI test process.
    /// This tests loading, failure, and retry UI without changing the device's network connection.
    actor MeetingsUITestFetchUseCase: FetchUpcomingMeetingsUseCaseProtocol {
        private let wrapped: any FetchUpcomingMeetingsUseCaseProtocol
        private let token: Int32

        init(wrapping wrapped: any FetchUpcomingMeetingsUseCaseProtocol, failureID: String) {
            self.wrapped = wrapped
            let name = "\(UITestConfig.meetingsFailureNotificationPrefix).\(failureID)"
            var token: Int32 = NOTIFY_TOKEN_INVALID
            precondition(notify_register_check(name, &token) == NOTIFY_STATUS_OK)
            self.token = token
        }

        deinit {
            notify_cancel(token)
        }

        func invoke(pageSize: Int, offset: Int) async throws -> PaginatedMeetings {
            // The test controls each transition: pending (0), failed (1), restored (2).
            var state: UInt64 = 0
            repeat {
                precondition(notify_get_state(token, &state) == NOTIFY_STATUS_OK)
                if state == 0 {
                    try await Task.sleep(for: .milliseconds(100))
                }
            } while state == 0
            guard state == 2 else {
                throw URLError(.notConnectedToInternet)
            }
            return try await wrapped.invoke(pageSize: pageSize, offset: offset)
        }
    }
#endif
