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

import WireFoundation
import WireTestingPackage
import XCTest

@testable import WireReusableUIComponents

final class InfoBannerViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testBlueTitleOnly() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(title: "Enjoy benefits of a team")
            .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

    @MainActor
    func testGreenTitleAndMessage() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(
            title: "Enjoy benefits of a team",
            message: "Explore extra features for free with the same level of security."
        )
        .environment(\.wireAccentColor, .green)
        .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

    @MainActor
    func testRedTitleAndButton() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(
            title: "Enjoy benefits of a team",
            button: .init(
                title: "Call to action",
                accessibilityIdentifier: "",
                action: {}
            )
        )
        .environment(\.wireAccentColor, .red)
        .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

    @MainActor
    func testAmberTitleMessageAndButton() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(
            title: "Enjoy benefits of a team",
            message: "Explore extra features for free with the same level of security.",
            button: .init(
                title: "Call to action",
                accessibilityIdentifier: "",
                action: {}
            )
        )
        .environment(\.wireAccentColor, .amber)
        .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

    @MainActor
    func testTurquoiseTitleMessageAndButton() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(
            title: "Enjoy benefits of a team",
            message: "Explore extra features for free with the same level of security.",
            button: .init(
                title: "Call to action",
                accessibilityIdentifier: "",
                action: {}
            )
        )
        .environment(\.wireAccentColor, .turquoise)
        .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

    @MainActor
    func testPurpleTitleMessageAndButton() {

        let screenBounds = UIScreen.main.bounds
        let view = InfoBannerView(
            title: "Enjoy benefits of a team",
            message: "Explore extra features for free with the same level of security.",
            button: .init(
                title: "Call to action",
                accessibilityIdentifier: "",
                action: {}
            )
        )
        .environment(\.wireAccentColor, .purple)
        .frame(width: screenBounds.width, height: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")

    }

}
