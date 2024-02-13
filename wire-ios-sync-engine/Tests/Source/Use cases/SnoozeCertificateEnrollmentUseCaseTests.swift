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

class SnoozeCertificateEnrollmentUseCaseTests: ZMUserSessionTestsBase {

    private var snoozer: SnoozeCertificateEnrollmentUseCase!
    private var mockRecurringActionService: MockRecurringActionServiceInterface!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var selfClientCertificateProvider: MockSelfClientCertificateProviderProtocol!
    private var gracePeriodRepository: GracePeriodRepository!

    override func setUp() {
        super.setUp()

        mockRecurringActionService = .init()
        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockFeatureRepository.fetchE2EI_MockValue = .init(status: .enabled)
        selfClientCertificateProvider = MockSelfClientCertificateProviderProtocol()
        let accountID = UUID.create()
        gracePeriodRepository = GracePeriodRepository(
            userID: accountID,
            sharedUserDefaults: sharedUserDefaults)
        gracePeriodRepository.storeEndGracePeriodDate(Date.now)
        snoozer = SnoozeCertificateEnrollmentUseCase(
            e2eiFeature: mockFeatureRepository.fetchE2EI(),
            gracePeriodRepository: gracePeriodRepository,
            recurringActionService: mockRecurringActionService,
            selfClientCertificateProvider: selfClientCertificateProvider,
            accountId: accountID)
    }

    override func tearDown() {
        snoozer = nil
        mockRecurringActionService = nil
        selfClientCertificateProvider = nil
        gracePeriodRepository = nil

        super.tearDown()
    }

    func testItAddsRecurringAction() async {
        // Given
        selfClientCertificateProvider.underlyingHasCertificate = false
        mockRecurringActionService.registerAction_MockMethod = { _ in }

        // When
        XCTAssertEqual(mockRecurringActionService.registerAction_Invocations.count, 0)
        await snoozer.start()

        // Then
        XCTAssertEqual(mockRecurringActionService.registerAction_Invocations.count, 1)
    }

    func testItRemovesRecurringAction() async {
        // Given
        selfClientCertificateProvider.underlyingHasCertificate = false
        mockRecurringActionService.registerAction_MockMethod = { _ in }
        mockRecurringActionService.removeActionId_MockMethod = { _ in }

        await snoozer.start()
        XCTAssertEqual(mockRecurringActionService.registerAction_Invocations.count, 1)

        // When
        snoozer.stop()

        // Then
        XCTAssertEqual(mockRecurringActionService.removeActionId_Invocations.count, 1)
    }
}
