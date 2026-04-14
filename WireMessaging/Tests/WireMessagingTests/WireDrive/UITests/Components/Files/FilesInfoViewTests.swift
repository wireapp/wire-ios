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
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FilesInfoViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
    }

    @MainActor
    func testEmpty() async {
        let configs: [(name: String, scope: FilesInfoView.Scope)] = [
            (name: "all_conv_files", scope: .files(conversation: .all)),
            (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
            (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
            (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
            (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
            (name: "search", scope: .search),
            (name: "move_to_folder", scope: .moveToFolder)
        ]

        for config in configs {
            let view = FilesInfoView(scope: config.scope, kind: .empty)
                .frame(width: 375)
                .fixedSize(horizontal: false, vertical: true)

            snapshotHelper.verify(matching: view, named: config.name)
        }
    }

    @MainActor
    func testErrorUnknown() async {
        let configs: [(name: String, scope: FilesInfoView.Scope)] = [
            (name: "all_conv_files", scope: .files(conversation: .all)),
            (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
            (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
            (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
            (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
            (name: "search", scope: .search),
            (name: "move_to_folder", scope: .moveToFolder),
            (name: "edit_file", scope: .editFile)
        ]

        for config in configs {
            let view = FilesInfoView(scope: config.scope, kind: .error(isConnectionError: false))
                .frame(width: 375)
                .fixedSize(horizontal: false, vertical: true)

            snapshotHelper.verify(matching: view, named: config.name)
        }
    }

    @MainActor
    func testErrorNoInternet() async {
        let configs: [(name: String, scope: FilesInfoView.Scope)] = [
            (name: "all_conv_files", scope: .files(conversation: .all)),
            (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
            (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
            (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
            (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
            (name: "search", scope: .search),
            (name: "move_to_folder", scope: .moveToFolder),
            (name: "edit_file", scope: .editFile)
        ]

        for config in configs {
            let view = FilesInfoView(scope: config.scope, kind: .error(isConnectionError: true))
                .frame(width: 375)
                .fixedSize(horizontal: false, vertical: true)

            snapshotHelper.verify(matching: view, named: config.name)
        }
    }

    @MainActor
    func testVariants() async {
        let configs: [(name: String, scope: FilesInfoView.Scope, kind: FilesInfoView.Kind)] = [
            (name: "files_empty", scope: .files(conversation: .all), kind: .empty),
            (name: "search_empty", scope: .search, kind: .empty),
            (name: "search_error", scope: .search, kind: .error(isConnectionError: true))
        ]

        for config in configs {
            let view = FilesInfoView(scope: config.scope, kind: config.kind)
                .frame(width: 375)
                .fixedSize(horizontal: false, vertical: true)

            snapshotHelper.verify(matching: view, named: config.name, variants: .colorSchemes)
            snapshotHelper.verify(matching: view, named: config.name, variants: .sizes(.smallestLargeLargest))
        }
    }
}
