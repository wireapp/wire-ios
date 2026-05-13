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

import WireTestingPackage
import WireSyncEngine
import XCTest

@testable import Wire

final class SuccessfulCertificateEnrollmentViewControllerSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    func testThatItShouldShowAppropriateMessage_WhenEnrolE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewController(isUpdateMode: false)
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShouldShowAppropriateMessage_WhenUpdateE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewController(isUpdateMode: true)
        snapshotHelper.verify(matching: sut)
    }

    func testDisplayState_WhenEnrollE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewModel(mode: .enroll)

        XCTAssertEqual(sut.displayState.title, L10n.Localizable.EnrollE2eiCertificate.title)
        XCTAssertEqual(sut.displayState.subtitle, L10n.Localizable.EnrollE2eiCertificate.subtitle)
        XCTAssertEqual(
            sut.displayState.certificateDetailsButtonTitle,
            L10n.Localizable.EnrollE2eiCertificate.certificateDetailsButton
        )
        XCTAssertEqual(sut.displayState.confirmationButtonTitle, L10n.Localizable.EnrollE2eiCertificate.okButton)
        XCTAssertEqual(sut.displayState.image, .certificateValid)
    }

    func testDisplayState_WhenUpdateE2eIdentityIsSuccessful() {
        let sut = SuccessfulCertificateEnrollmentViewModel(mode: .update)

        XCTAssertEqual(sut.displayState.title, L10n.Localizable.UpdateE2eiCertificate.title)
        XCTAssertEqual(sut.displayState.subtitle, L10n.Localizable.UpdateE2eiCertificate.subtitle)
        XCTAssertEqual(
            sut.displayState.certificateDetailsButtonTitle,
            L10n.Localizable.EnrollE2eiCertificate.certificateDetailsButton
        )
        XCTAssertEqual(sut.displayState.confirmationButtonTitle, L10n.Localizable.EnrollE2eiCertificate.okButton)
        XCTAssertEqual(sut.displayState.image, .certificateValid)
    }

    func testCertificateDetailsRoute() {
        let certificateDetails = "certificate-chain"
        let sut = SuccessfulCertificateEnrollmentViewModel(mode: .enroll, certificateDetails: certificateDetails)

        guard case let .certificateDetails(detailsState) = sut.certificateDetailsTapped() else {
            return XCTFail("Expected certificate details route")
        }

        XCTAssertEqual(detailsState.certificateDetails, certificateDetails)
        XCTAssertEqual(detailsState.isDownloadAndCopyEnabled, Settings.isClipboardEnabled)
        XCTAssertEqual(detailsState.fileName, "certificate-chain")
        XCTAssertEqual(detailsState.fileType, "txt")
    }

    func testConfirmationRoute() {
        let sut = SuccessfulCertificateEnrollmentViewModel(mode: .enroll)

        guard case .complete = sut.confirmationTapped() else {
            return XCTFail("Expected complete route")
        }
    }
}
