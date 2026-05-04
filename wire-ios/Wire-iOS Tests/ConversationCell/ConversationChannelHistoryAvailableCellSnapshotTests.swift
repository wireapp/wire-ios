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

import WireDesign
import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationChannelHistoryAvailableCellSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationChannelHistoryAvailableCellDescription!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        BackendInfo.apiVersion = .v8
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testChannelHistoryHasMoreHistory_LightTheme() {
        let view = makeSut(hasMoreHistory: true)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view)
    }

    func testChannelHistoryHasMoreHistory_DarkTheme() {
        let view = makeSut(hasMoreHistory: true)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view)
    }

    func testChannelHistoryHasNoMoreHistory_LightTheme() {
        let view = makeSut(hasMoreHistory: false)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view)
    }

    func testChannelHistoryHasNoMoreHistory_DarkTheme() {
        let view = makeSut(hasMoreHistory: false)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view)
    }

    // MARK: - Helpers

    private func makeSut(hasMoreHistory: Bool) -> UIView {
        sut = ConversationChannelHistoryAvailableCellDescription(hasMoreHistory: hasMoreHistory)
        let view = sut.makeView()
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        let wrapperView = UIView(frame: .init(x: 0, y: 0, width: 375, height: hasMoreHistory ? 40 : 50))
        wrapperView.backgroundColor = SemanticColors.View.backgroundConversationList
        wrapperView.addSubview(view)
        view.frame = wrapperView.bounds

        return view
    }

}
