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

    actor MeetingsUITestUpdateUseCase: UpdateMeetingUseCaseProtocol {
        private let wrapped: any UpdateMeetingUseCaseProtocol
        private let token: Int32

        init(wrapping wrapped: any UpdateMeetingUseCaseProtocol, failureID: String) {
            self.wrapped = wrapped
            let name = "\(UITestConfig.meetingsUpdateFailureNotificationPrefix).\(failureID)"
            var token: Int32 = NOTIFY_TOKEN_INVALID
            precondition(notify_register_check(name, &token) == NOTIFY_STATUS_OK)
            self.token = token
        }

        deinit {
            notify_cancel(token)
        }

        func invoke(
            meeting: Meeting,
            title: String,
            startTime: Date,
            endTime: Date,
            recurrence: MeetingRecurrence?,
            participants: [MeetingMember],
            emailsToAdd: [String],
            emailsToRemove: [String]
        ) async throws -> Meeting {
            // Darwin notification state controls a failure in the app process before the real update request.
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
            return try await wrapped.invoke(
                meeting: meeting,
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence,
                participants: participants,
                emailsToAdd: emailsToAdd,
                emailsToRemove: emailsToRemove
            )
        }

        func fetchInvitedEmails(for meeting: Meeting) async throws -> [String] {
            try await wrapped.fetchInvitedEmails(for: meeting)
        }

        func updateConversationName(for meeting: Meeting) async throws {
            try await wrapped.updateConversationName(for: meeting)
        }
    }
#endif
