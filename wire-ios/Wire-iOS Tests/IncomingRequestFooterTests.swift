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

import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - IncomingRequestFooterTests

final class IncomingRequestFooterTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        UIColor.setAccentOverride(.blue)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        UIColor.setAccentOverride(nil)
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testIncomingRequestFooter_Light() {
        let footer = IncomingRequestFooterView()
        let view = footer.prepareForSnapshots()

        snapshotHelper.verify(matching: view)
    }

    func testIncomingRequestFooter_Dark() {
        let footer = IncomingRequestFooterView()
        let view = footer.prepareForSnapshots()

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view)
    }
}

extension IncomingRequestFooterView {
    // MARK: - Helper Method

    fileprivate func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 375),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
}
