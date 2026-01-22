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

final class CreateFileViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var createFileUseCase: MockWireDriveCreateFileUseCaseProtocol!
    private var viewModel: CreateFileViewModel!
    private let creationTargets = [WireDriveCreateFileUseCase.Target.file(.fixture()), .folder]

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        createFileUseCase = MockWireDriveCreateFileUseCaseProtocol()
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        createFileUseCase = nil
        viewModel = nil
    }

    @MainActor
    func testCreateFileView_WrongCharacterInputError() {
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
    func testCreateFileView_DotPrefixError() {
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
    func testCreateFileView_TooLongInputError() {
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
    func testCreateFileView_Loading() {
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
    func testCreateFileView_alreadyExistsError() async {
        for creationTarget in creationTargets {
            let view = makeView(target: creationTarget)
            createFileUseCase.invokeCreationTargetPathName_MockError = WireDriveCreateFileUseCaseError
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
    func testCreateFileView_EmptyInput() {
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
    func testCreateFileView_File_Navigation_Title() {
        let kinds = [WireDriveFileTemplate.Kind.document, .spreadsheet, .presentation]

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
    private func makeView(target: WireDriveCreateFileUseCase.Target = .folder) -> some View {
        viewModel = CreateFileViewModel(
            creationTarget: target,
            path: "5b189264-4300-4f21-8dca-7acd2b1925c7@wire.com/Folder-1/Folder-2",
            createFileUseCase: createFileUseCase
        )

        let vm = viewModel!

        return CreateFileView(viewModel: vm)
            .frame(width: 375, height: 667)
    }

}

private extension WireDriveFileTemplate {
    static func fixture(kind: Self.Kind = .document) -> WireDriveFileTemplate {
        let uuid = switch kind {
        case .document:
            "01-Microsoft Word.docx"
        case .presentation:
            "3-Microsoft PowerPoint.pptx"
        case .spreadsheet:
            "02-Microsoft Excel.xlsx"
        }
        
        let label = switch kind {
        case .document:
            "Microsoft Word"
        case .presentation:
            "Microsoft PowerPoint"
        case .spreadsheet:
            "Microsoft Excel"
        }
        
        return WireDriveFileTemplate(
            kind: kind,
            editable: true,
            label: label,
            UUID: uuid
        )
    }
}
