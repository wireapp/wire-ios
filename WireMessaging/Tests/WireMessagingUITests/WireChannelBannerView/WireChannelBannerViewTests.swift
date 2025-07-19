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
import WireDesign
import WireFoundation
import WireMessagingBindings
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class WireChannelBannerTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState() {
        let view = WireChannelBannerView(
            configuration: .init(
                title: "Show older messages?",
                message: "Upgrade to a paid plan to offer channel members the whole history.",
                mainButtonTitle: "Upgrade now",
                mainButtonAction: {},
                closeButton: .init(
                    accessibilityLabel: "",
                    action: {}
                )
            )
        )
        .frame(width: 375, height: 667)
        .padding()
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}
