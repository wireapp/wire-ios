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

class FetchMLSSubconversationGroupInfoActionHandlerTests: BaseFetchMLSGroupInfoActionHandlerTests<FetchMLSSubconversationGroupInfoAction, FetchMLSSubconversationGroupInfoActionHandler> {

    let subgroupType: SubgroupType = .conference

    override func setUp() {
        super.setUp()
        action = FetchMLSSubconversationGroupInfoAction(conversationId: conversationId, domain: domain, subgroupType: subgroupType)
    }

    func test_itGeneratesARequest_APIV4() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v4/conversations/\(domain)/\(conversationId.transportString())/subconversations/\(subgroupType.rawValue)/groupinfo",
            expectedMethod: .methodGET,
            apiVersion: .v4
        )
    }

    func test_itDoesntGenerateRequests_APIV3() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v3,
            expectedError: .endpointUnavailable
        )
    }

}
