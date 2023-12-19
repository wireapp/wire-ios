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

@testable import WireDataModel
@testable import WireDataModelSupport

class MLSConversationVerificationStatusProviderTests: ZMConversationTestsBase {

    var sut: MLSConversationVerificationStatusProvider!
    var e2eIVerificationStatusService: MockE2eIVerificationStatusServiceInterface!
    var mockConversation: ZMConversation!

    override func setUp() {
        super.setUp()

        e2eIVerificationStatusService = MockE2eIVerificationStatusServiceInterface()
        sut = MLSConversationVerificationStatusProvider(e2eIVerificationStatusService: e2eIVerificationStatusService,
                                                        syncContext: syncMOC)
        mockConversation = ZMConversation.insertNewObject(in: syncMOC)
        mockConversation.mlsVerificationStatus = nil
        mockConversation.mlsGroupID = MLSGroupID.random()
    }

    override func tearDown() {
        e2eIVerificationStatusService = nil
        mockConversation = nil
        sut = nil

        super.tearDown()
    }

    func test_itUpdatesConversation_toVerifiedStatus() async {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .verified
        }

        // Given
        mockConversation.mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        mockConversation.mlsVerificationStatus = .notVerified
        let groupID = mockConversation.mlsGroupID

        // When
        await sut.updateStatus(groupID!)

        // Then
        XCTAssertEqual(mockConversation.mlsVerificationStatus, .verified)
    }

    func test_itUpdatesConversation_fromVerifiedToDegraded() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .notVerified
        }

        // Given
        mockConversation.mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        mockConversation.mlsVerificationStatus = .verified
        let groupID = mockConversation.mlsGroupID

        // When
        await sut.updateStatus(groupID!)

        // Then
        XCTAssertEqual(mockConversation.mlsVerificationStatus, .degraded)
    }

//    func test_itDoesNotUpdateConversation_newStatusIsSame() async throws {
//        // Mock
//        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
//            return .notVerified
//        }
//
//        // Given
//        //mockConversation.mlsGroupID = MLSGroupID(Data([1, 2, 3]))
//        mockConversation.mlsVerificationStatus = .notVerified
//        let groupID = mockConversation.mlsGroupID
//
//        // When
//        await sut.updateStatus(groupID!)
//
//        // Then
//        XCTAssertEqual(mockConversation.mlsVerificationStatus, .notVerified)
//    }
//
//    func test_itDoesNotUpdateConversation_wrongMLSGroupId() async throws {
//        // Mock
//        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
//            return .verified
//        }
//
//        // Given
//        //mockConversation.mlsGroupID = MLSGroupID(Data([1, 2, 3]))
//        mockConversation.mlsVerificationStatus = .notVerified
//        let groupID = MLSGroupID(Data([1, 2, 3]))
//
//        // When
//        await sut.updateStatus(groupID)
//
//        // Then
//        XCTAssertEqual(mockConversation.mlsVerificationStatus, .notVerified)
//    }

}
