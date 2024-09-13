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

extension ZMUser {
    /// **Problem:**
    /// The domain of a backend changed, so the self user has an old and invalid domain,
    /// which causes requests to federated endpoints to fail.
    ///
    /// **Solution:**
    /// Refetch the self user's domain.

    static func refetchSelfUserDomain(in context: NSManagedObjectContext) {
        let selfUser = selfUser(in: context)
        // Only if the domain is `nil` will we store the domain discovered on the backend.
        // After that, we don't expect it to change and may crash the app if it does.
        selfUser.domain = nil
        selfUser.needsToBeUpdatedFromBackend = true
    }
}
