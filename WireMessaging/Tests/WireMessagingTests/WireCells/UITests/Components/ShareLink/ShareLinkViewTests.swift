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
import WireFoundationSupport
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class ShareLinkViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var viewModel: ShareLinkView.ViewModel!
    private var keychain: KeychainProtocolMock!
    private var nodesAPI: MockNodesAPIProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        keychain = KeychainProtocolMock()
        nodesAPI = MockNodesAPIProtocol()

        let useCases = ShareLinkView.ViewModel.UseCases(
            getLinkData: WireCellsGetPublicLinkDataUseCase(nodesAPI: nodesAPI),
            createPublicLink: WireCellsCreatePublicLinkUseCase(nodesAPI: nodesAPI),
            deletePublicLink: WireCellsDeletePublicLinkUseCase(nodesAPI: nodesAPI),
            updatePublicLinkExpiration: WireCellsUpdatePublicLinkExpirationUseCase(nodesAPI: nodesAPI),
            updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase(nodesAPI: nodesAPI),
            getPublicLinkPasswordUseCase: WireCellsGetPublicLinkPasswordUseCase(keychain: keychain),
            storePublicLinkPasswordUseCase: WireCellsStorePublicLinkPasswordUseCase(keychain: keychain),
            deletePublicLinkPasswordUseCase: WireCellsDeletePublicLinkPasswordUseCase(keychain: keychain)
        )

        viewModel = .init(fileItem: .fixture(), useCases: useCases)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        viewModel = nil
        keychain = nil
        nodesAPI = nil
    }

    @MainActor
    func testShareLinkView() async {
        for testCase in TestCase.allCases {
            switch testCase {
            case .noLink:
                viewModel.publicLinkState = .disabled
            case .expiredLink:
                viewModel.publicLinkState = .enabled(
                    id: UUID.mockID1.uuidString,
                    url: URL(string: "https://wire.com")!,
                    expirationDate: .init(timeIntervalSince1970: 1_759_311_973),
                    requiresPassword: false
                )
            case .validLink:
                viewModel.publicLinkState = .enabled(
                    id: UUID.mockID1.uuidString,
                    url: URL(string: "https://wire.com")!,
                    expirationDate: nil,
                    requiresPassword: true
                )

                viewModel.password = "Test"
            }

            let view = makeView()

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(testCase.rawValue)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(testCase.rawValue)" + "dark")
        }
    }

    enum TestCase: String, CaseIterable {
        case noLink
        case expiredLink
        case validLink
    }

    @MainActor
    private func makeView() -> some View {
        let viewModel = viewModel!

        return ShareLinkView(viewModel: viewModel)
            .frame(width: 375, height: 667)
    }

}
