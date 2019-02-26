////
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

extension MockTransportSession {
    
    @objc(fetchUserWithIdentifier:)
    public func fetchUser(withIdentifier identifier: String) -> MockUser? {
        let request = MockUser.sortedFetchRequest(withPredicate: NSPredicate(format: "%K == %@", #keyPath(MockUser.identifier), identifier.lowercased()))
        let users = try? managedObjectContext.fetch(request)
        
        return users?.first
    }
    
    @objc(processRichProfileFetchForUser:)
    public func processRichProfileFetchFor(user userID: String) -> ZMTransportResponse {
        guard let user = fetchUser(withIdentifier: userID) else { return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil) }
        if let members = self.selfUser.currentTeamMembers {
            guard members.contains(user) else {
                return ZMTransportResponse(payload: ["label": "insufficient-permissions"] as NSDictionary, httpStatus: 403, transportSessionError: nil)
            }
        }
        
        let fields = user.richProfile ?? []
        return ZMTransportResponse(payload: ["fields" : fields ] as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
}
