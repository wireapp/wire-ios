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
import XCTest

@testable import WireReusableUIComponents

final class LegalHoldIndicatorViewSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var sut: LegalHoldIndicatorView!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        sut = .init()
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testThatItShowsLoadingIndicator() {
        snapshotHelper.verify(matching: sut.frame(width: 30))
    }
}
