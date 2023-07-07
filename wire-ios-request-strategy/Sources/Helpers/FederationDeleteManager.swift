////
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

final public class FederationDeleteManager {
    private weak var syncContext: NSManagedObjectContext?

    public init(syncContext: NSManagedObjectContext? = nil) {
        self.syncContext = syncContext
    }

    public func backendStoppedFederatingWithDomain(domain: String) {
        // !@#$%^&*(
        // search all conversations hosted on X:
        guard let moc = syncContext else { return }
        let conversations = ZMConversation.existingConversationsHostedOnDomain(domain: domain,
                                                                               moc: moc)
        print(conversations)

        // remove myself & all users from MY

        // add system message about stopping federation

        // add system message about removing myself & otherUser
//        search all conversations hosted on MY that has members from X:
//            - add system message about stopping federation
//            - remove members from X
//            - add system message about removing members
//        search all connected users from X
//            - delete connection
    }

    func domainsStoppedFederating(domains: [String]) {

    }
}
