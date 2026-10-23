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

import Network
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

@MainActor
final class FilesTrailingToolBarTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var originalBulkActionsFlag: Any?

    override func setUp() async throws {
        snapshotHelper = SnapshotHelper()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        originalBulkActionsFlag = UserDefaults.standard.object(forKey: "enableDriveBulkActions")
    }

    override func tearDown() async throws {
        UserDefaults.standard.set(originalBulkActionsFlag, forKey: "enableDriveBulkActions")
        snapshotHelper = nil
    }

    func testToolbarConditions() async {
        let scenarios: [(String, Configuration)] = [
            ("files_editor", .init()),
            ("files_viewer", .init(role: .viewer)),
            ("files_empty", .init(hasItems: false)),
            ("files_selecting", .init(isSelecting: true)),
            ("files_offline", .init(isOffline: true)),
            ("recycle_bin_editor", .init(isRecycleBin: true)),
            ("recycle_bin_viewer", .init(role: .viewer, isRecycleBin: true)),
            ("recycle_bin_empty", .init(isRecycleBin: true, hasItems: false)),
            ("recycle_bin_selecting", .init(isRecycleBin: true, isSelecting: true)),
            ("recycle_bin_offline", .init(isRecycleBin: true, isOffline: true)),
        ]

        for (name, configuration) in scenarios {
            let viewModel = await makeViewModel(configuration)
            let toolbar = makeToolbar(viewModel)
            let view = NavigationStack {
                ColorTheme.Backgrounds.surface.color
                    .navigationTitle(viewModel.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(viewModel.navigationTitle)
                                .font(for: .h3)
                                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        }
                        toolbar
                    }
            }
            .frame(width: 375, height: 160)

            snapshotHelper.verifyLightAndDark(matching: view, named: "\(name)-")
        }
    }

    private struct Configuration {
        var role: WireDriveConversation.Participant.Role = .editor
        var isRecycleBin = false
        var hasItems = true
        var bulkActionsEnabled = true
        var isSelecting = false
        var isOffline = false
    }

    private func makeViewModel(_ configuration: Configuration) async -> FilesViewModel {
        UserDefaults.standard.set(configuration.bulkActionsEnabled, forKey: "enableDriveBulkActions")

        let preview = FilesViewModel.preview(selfUserRole: configuration.role)
        let networkStatus: NetworkMonitor.NetworkStatus = configuration.isOffline ? .disconnected : .connected
        let networkMonitor = NetworkMonitor(monitor: StubPathMonitor(), initialStatus: networkStatus)
        let viewModel = FilesViewModel(
            useCases: preview.useCases,
            isCellsStatePending: false,
            cellName: preview.cellName,
            isBrowsing: false,
            isRecycleBin: configuration.isRecycleBin,
            networkMonitor: networkMonitor
        )
        await viewModel.setup()
        XCTAssertEqual(viewModel.selfUserRole, configuration.role)
        viewModel.filesController.state = .received(items: configuration.hasItems ? [.fixture()] : [])
        viewModel.enableMultipleSelection(configuration.isSelecting)
        networkMonitor.currentStatus = networkStatus
        return viewModel
    }

    private func makeToolbar(_ viewModel: FilesViewModel) -> FilesTrailingToolbar {
        FilesTrailingToolbar(
            viewModel: viewModel,
            actionHandlers: .init(
                onOpenRecycleBin: {},
                onDismissContainer: {},
                onUploadFiles: {},
                onUploadMedia: {}
            )
        )
    }

}

private final class StubPathMonitor: NWPathMonitoring {
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)?

    func start(queue: DispatchQueue) {}
}
