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

public extension Worker {

    /// Creates a `Worker` that checks if the current build is blacklisted and executes `onIsBuildBlacklisted` callback
    /// if it is.
    static func checkBlacklist(
        useCase: any IsBuildBlacklistedUseCase,
        onIsBuildBlacklisted: @escaping @Sendable () -> Void
    ) -> Worker {
        Worker(
            work: {
                let (isBuildBlacklisted, error) = await useCase.invoke()

                if isBuildBlacklisted {
                    onIsBuildBlacklisted()
                }

                return error == nil
            },
            interval: .oneHour * 6,
            trigger: Worker.defaultTrigger()
        )
    }

}
