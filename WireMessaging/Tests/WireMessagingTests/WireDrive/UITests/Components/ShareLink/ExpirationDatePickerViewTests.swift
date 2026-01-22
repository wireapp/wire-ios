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
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class ExpirationDatePickerViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var viewModel: ExpirationDatePickerView.ViewModel!
    private var nodesAPI: MockNodesAPIProtocol!
    private var updatePublicLinkExpiration: WireDriveUpdatePublicLinkExpirationUseCase!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesAPI = MockNodesAPIProtocol()
        updatePublicLinkExpiration = WireDriveUpdatePublicLinkExpirationUseCase(nodesAPI: nodesAPI)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        viewModel = nil
        nodesAPI = nil
        updatePublicLinkExpiration = nil
    }

    // TODO: [WPB-21903] - fix snapshot test currently failing on the CI
//    @MainActor
//    func testExpirationDatePickerView() async {
//        for testCase in TestCase.allCases {
//            switch testCase {
//            case .noExpirationDate:
//                viewModel = .init(
//                    linkID: "test",
//                    calendar: Calendar(identifier: .gregorian),
//                    expirationDate: nil,
//                    didSave: { _ in },
//                    updatePublicLinkExpiration: updatePublicLinkExpiration
//                )
//            case .hasExpirationDate:
//                viewModel = .init(
//                    linkID: "test",
//                    calendar: Calendar(identifier: .gregorian),
//                    expirationDate: .distantFuture,
//                    didSave: { _ in },
//                    updatePublicLinkExpiration: updatePublicLinkExpiration
//                )
//            }
//
//            let view = makeView()
//
//            snapshotHelper
//                .withUserInterfaceStyle(.light)
//                .verify(matching: view, named: "\(testCase.rawValue)" + "light")
//            snapshotHelper
//                .withUserInterfaceStyle(.dark)
//                .verify(matching: view, named: "\(testCase.rawValue)" + "dark")
//        }
//    }

    enum TestCase: String, CaseIterable {
        case hasExpirationDate
        case noExpirationDate
    }

    @MainActor
    private func makeView() -> some View {
        let viewModel = viewModel!

        return ExpirationDatePickerView(viewModel: viewModel)
            .frame(width: 375, height: 667)
    }

}
