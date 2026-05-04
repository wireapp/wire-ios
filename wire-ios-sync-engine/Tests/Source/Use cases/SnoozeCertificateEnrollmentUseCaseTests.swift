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
import WireTesting

@testable import WireDataModelSupport
@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class SnoozeCertificateEnrollmentUseCaseTests: ZMUserSessionTestsBase {

    private var mockLegacyFeatureRepository: MockLegacyFeatureRepositoryInterface!
    private var mockSelfClientCertificateProvider: MockSelfClientCertificateProviderProtocol!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        mockLegacyFeatureRepository = MockLegacyFeatureRepositoryInterface()
        mockLegacyFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled)
        mockSelfClientCertificateProvider = MockSelfClientCertificateProviderProtocol()
    }

    override func tearDown() {
        mockSelfClientCertificateProvider = nil
        mockLegacyFeatureRepository = nil

        super.tearDown()
    }

    func testItAddsRecurringAction() async {
        // Given
        mockSelfClientCertificateProvider.underlyingHasCertificate = false
        mockRecurringActionService.registerAction_MockMethod = { _ in }

        // We use a fresh mock here instead of the given one from the super class
        // to be able to count invocations exactly without side effects.
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

    private func makeUseCase(recurringActionService: any RecurringActionServiceInterface)
        -> SnoozeCertificateEnrollmentUseCase {
        SnoozeCertificateEnrollmentUseCase(
            featureRepository: mockLegacyFeatureRepository,
            featureRepositoryContext: context,
            recurringActionService: recurringActionService,
            accountId: UUID()
        )
    }
}
