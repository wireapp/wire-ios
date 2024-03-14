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

import XCTest
import WireSyncEngineSupport

 final class E2EIdentityCertificateUpdateStatusUseCaseTests: XCTestCase {
    var mockGetE2eIdentityCertificates: MockGetE2eIdentityCertificatesUseCaseProtocol!
    var e2eIdentityCertificateStatus: E2EIdentityCertificateUpdateStatusUseCase!

    override func setUp() {
        mockGetE2eIdentityCertificates = MockGetE2eIdentityCertificatesUseCaseProtocol()
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            serverStoragePeriod: 0,
            randomPeriod: 0,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            lastAlertDate: nil)
        super.setUp()
    }

    override func tearDown() {
        mockGetE2eIdentityCertificates = nil
        e2eIdentityCertificateStatus = nil
        super.tearDown()
    }

    func update(certificate: E2eIdentityCertificate) {
        mockGetE2eIdentityCertificates.invokeMlsGroupIdClientIds_MockValue = [certificate]
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsBeyondSevenDays() async {
        update(certificate: certificate(with: .oneWeek + .oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDays() async {
        update(certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedToday() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            serverStoragePeriod: 0,
            randomPeriod: 0,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            lastAlertDate: Date.now)
        update(certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInSevenDaysAndLastAlertWasDisplayedNotToday() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            serverStoragePeriod: 0,
            randomPeriod: 0,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            lastAlertDate: Date.now - .oneDay)
        update(certificate: certificate(with: .oneWeek))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneDay() async {
        update(certificate: certificate(with: .oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownWithinFourHours() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            serverStoragePeriod: 0,
            randomPeriod: 0,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            lastAlertDate: Date.now)
        update(certificate: certificate(with: .oneHour * 4))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsNoAction_WhenExpiryDateIsWithInOneDayAndAlertWasShownBeyondFourHours() async {
        e2eIdentityCertificateStatus = E2EIdentityCertificateUpdateStatusUseCase(
            e2eCertificateForCurrentClient: mockGetE2eIdentityCertificates,
            gracePeriod: 0,
            serverStoragePeriod: 0,
            randomPeriod: 0,
            mlsGroupID: MLSGroupID(Data()),
            mlsClientID: MLSClientID(userID: "", clientID: "", domain: ""),
            lastAlertDate: Date.now)
        update(certificate: certificate(with: .oneHour * 5))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .noAction)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInFourHours() async {
        update(certificate: certificate(with: .oneHour * 4))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsReminder_WhenExpiryDateIsWithInOneHour() async {
        update(certificate: certificate(with: .oneHour))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .reminder)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsBlock_WhenItExpires() async {
        update(certificate: certificate(with: 0))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .block)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testThatItReturnsBlock_WhenItIsBeyondExpiryDate() async {
        update(certificate: certificate(with: -.oneDay))
        do {
            let result = try await e2eIdentityCertificateStatus.invoke()
            XCTAssertEqual(result, .block)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func certificate(with timeInterval: TimeInterval) -> E2eIdentityCertificate {
        let certificate = E2eIdentityCertificate(
            clientId: "sdfsdfsdfs",
            certificateDetails: .mockCertificate,
            mlsThumbprint: "ABCDEFGHIJKLMNOPQRSTUVWX",
            notValidBefore: Date.now,
            expiryDate: Date.now,
            certificateStatus: .valid,
            serialNumber: .mockSerialNumber
        )
        certificate.expiryDate = Date.now + timeInterval
        return certificate
    }
 }
