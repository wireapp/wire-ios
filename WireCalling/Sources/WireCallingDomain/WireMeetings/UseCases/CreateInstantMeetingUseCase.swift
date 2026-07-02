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

package import WireFoundation

import Foundation

package struct CreateInstantMeetingUseCase: CreateInstantMeetingUseCaseProtocol {

    private let repository: any MeetingRepositoryProtocol
    private let dateProvider: any CurrentDateProviding

    package init(
        repository: any MeetingRepositoryProtocol,
        dateProvider: any CurrentDateProviding
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    package func invoke(title: String) async throws -> Meeting {
        let now = dateProvider.now
        return try await repository.createMeeting(
            title: title,
            startTime: now,
            endTime: now.addingTimeInterval(60 * 60), // duration 1h
            recurrence: nil
        )
    }

}
