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

import XCTest
import WireDataModel
@testable import WireRequestStrategy

class FetchMLSConversationGroupInfoActionHandlerTests: BaseFetchMLSGroupInfoActionHandlerTests<FetchMLSConversationGroupInfoAction, FetchMLSConversationGroupInfoActionHandler> {

    override func setUp() {
        super.setUp()
        action = FetchMLSConversationGroupInfoAction(conversationId: conversationId, domain: domain)
        handler = FetchMLSConversationGroupInfoActionHandler(context: syncMOC)
    }

    func test_itGeneratesARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/conversations/\(domain)/\(conversationId.transportString())/groupinfo",
            expectedMethod: .get,
            expectedAcceptType: .messageMLS,
            apiVersion: .v5
        )
    }

    func test_itDoesntGenerateRequests_APIV4() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v4,
            expectedError: .endpointUnavailable
        )
    }

}
