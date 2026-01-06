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

import SwiftUI
import WireFoundation
import WireMessagingUI
import WireTestingPackage
import XCTest

class ConversationTypePickerTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testColorSchemeVariantsEmptyState() {
        let view = VStack {
            ConversationTypePicker(
                availableConversationTypes: [.channel, .group],
                onConversationTypeSelected: { _ in }
            )
            .frame(width: 350, height: 200)
            .padding()
        }
        .background(Color.blue)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState() {
        let view = VStack {
            ConversationTypePicker(
                availableConversationTypes: [.channel, .group],
                onConversationTypeSelected: { _ in }
            )
            .frame(width: 350, height: 200)
            .padding()
        }
        .background(Color.blue)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}
