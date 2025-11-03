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
    private var renameNodeUseCase: MockWireCellsRenameNodeUseCaseProtocol!
    private var viewModel: FileRenameViewModel!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        renameNodeUseCase = MockWireCellsRenameNodeUseCaseProtocol()

        let fileRenameModel = FileRenameViewModel.FileRenameModel(
            nodeID: .mockID1,
            filename: "foo.png",
            filepath: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Image foo.png"
        )

        viewModel = FileRenameViewModel(
            renameNodeUseCase: renameNodeUseCase,
            fileRenameModel: fileRenameModel
        )
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        renameNodeUseCase = nil
        viewModel = nil
    }

    @MainActor
    func testFilesRenameView() {
        let view = makeView()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesRenameView_WrongCharacterInputError() {
        let view = makeView()
        viewModel.filenameInput = "/"

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesRenameView_TooLongInputError() {
        let view = makeView()
        viewModel.filenameInput = Array(repeating: "r", count: 65).joined()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesRenameView_Loading() {
        let view = makeView()
        viewModel.isLoading = true

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesRenameView_FileAlreadyExistsError() async {
        let view = makeView()
        renameNodeUseCase.invokeNodeIDNodeFilepathNewFilename_MockError = WireCellsRenameNodeError.fileAlreadyExists
        _ = await viewModel.save()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilesRenameView_EmptyInput() {
        let view = makeView()
        viewModel.filenameInput = ""

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    private func makeView() -> some View {
        let viewModel = self.viewModel!
        
        return FileRenameView(viewModel: viewModel)
            .frame(width: 375, height: 667)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }

}
