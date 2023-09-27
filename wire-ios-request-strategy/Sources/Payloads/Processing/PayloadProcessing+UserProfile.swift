// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension Payload.UserProfiles {

    /// Update all user entities with the data from the user profiles.
    ///
    /// - parameter context: `NSManagedObjectContext` on which the update should be performed.
    func updateUserProfiles(in context: NSManagedObjectContext) {
        let processor = UserProfilePayloadProcessor()

        for userProfile in self {
            guard
                let id = userProfile.id ?? userProfile.qualifiedID?.uuid,
                let user = ZMUser.fetch(with: id, domain: userProfile.qualifiedID?.domain, in: context)
            else {
                continue
            }

            processor.updateUserProfile(
                from: userProfile,
                for: user
            )
        }
    }

}
