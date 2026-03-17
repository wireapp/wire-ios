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
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

class FlowLayoutTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testLeadingAlignment() {
        let view = FlowLayout(alignment: .leading) {
            Rectangle()
                .fill(.red)
                .frame(width: 50, height: 50)

            Rectangle()
                .fill(.green)
                .frame(width: 50, height: 30)

            Rectangle()
                .fill(.blue)
                .frame(idealWidth: .infinity)
                .frame(height: 70)
        }
        .background(Color.yellow)
        .padding(8)
        .frame(width: 350, height: 200)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
    }

    @MainActor
    func testTrailingAlignment() {
        let view = FlowLayout(alignment: .trailing) {
            Rectangle()
                .fill(.red)
                .frame(width: 50, height: 50)

            Rectangle()
                .fill(.green)
                .frame(width: 50, height: 30)

            Rectangle()
                .fill(.blue)
                .frame(idealWidth: .infinity)
                .frame(height: 70)
        }
        .background(Color.yellow)
        .padding(8)
        .frame(width: 350, height: 200)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
    }

}
