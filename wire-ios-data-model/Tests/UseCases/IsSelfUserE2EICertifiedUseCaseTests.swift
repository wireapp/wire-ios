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

import WireCoreCrypto
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

// MARK: - IsSelfUserE2EICertifiedUseCaseTests

final class IsSelfUserE2EICertifiedUseCaseTests: ZMBaseManagedObjectTest {
    private var selfUser: ZMUser!
    private var selfMLSConversation: ZMConversation!
    private var mockIsUserE2EICertifiedUseCase: MockIsUserE2EICertifiedUseCaseProtocol!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var sut: IsSelfUserE2EICertifiedUseCase!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        let modelHelper = ModelHelper()
        selfUser = context.performAndWait {
            modelHelper.createSelfUser(in: context)
        }
        selfMLSConversation = context.performAndWait {
            modelHelper.createSelfMLSConversation(mlsGroupID: .random(), in: context)
        }
        mockIsUserE2EICertifiedUseCase = .init()
        mockFeatureRepository = .init()
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled, config: .init())
        sut = .init(
            context: context,
            featureRepository: mockFeatureRepository,
            featureRepositoryContext: context,
            isUserE2EICertifiedUseCase: mockIsUserE2EICertifiedUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockIsUserE2EICertifiedUseCase = nil
        mockFeatureRepository = nil
        selfMLSConversation = nil
        selfUser = nil

        super.tearDown()
    }

    func testInvokeIsCalled() async throws {
        // Given
        mockIsUserE2EICertifiedUseCase.invokeConversationUser_MockValue = true

        // When
        let result = try await sut.invoke()

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockIsUserE2EICertifiedUseCase.invokeConversationUser_Invocations.count, 1)
        let invocation = try XCTUnwrap(mockIsUserE2EICertifiedUseCase.invokeConversationUser_Invocations.first)
        XCTAssert(invocation.user === selfUser)
        XCTAssert(invocation.conversation === selfMLSConversation)
    }

    func testThatSelfUserIsNotCertified_WhenE2EIFeatureIsDisabled() async throws {
        // Given
        mockIsUserE2EICertifiedUseCase.invokeConversationUser_MockValue = true

        // When
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .disabled, config: .init())
        let result = try await sut.invoke()

        // Then
        XCTAssertFalse(result)
    }

    func testErrorsAreForwarded() async throws {
        // Given
        mockIsUserE2EICertifiedUseCase.invokeConversationUser_MockError = MockError.some

        do {
            // When
            _ = try await sut.invoke()
            XCTFail("unexpected success")
        } catch MockError.some {
            // okay
        }
    }
}

// MARK: - MockError

private enum MockError: Error {
    case some
}
