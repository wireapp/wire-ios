//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMConversation {

    func isFederating(with user: UserType) -> Bool {
        guard
            let domain = domain,
            let userDomain = user.domain
        else { return false }

        return domain != userDomain
    }

    public static func groupConversationOwned(by domain: String, in context: NSManagedObjectContext) -> [ZMConversation]? {
        let hostedOnDomainPredicate = NSPredicate(format: "%K == %d AND %K == %@",
                                                  ZMConversationConversationTypeKey,
                                                  ZMConversationType.group.rawValue,
                                                  ZMConversationDomainKey,
                                                  domain)
        let request = self.sortedFetchRequest(with: hostedOnDomainPredicate)

        return context.fetchOrAssert(request: request) as? [ZMConversation]
    }

    public static func groupConversationNotOwned(by domains: [String], in context: NSManagedObjectContext) -> [ZMConversation]? {
        let groupConversationPredicate = NSPredicate(format: "%K == %d",
                                                  ZMConversationConversationTypeKey,
                                                  ZMConversationType.group.rawValue)
        let hostedOnDomainPredicate = NSPredicate(format: "%K IN %@",
                                                  ZMConversationDomainKey,
                                                  domains)
        let notHostedOnDomainPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: hostedOnDomainPredicate)
        let resultPredicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [groupConversationPredicate, notHostedOnDomainPredicate])

        let request = self.sortedFetchRequest(with: resultPredicate)

        return context.fetchOrAssert(request: request) as? [ZMConversation]
    }

}
