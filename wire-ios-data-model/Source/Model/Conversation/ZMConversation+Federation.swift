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

extension ZMConversation {
    public func isFederating(with user: UserType) -> Bool {
        guard
            let domain,
            let userDomain = user.domain
        else {
            return false
        }

        return domain != userDomain
    }

    public static func groupConversations(
        hostedOnDomain domain: String,
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        let predicate: NSPredicate = .isGroupConversation.and(.isHostedOnDomain(domain))
        let request = sortedFetchRequest(with: predicate)
        return context.fetchOrAssert(request: request) as? [ZMConversation] ?? []
    }

    public static func groupConversations(
        notHostedOnDomains domains: [String],
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        let predicate: NSPredicate = .isGroupConversation.and(.isNotHostedOnDomains(domains))
        let request = sortedFetchRequest(with: predicate)
        return context.fetchOrAssert(request: request) as? [ZMConversation] ?? []
    }
}

extension NSPredicate {
    fileprivate static var isGroupConversation: NSPredicate {
        hasConversationType(.group)
    }

    fileprivate static func hasConversationType(_ type: ZMConversationType) -> NSPredicate {
        NSPredicate(
            format: "%K == %d",
            ZMConversationConversationTypeKey,
            type.rawValue
        )
    }

    fileprivate static func isHostedOnDomain(_ domain: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@",
            ZMConversationDomainKey,
            domain
        )
    }

    fileprivate static func isNotHostedOnDomains(_ domains: [String]) -> NSPredicate {
        isHostedOnAnyDomain(domains).inverse
    }

    fileprivate static func isHostedOnAnyDomain(_ domains: [String]) -> NSPredicate {
        NSPredicate(
            format: "%K IN %@",
            ZMConversationDomainKey,
            domains
        )
    }
}
