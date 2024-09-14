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

import SwiftUI
import WireTestingPackage
import XCTest

@testable import Wire

final class E2eIdentityCertificateViewTests: XCTestCase {

    // MARK: - Properties

    var sut: UIHostingController<E2EIdentityCertificateDetailsView>!
    private var snapshotHelper: SnapshotHelper_!

    lazy var kCertificate: String = {
        return .mockCertificate
    }()

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Helper Method

    func setupSut(
        certificateDetails: String,
        isDownloadAndCopyEnabled: Bool,
        isMenuPresented: Bool
    ) {
        let certificateView = E2EIdentityCertificateDetailsView(
            certificateDetails: kCertificate,
            isDownloadAndCopyEnabled: isDownloadAndCopyEnabled,
            isMenuPresented: isMenuPresented
        )
        sut = UIHostingController(rootView: certificateView)
        sut.view.frame = UIScreen.main.bounds
    }

    // MARK: - Light Mode

    func testGivenCopyIsDisabledWhenCertificateIsAvailableThenRightViewIsShown() {
        setupSut(
            certificateDetails: kCertificate,
            isDownloadAndCopyEnabled: false,
            isMenuPresented: false
        )

        snapshotHelper.verify(matching: sut)
    }

    func testGivenCopyIsEnabledAndCertificateIsAvailableWhenMenuIsPresentedThenRightViewIsShown() {
        setupSut(
            certificateDetails: kCertificate,
            isDownloadAndCopyEnabled: true,
            isMenuPresented: true
        )

        snapshotHelper.verify(matching: sut)
    }

    // MARK: Dark Mode

    func testGivenCopyIsDisabledWhenCertificateIsAvailableThenRightViewIsShownInDarkMode() {
        setupSut(
            certificateDetails: kCertificate,
            isDownloadAndCopyEnabled: false,
            isMenuPresented: false
        )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testGivenCopyIsEnabledAndCertificateIsAvailableWhenMenuIsPresentedThenRightViewIsShownInDarkMode() {
        setupSut(
            certificateDetails: kCertificate,
            isDownloadAndCopyEnabled: true,
            isMenuPresented: true
        )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

}
