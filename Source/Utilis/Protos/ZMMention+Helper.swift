//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ZMMentionBuilder {

    public static func build(_ users: [ZMUser]) -> [ZMMention] {
        var mentions: [ZMMention] = []

        for user in users {
            let builder = ZMMention.builder()!
            builder.setUser(user)
            mentions.append(builder.build()!)
        }

        return mentions
    }

    public func setUser(_ user: ZMUser) {
        setUserId(user.remoteIdentifier!.transportString())
        setUserName(user.name!)
    }

}
