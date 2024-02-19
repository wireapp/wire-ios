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

import Foundation

// sourcery: AutoMockable
/// Determines if the self user has is Proteus verified.
public protocol IsSelfUserProteusVerifiedUseCaseProtocol {
    /// Returns `true` if the self user is verified, `false` otherwise.
    func invoke() async -> Bool
}

public struct IsSelfUserProteusVerifiedUseCase: IsSelfUserProteusVerifiedUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let schedule: NSManagedObjectContext.ScheduledTaskType

    public init(
        context: NSManagedObjectContext,
        schedule: NSManagedObjectContext.ScheduledTaskType
    ) {
        self.context = context
        self.schedule = schedule
    }

    public func invoke() async -> Bool {
        await context.perform(schedule: schedule) {
            ZMUser.selfUser(in: context)
                .allClients
                .allSatisfy(\.verified)
        }
    }
}
