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

import Foundation
import UIKit

import WireTestingPackage
import XCTest

import WireMessagingDomain
@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

class ChannelHistoryViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    @MainActor
    func testChannelHistory_UserPremium() async {
        let sut = await makeSUT()

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testCustomChannelHistory_UserPremium() async {
        let sut = await makeSUT(customHistory: true)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testChannelHistory_UserNotPremium() async {
        let sut = await makeSUT(isPremium: false)

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    private func makeSUT(
        customHistory: Bool = false,
        isPremium: Bool = true
    ) async -> UIViewController {
        let screenBounds = UIScreen.main.bounds

        let useCase = MockChannelHistoryUseCaseProtocol()
        useCase.updateHistoryDepth_MockMethod = { _ in }
        useCase.isEnterpriseUser_MockValue = isPremium

        let viewModel = ChannelHistoryViewModel(
            historyDepth: "",
            teamsURL: URL(string: "https://google.com")!,
            accentColor: .red,
            useCase: useCase
        )
        await viewModel.fetchData()

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
