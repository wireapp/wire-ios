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
import WireUtilities

public extension ZMUser {

    /// Retrieves all users (excluding bots), having ZMConnectionStatusAccepted connection statuses.
    @objc internal static var predicateForConnectedNonBotUsers: NSPredicate {
        predicateForUsers(withSearch: "", connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }

    /// Retrieves connected users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query and ZMConnectionStatusAccepted connection statuses
    @objc(predicateForConnectedUsersWithSearchString:)
    static func predicateForConnectedUsers(withSearch query: String) -> NSPredicate {
        predicateForUsers(withSearch: query, connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }

    static func predicateForConnectedUsers(
        withSearch query: String,
        hostedOnDomain domain: String
    ) -> NSPredicate {
        predicateForUsers(
            withSearch: query,
            connectionStatuses: [ZMConnectionStatus.accepted.rawValue]
        )
        .and(NSPredicate.isHostedOnDomain(domain))
    }

    /// Retrieves all users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query
    static func predicateForAllUsers(withSearch query: String) -> NSPredicate {
        predicateForUsers(withSearch: query, connectionStatuses: nil)
    }

    /// Retrieves users with name or handle matching search string, having one of given connection statuses
    ///
    /// - Parameters:
    ///   - query: search string
    ///   - connectionStatuses: an array of connections status of the users. E.g. for connected users it is
    /// [ZMConnectionStatus.accepted.rawValue]
    /// - Returns: predicate having search query and supplied connection statuses
    @objc(predicateForUsersWithSearchString:connectionStatusInArray:)
    static func predicateForUsers(withSearch query: String, connectionStatuses: [Int16]?) -> NSPredicate {
        var allPredicates = [[NSPredicate]]()
        if let statuses = connectionStatuses {
            allPredicates.append([predicateForUsers(withConnectionStatuses: statuses)])
        }

        if !query.isEmpty {
            let namePredicate = NSPredicate(
                formatDictionary: [#keyPath(ZMUser.normalizedName): "%K MATCHES %@"],
                matchingSearch: query
            )
            let handlePredicate = NSPredicate(
                format: "%K BEGINSWITH %@",
                #keyPath(ZMUser.handle),
                query.strippingLeadingAtSign()
            )
            allPredicates.append([namePredicate, handlePredicate].compactMap(\.self))
        }

        let orPredicates = allPredicates.map { NSCompoundPredicate(orPredicateWithSubpredicates: $0) }

        return NSCompoundPredicate(andPredicateWithSubpredicates: orPredicates)
    }

    @objc(predicateForUsersWithConnectionStatusInArray:)
    static func predicateForUsers(withConnectionStatuses connectionStatuses: [Int16]) -> NSPredicate {
        NSPredicate(format: "(%K IN (%@))", #keyPath(ZMUser.connection.status), connectionStatuses)
    }

    static func predicateForUsersToUpdateRichProfile() -> NSPredicate {
        NSPredicate(format: "(%K == YES)", #keyPath(ZMUser.needsRichProfileUpdate))
    }

    static func predicateForUsersArePendingToRefreshMetadata() -> NSPredicate {
        NSPredicate(format: "%K == YES", #keyPath(ZMUser.isPendingMetadataRefresh))
    }

    internal static func predicateForUsersWithOneOnOneConversation() -> NSPredicate {
        NSPredicate(format: "%K != nil", #keyPath(ZMUser.oneOnOneConversation))
    }

    static func predicateForConnectedUsers(hostedOnDomain domain: String) -> NSPredicate {
        NSPredicate.isHostedOnDomain(domain)
            .and(predicateForUsers(withConnectionStatuses: [ZMConnectionStatus.accepted.rawValue]))
    }

    static func predicateForSentAndPendingConnections(hostedOnDomain domain: String) -> NSPredicate {
        NSPredicate.isHostedOnDomain(domain)
            .and(predicateForUsers(withConnectionStatuses: [
                ZMConnectionStatus.pending.rawValue,
                ZMConnectionStatus.sent.rawValue
            ]))
    }

}

// MARK: - Domain

private extension NSPredicate {

    static func isHostedOnDomain(_ domain: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@",
            #keyPath(ZMUser.domain),
            domain
        )
    }

}
