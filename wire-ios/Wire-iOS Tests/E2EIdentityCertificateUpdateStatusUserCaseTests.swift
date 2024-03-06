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
@testable import Wire
import XCTest
import WireSyncEngineSupport

final class E2EIdentityCertificateUpdateStatusUserCaseTests: XCTestCase {
    var mockGetIsE2EIdentityEnabled: MockGetIsE2EIdentityEnabledUseCaseProtocol!
    var mockGetE2eIdentityCertificates: MockGetE2eIdentityCertificatesUseCaseProtocol!
    var e2eIdentityCertificateStatus: E2EIdentityCertificateUpdateStatusUseCase!

    override func setUp() {
        mockGetIsE2EIdentityEnabled = MockGetIsE2EIdentityEnabledUseCaseProtocol()
        mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUseCaseProtocol()
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            isE2EIdentityEnabled: mockGetIsE2EIdentityEnabled,
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            gracePeriod: 0,
            lastAlertDate: nil)
        super.setUp()
    }

    override func tearDown() {
        mockGetIsE2EIdentityEnabled = nil
        mockGetE2eIdentityCertificates = nil
        e2eIdentityCertificateStatus = nil
        super.tearDown()
    }

    func update(isE2EIdenityEnabled: Bool, certificate: E2eIdentityCertificate) {
        mockGetIsE2EIdentityEnabled.invoke_MockValue = isE2EIdenityEnabled
        mockGetE2eIdentityCertificates.invokeMlsGroupIdClientIds_MockValue = [certificate]
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsBeyondSevenDays() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneWeek + .oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDays() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedToday() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            isE2EIdentityEnabled: mockGetIsE2EIdentityEnabled,
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            gracePeriod: 0,
            lastAlertDate: Date.now)
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedNotToday() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            isE2EIdentityEnabled: mockGetIsE2EIdentityEnabled,
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            gracePeriod: 0,
            lastAlertDate: Date.now - .oneDay)
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneDay() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownWithinFourHours() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            isE2EIdentityEnabled: mockGetIsE2EIdentityEnabled,
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            gracePeriod: 0,
            lastAlertDate: Date.now)
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneHour * 4))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneDayAndAlertWasShownBeyondFourHours() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            isE2EIdentityEnabled: mockGetIsE2EIdentityEnabled,
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            gracePeriod: 0,
            lastAlertDate: Date.now)
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneHour * 5))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInFourHours() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneHour * 4))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneHour() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: .oneHour))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsBlock_WhenItExpires() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: 0))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .block)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsBlock_WhenItIsBeyondExpiryDate() async {
        update(isE2EIdenityEnabled: true, certificate: certificate(with: -.oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .block)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func certificate(with timeInterval: TimeInterval) -> E2eIdentityCertificate {
        let certificate = E2eIdentityCertificate.mockValid
        certificate.expiryDate = Date.now + timeInterval
        return certificate
    }
}
