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

import CoreData
import Dispatch

/// If the team has an image set, this use cases retrieves it.
/// If no team image data is available, a string value with the team name's initials will be returned.
@MainActor
public protocol GetTeamAccountImageSourceUseCaseProtocol {

    // TODO: fix doc
    /// <#Description#>
    /// - Parameters:
    ///   - user: <#user description#>
    ///   - userContext: <#userContext description#>
    ///   - account: <#account description#>
    /// - Returns: <#description#>
    func invoke(
        user: some UserType,
        userContext: NSManagedObjectContext?,
        account: Account
    ) async throws -> AccountImageSource
}
