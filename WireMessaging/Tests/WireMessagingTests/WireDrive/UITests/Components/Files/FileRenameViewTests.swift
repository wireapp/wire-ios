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

import Combine
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FileRenameViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var renameNodeUseCase: MockWireDriveRenameNodeUseCaseProtocol!
    private var viewModel: FileRenameViewModel!
    private let kinds = [FilesViewItem.Kind.file, .folder]

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        renameNodeUseCase = MockWireDriveRenameNodeUseCaseProtocol()
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        renameNodeUseCase = nil
    }

    @MainActor
    func testFileRenameView() {
        for kind in kinds {
            let (_, view) = makeView(kind: kind)
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testFileRenameView_WrongCharacterInputError() {
        for kind in kinds {
            let (viewModel, view) = makeView(kind: kind)
            viewModel.filenameInput = "/"
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testFileRenameView_TooLongInputError() {
        for kind in kinds {
            let (viewModel, view) = makeView(kind: kind)
            viewModel.filenameInput = Array(repeating: "r", count: 65).joined()
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testFileRenameView_Loading() {
        for kind in kinds {
            let (viewModel, view) = makeView(kind: kind)
            viewModel.isLoading = true
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testFileRenameView_AlreadyExistsError() async {
        for kind in kinds {
            let (viewModel, view) = makeView(kind: kind)
            renameNodeUseCase.invokeNodeIDNodeFilepathNewFilenameIsFolder_MockError = WireDriveRenameNodeError
                .fileAlreadyExists
            _ = await viewModel.save()
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testFileRenameView_EmptyInput() {

        for kind in kinds {
            let (viewModel, view) = makeView(kind: kind)
            viewModel.filenameInput = ""
            let name = kind == .file ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    private func makeView(kind: FilesViewItem.Kind = .file) -> (FileRenameViewModel, some View) {
        let model = FileRenameViewModel.Model(
            nodeID: .mockID1,
            filename: "foo.png",
            filepath: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.png"
        )

        let viewModel = FileRenameViewModel(
            renameNodeUseCase: renameNodeUseCase,
            model: model,
            kind: kind
        )

        let view = FileRenameView(viewModel: viewModel)
            .frame(width: 375, height: 667)

        return (viewModel, view)
    }

}
