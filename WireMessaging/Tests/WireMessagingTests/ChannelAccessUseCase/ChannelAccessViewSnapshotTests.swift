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
import WireMessagingUI

@testable import WireMessagingDomainSupport

final class ChannelAccessViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    @MainActor
    func testPublicAccessLevel() {
        let sut = makeSUT(settings: .init(accessLevel: .public, participantPermission: nil))

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    func testPrivateAccessLevel() {
        let sut = makeSUT(settings: .init(
            accessLevel: .private,
            participantPermission: .everyone
        ))

        snapshotHelper.verifyLightAndDark(matching: sut)
    }

    @MainActor
    private func makeSUT(settings: ChannelAccessSettings) -> UIViewController {
        let screenBounds = UIScreen.main.bounds

        let useCase = MockChannelAccessUseCaseProtocol()
        useCase.underlyingSettings = settings

        let viewModel = ChannelAccessViewModel(
            accentColor: .red, useCase: useCase
        )

        let viewController = ChannelAccessHostingController(viewModel: viewModel)
        let navVC = UINavigationController(rootViewController: UIViewController())
        navVC.pushViewController(viewController, animated: false)
        navVC.view.frame = CGRect(
            origin: .zero,
            size: screenBounds.size
        )
        return navVC
    }

}
