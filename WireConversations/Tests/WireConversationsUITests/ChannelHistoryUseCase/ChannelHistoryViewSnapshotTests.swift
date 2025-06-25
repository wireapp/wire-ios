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

import Foundation
import UIKit

import WireTestingPackage
import XCTest

import WireConversationsAPI
@testable import WireConversationsImplementationSupport
@testable import WireConversationsUI

class ChannelHistoryViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    @MainActor
    func testChannelHistory() {
        let sut = makeSUT()

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testCustomChannelHistory() {
        let sut = makeSUT(customHistory: true)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    private func makeSUT(customHistory: Bool = false) -> UIViewController {
        let screenBounds = UIScreen.main.bounds

        let useCase = MockChannelHistoryUseCaseProtocol()
        useCase.updateHistoryDepth_MockMethod = { _ in }

        let viewModel = ChannelHistoryViewModel(
            historyDepth: 10_000,
            accentColor: .red,
            useCase: useCase
        )

        viewModel.channelHistoryOption = customHistory ? .custom : .oneDay

        let viewController = ChannelHistoryHostingController(viewModel: viewModel)
        let navVC = UINavigationController(rootViewController: UIViewController())
        navVC.pushViewController(viewController, animated: false)
        navVC.view.frame = CGRect(
            origin: .zero,
            size: screenBounds.size
        )
        return navVC
    }
}
