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
@testable import WireSyncEngine
@testable import WireSyncEngineSupport
@testable import WireDataModelSupport
import WireTesting

final class SnoozeCertificateEnrollmentUseCaseTests: ZMUserSessionTestsBase {

    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var selfClientCertificateProvider: MockSelfClientCertificateProviderProtocol!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled)
        selfClientCertificateProvider = MockSelfClientCertificateProviderProtocol()
    }

    override func tearDown() {
        selfClientCertificateProvider = nil
        mockFeatureRepository = nil

        super.tearDown()
    }

    func testItAddsRecurringAction() async {
        // Given
        selfClientCertificateProvider.underlyingHasCertificate = false
        mockRecurringActionService.registerAction_MockMethod = { _ in }

        let mockRecurringActionService = MockRecurringActionServiceInterface()
        mockRecurringActionService.registerAction_MockMethod = { _ in }

        let useCase = makeUseCase(recurringActionService: mockRecurringActionService)

        // When
        XCTAssertEqual(mockRecurringActionService.registerAction_Invocations.count, 0)
        await useCase.invoke(endOfPeriod: .now)

        // Then
        XCTAssertEqual(mockRecurringActionService.registerAction_Invocations.count, 1)
    }

    // MARK: Helpers

    private func makeUseCase(recurringActionService: any RecurringActionServiceInterface) -> SnoozeCertificateEnrollmentUseCase {
        SnoozeCertificateEnrollmentUseCase(
            featureRepository: mockFeatureRepository,
            featureRepositoryContext: context,
            recurringActionService: recurringActionService,
            accountId: UUID()
        )
    }
}
