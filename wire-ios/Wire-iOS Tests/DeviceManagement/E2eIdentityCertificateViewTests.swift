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
import SwiftUI
@testable import Wire
import XCTest

final class E2eIdentityCertificateViewTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: UIHostingController<E2EIdentityCertificateDetailsView>!

    lazy var kCertificate: String = {
        return .mockCertificate
    }()

    // MARK: - Helper Method

    func setupSut(
        certificateDetails: String,
        mode: UIUserInterfaceStyle,
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
        sut.overrideUserInterfaceStyle = mode
    }

    // MARK: - Light Mode

    func testGivenCopyIsDisabledWhenCertificateIsAvailableThenRightViewIsShown() {
        setupSut(
            certificateDetails: kCertificate,
            mode: .light,
            isDownloadAndCopyEnabled: false,
            isMenuPresented: false
        )
        verify(matching: sut)
    }

    func testGivenCopyIsEnabledAndCertificateIsAvailableWhenMenuIsPresentedThenRightViewIsShown() {
        setupSut(
            certificateDetails: kCertificate,
            mode: .light,
            isDownloadAndCopyEnabled: true,
            isMenuPresented: true
        )
        verify(matching: sut)
    }

    // MARK: Dark Mode

    func testGivenCopyIsDisabledWhenCertificateIsAvailableThenRightViewIsShownInDarkMode() {
        setupSut(
            certificateDetails: kCertificate,
            mode: .dark,
            isDownloadAndCopyEnabled: false,
            isMenuPresented: false
        )
        verify(matching: sut)
    }

    func testGivenCopyIsEnabledAndCertificateIsAvailableWhenMenuIsPresentedThenRightViewIsShownInDarkMode() {
        setupSut(
            certificateDetails: kCertificate,
            mode: .dark,
            isDownloadAndCopyEnabled: true,
            isMenuPresented: true
        )
        verify(matching: sut)
    }

}
