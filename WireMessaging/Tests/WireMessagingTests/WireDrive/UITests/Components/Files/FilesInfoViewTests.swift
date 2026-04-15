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
import Testing
import WireTestingPackage

@testable import WireMessagingUI

struct FilesInfoViewTests {

    private let snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    typealias ScopeArgument = (name: String, scope: FilesInfoView.Scope)
    typealias ScopeAndKindArgument = (name: String, scope: FilesInfoView.Scope, kind: FilesInfoView.Kind)

    /// Testing the empty states in different scopes (areas/features of the app).
    @Test(arguments: [ScopeArgument]([
        (name: "all_conv_files", scope: .files(conversation: .all)),
        (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
        (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
        (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
        (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
        (name: "search", scope: .search),
        (name: "move_to_folder", scope: .moveToFolder)
    ]))
    @MainActor
    func testEmpty(_ argument: ScopeArgument) async {
        let view = FilesInfoView(scope: argument.scope, kind: .empty)
            .frame(width: 375)
            .fixedSize(horizontal: false, vertical: true)

        snapshotHelper.verify(matching: view, named: argument.name)
    }

    /// Testing the error states of unkown errors in different scopes (areas/features of the app).
    @Test(arguments: [ScopeArgument]([
        (name: "all_conv_files", scope: .files(conversation: .all)),
        (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
        (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
        (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
        (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
        (name: "search", scope: .search),
        (name: "move_to_folder", scope: .moveToFolder),
        (name: "edit_file", scope: .editFile)
    ]))
    @MainActor
    func testErrorUnknown(_ argument: ScopeArgument) async {
        let view = FilesInfoView(scope: argument.scope, kind: .error(isConnectionError: false))
            .frame(width: 375)
            .fixedSize(horizontal: false, vertical: true)

        snapshotHelper.verify(matching: view, named: argument.name)
    }

    /// Testing the error states of "no internet" errors in different scopes (areas/features of the app).
    @Test(arguments: [ScopeArgument]([
        (name: "all_conv_files", scope: .files(conversation: .all)),
        (name: "one_conv_files_root", scope: .files(conversation: .one, isFolder: false)),
        (name: "one_conv_files_folder", scope: .files(conversation: .one, isFolder: true)),
        (name: "recycle_bin_root", scope: .recycleBin(isFolder: false)),
        (name: "recycle_bin_folder", scope: .recycleBin(isFolder: true)),
        (name: "search", scope: .search),
        (name: "move_to_folder", scope: .moveToFolder),
        (name: "edit_file", scope: .editFile)
    ]))
    @MainActor
    func testErrorNoInternet(_ argument: ScopeArgument) async {
        let view = FilesInfoView(scope: argument.scope, kind: .error(isConnectionError: true))
            .frame(width: 375)
            .fixedSize(horizontal: false, vertical: true)

        snapshotHelper.verify(matching: view, named: argument.name)
    }

    /// Testing differnet compositions of `FilesInfoView` (with buttons, links or just text) with different sizes and
    /// color themes.
    @Test(arguments: [ScopeAndKindArgument]([
        (name: "files_empty", scope: .files(conversation: .all), kind: .empty), // this has a link
        (name: "search_empty", scope: .search, kind: .empty), // this has just text
        (name: "search_error", scope: .search, kind: .error(isConnectionError: true)) // this has a button
    ]))
    @MainActor
    func testVariants(_ argument: ScopeAndKindArgument) async {
        let view = FilesInfoView(scope: argument.scope, kind: argument.kind)
            .frame(width: 375)
            .fixedSize(horizontal: false, vertical: true)

        snapshotHelper.verify(matching: view, named: argument.name, variants: .colorSchemes)
        snapshotHelper.verify(matching: view, named: argument.name, variants: .sizes(.smallestLargeLargest))
    }
}
