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
import WireFoundationSupport
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class ShareLinkPasswordViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var viewModel: ShareLinkPasswordView.ViewModel!
    private var keychain: KeychainProtocolMock!
    private var nodesAPI: MockNodesAPIProtocol!
    private var updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase!
    private var storePublicLinkPasswordUseCase: WireCellsStorePublicLinkPasswordUseCase!
    private var deletePublicLinkPasswordUseCase: WireCellsDeletePublicLinkPasswordUseCase!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        keychain = KeychainProtocolMock()
        nodesAPI = MockNodesAPIProtocol()
        updatePublicLinkPassword = .init(nodesAPI: nodesAPI)
        storePublicLinkPasswordUseCase = .init(keychain: keychain)
        deletePublicLinkPasswordUseCase = .init(keychain: keychain)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        viewModel = nil
        keychain = nil
        nodesAPI = nil
        updatePublicLinkPassword = nil
        storePublicLinkPasswordUseCase = nil
        deletePublicLinkPasswordUseCase = nil
    }

    @MainActor
    func testShareLinkPasswordView() async {
        for testCase in TestCase.allCases {
            switch testCase {
            case .hasPassword:
                setupViewModel(password: "test", requiresPassword: true)
            case .noPassword:
                setupViewModel(password: nil, requiresPassword: false)
            case .settingPassword:
                setupViewModel(password: "test", requiresPassword: true)
                viewModel.resetPassword()
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
        case hasPassword
        case noPassword
        case settingPassword
    }

    @MainActor
    private func setupViewModel(password: String?, requiresPassword: Bool) {
        viewModel = .init(
            password: password,
            requiresPassword: requiresPassword,
            linkID: nil,
            useCases: .init(
                updatePublicLinkPassword: updatePublicLinkPassword,
                storePublicLinkPasswordUseCase: storePublicLinkPasswordUseCase,
                deletePublicLinkPasswordUseCase: deletePublicLinkPasswordUseCase
            ),
            didSave: { _, _ in }
        )
    }

    @MainActor
    private func makeView() -> some View {
        let viewModel = viewModel!

        return ShareLinkPasswordView(viewModel: viewModel)
            .frame(width: 375, height: 667)
    }

}
