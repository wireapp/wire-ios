//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel

protocol ConversationCreationValuesConfigurable: AnyObject {

    func configure(with values: ConversationCreationValues)

}

final class ConversationCreationValues {

    // MARK: - Properties

    private var unfilteredParticipants: UserSet
    private let selfUser: UserType

    let isChannel: Bool
    let isAppsFeatureEnabled: Bool
    var channelHistoryDepth: String?
    var name: String
    var allowGuests: Bool
    var allowApps: Bool
    var enableReceipts: Bool
    var enableFileManagement: Bool
    var encryptionProtocol: MessageProtocol

    var participants: UserSet {
        get {
            var result = unfilteredParticipants

            if !allowGuests {
                let noGuests = result.filter { $0.isOnSameTeam(otherUser: selfUser) }
                result = UserSet(noGuests)
            }

            if !allowApps {
                let noAppsOrBots = result.filter { !$0.isAppOrBot }
                result = UserSet(noAppsOrBots)
            }

            return result
        }
        set {
            unfilteredParticipants = newValue
        }
    }

    // MARK: - Life cycle

    init(
        isChannel: Bool,
        isAppsFeatureEnabled: Bool,
        name: String = "",
        participants: UserSet = UserSet(),
        allowGuests: Bool = true,
        allowApps: Bool = true,
        enableReceipts: Bool = true,
        enableFileManagement: Bool = false,
        encryptionProtocol: MessageProtocol,
        selfUser: UserType
    ) {
        self.isChannel = isChannel
        self.isAppsFeatureEnabled = isAppsFeatureEnabled
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.allowApps = isAppsFeatureEnabled ? allowApps : false
        self.enableReceipts = enableReceipts
        self.enableFileManagement = enableFileManagement
        self.encryptionProtocol = encryptionProtocol
        self.selfUser = selfUser
    }

}
