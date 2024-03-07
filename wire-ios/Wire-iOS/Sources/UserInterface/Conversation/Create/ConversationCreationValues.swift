//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    var name: String
    var allowGuests: Bool
    var allowServices: Bool
    var enableReceipts: Bool
    var encryptionProtocol: Feature.MLS.Config.MessageProtocol

    var participants: UserSet {
        get {
            var result = unfilteredParticipants

            if !allowGuests {
                let noGuests = result.filter { $0.isOnSameTeam(otherUser: selfUser) }
                result = UserSet(noGuests)
            }

            if !allowServices {
                let noServices = result.filter { !$0.isServiceUser }
                result = UserSet(noServices)
            }

            return result
        }
        set {
            unfilteredParticipants = newValue
        }
    }

    // MARK: - Life cycle

    init(
        name: String = "",
        participants: UserSet = UserSet(),
        allowGuests: Bool = true,
        allowServices: Bool = true,
        enableReceipts: Bool = true,
        encryptionProtocol: Feature.MLS.Config.MessageProtocol,
        selfUser: UserType
    ) {
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.allowServices = allowServices
        self.enableReceipts = enableReceipts
        self.encryptionProtocol = encryptionProtocol
        self.selfUser = selfUser
    }

}
