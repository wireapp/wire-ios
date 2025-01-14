//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireReusableUIComponents

@MainActor
final class ProgressIndicatingAlertControllerTests: XCTestCase {

    private var sut: UIViewController!
    private var window: UIWindow!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() async throws {
        window = .init(frame: UIScreen.main.bounds)
        window.backgroundColor = .systemBackground
        window.makeKeyAndVisible()

        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() async throws {
        window.isHidden = true
        window = nil
        snapshotHelper = nil
    }

    @available(iOS 17, *) @MainActor
    func testUIFontDarkUserInterfaceStyle() async {
        sut = ProgressIndicatingAlertControllerPreview()
        try? await Task.sleep(for: .milliseconds(200))
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @available(iOS 17, *) @MainActor
    func testUIFontContentSizeCategories() async {
        sut = ProgressIndicatingAlertControllerPreview()
        window.rootViewController = sut
        try? await Task.sleep(for: .milliseconds(200))
        for contentSizeCategory in UIContentSizeCategory.allCases {
            sut.traitOverrides.preferredContentSizeCategory = contentSizeCategory
            snapshotHelper
                .verify(
                    matching: renderedImage(),
                    named: "\(contentSizeCategory)"
                )
        }

        XCTFail("doesn't work")
    }

    private func renderedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: sut.view.bounds.size)
        return renderer.image { _ in
            sut.view.drawHierarchy(in: sut.view.bounds, afterScreenUpdates: true)
        }
    }
}
