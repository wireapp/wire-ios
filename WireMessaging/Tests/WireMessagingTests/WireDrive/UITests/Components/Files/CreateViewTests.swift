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

final class CreateViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var createUseCase: MockWireCellsCreateUseCaseProtocol!
    private var viewModel: CreateViewModel!
    private let creationTargets = [CreationTarget.file(.fixture()), .folder]

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        createUseCase = MockWireCellsCreateUseCaseProtocol()
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        createUseCase = nil
        viewModel = nil
    }

    @MainActor
    func testCreateView_WrongCharacterInputError() {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            viewModel.nameInput = "/"
            let name = creationTarget == .file(.fixture()) ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testCreateView_DotPrefixError() {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            viewModel.nameInput = "."
            let name = creationTarget == .file(.fixture()) ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testCreateView_TooLongInputError() {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            viewModel.nameInput = Array(repeating: "r", count: 65).joined()
            let name = creationTarget == .file(.fixture()) ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testCreateView_Loading() {
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
    func testCreateView_alreadyExistsError() async {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            createUseCase.invokeCreationTargetPathName_MockError = WireCellsCreateUseCaseError
                .alreadyExists
            _ = await viewModel.create()
            let name = creationTarget == .file(.fixture()) ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testCreateView_EmptyInput() {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            viewModel.nameInput = ""
            let name = creationTarget == .file(.fixture()) ? ".file." : ".folder."

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(name)" + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(name)" + "dark")
        }
    }

    @MainActor
    func testCreateView_File_Navigation_Title() {
        let kinds = [WireDriveTemplate.Kind.document, .spreadsheet, .presentation]

        for kind in kinds {
            let view = makeView(target: .file(.fixture(kind: kind)))
            viewModel.nameInput = ""
            let name = String(describing: kind)

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: ".\(name)." + "light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: ".\(name)." + "dark")
        }
    }

    @MainActor
    private func makeView(target: CreationTarget = .folder) -> some View {
        viewModel = CreateViewModel(
            creationTarget: target,
            path: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2",
            createUseCase: createUseCase
        )

        let vm = viewModel!

        return CreateView(viewModel: vm)
            .frame(width: 375, height: 667)
    }

}

private extension WireDriveTemplate {
    static func fixture(kind: Self.Kind = .document) -> WireDriveTemplate {
        WireDriveTemplate(
            kind: kind,
            editable: true,
            label: "Microsoft Word",
            UUID: "01-Microsoft Word.docx"
        )
    }
}
