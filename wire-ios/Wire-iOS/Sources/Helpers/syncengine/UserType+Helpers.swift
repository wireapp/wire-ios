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
import WireSyncEngine

typealias ConversationCreatedBlock = (Result<ZMConversation, Error>) -> Void

extension UserType {

    var pov: PointOfView {
        return self.isSelfUser ? .secondPerson : .thirdPerson
    }

    var isPendingApproval: Bool {
        return isPendingApprovalBySelfUser || isPendingApprovalByOtherUser
    }

    var hasUntrustedClients: Bool {
        return allClients.contains { !$0.verified }
    }

    func createTeamOneToOneConversation(
        in context: NSManagedObjectContext,
        completion: @escaping ConversationCreatedBlock
    ) {
        guard
            self.isTeamMember,
            let user = self.materialize(in: context)
        else {
            return
        }
        let conversationService = ConversationService(context: context)

        conversationService.createTeamOneToOneConversation(user: user) { result in
            switch result {
            case .success(let conversation):
                completion(.success(conversation))

            case .failure(let error):
                WireLogger.conversation.error("failed to create one to one conversation: \(String(describing: error))")
                completion(.failure(error))
            }
        }
    }

}
