////
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

extension MockTransportSession {

    @objc(fetchConversationWithIdentifier:)
    public func fetchConversation(with identifier: String) -> MockConversation? {
        let request = MockConversation.sortedFetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", identifier.lowercased())
        let conversations = managedObjectContext.executeFetchRequestOrAssert(request) as? [MockConversation]
        return conversations?.first
    }

    @objc(processAccessModeUpdateForConversation:payload:)
    public func processAccessModeUpdate(for conversationId: String, payload: [String : AnyHashable]) -> ZMTransportResponse {
        if let conversation = fetchConversation(with: conversationId) {

            guard let accessRole = payload["access_role"] as? String else {
                return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
            }
            guard let access = payload["access"] as? [String] else {
                return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
            }

            conversation.accessRole = accessRole
            conversation.accessMode = access

            let responsePayload = [
                "conversation" : conversation.identifier,
                "type" : "conversation.access-update",
                "time" : NSDate().transportString(),
                "from" : selfUser.identifier,
                "data" : [
                    "access_role" : conversation.accessRole,
                    "access" : conversation.accessMode
                ]
            ] as ZMTransportData
            return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)
        } else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
    }
}
