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
import Foundation
import SwiftUI
import WireLogging
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

@MainActor
final class FileRenameViewModel: ObservableObject {

    struct Model {
        let nodeID: UUID
        let filename: String
        let filepath: String
    }

    @Published var filenameInput: String
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var didRename: Bool = false

    var isSaveDisabled: Bool {
        errorMessage != nil || !isInputValid
    }

    private let renameNodeUseCase: any WireCellsRenameNodeUseCaseProtocol
    private let model: Model
    private let kind: FilesViewItem.Kind
    private var subscriptions = Set<AnyCancellable>()
    private let filenameValidator = FilenameValidator()
    private var isInputValid = true

    var title: String {
        switch kind {
        case .folder:
            Strings.Files.FolderName.title
        case .file:
            Strings.Files.FileName.title
        }
    }

    var placeholder: String {
        switch kind {
        case .folder:
            Strings.Files.RenameFolder.placeholder
        case .file:
            Strings.Files.RenameFile.placeholder
        }
    }

    var navigationTitle: String {
        switch kind {
        case .folder:
            Strings.Files.RenameFolder.navigationTitle
        case .file:
            Strings.Files.RenameFile.navigationTitle
        }
    }

    private var inputTooLongErrorMessage: String {
        switch kind {
        case .folder:
            Strings.Files.RenameFolder.folderNameTooLongError
        case .file:
            Strings.Files.RenameFile.filenameTooLongError
        }
    }

    private var alreadyExistsErrorMessage: String {
        switch kind {
        case .folder:
            Strings.Files.RenameFolder.folderAlreadyExistsError
        case .file:
            Strings.Files.RenameFile.fileAlreadyExistsError
        }
    }

    init(
        renameNodeUseCase: any WireCellsRenameNodeUseCaseProtocol,
        model: Model,
        kind: FilesViewItem.Kind
    ) {
        self.renameNodeUseCase = renameNodeUseCase
        self.filenameInput = kind == .folder ? model.filename : Self.removeFileExtension(from: model.filename)
        self.model = model
        self.kind = kind

        bindTextInput()
    }

    func save() async -> Bool {
        isFocused = false

        do {
            isLoading = true
            let nodeID = model.nodeID
            let nodeFilePath = model.filepath

            try await renameNodeUseCase.invoke(
                nodeID: nodeID,
                nodeFilepath: nodeFilePath,
                newFilename: filenameInput,
                isFolder: kind == .folder
            )

            didRename = true

            return true

        } catch let error as WireCellsRenameNodeError {
            isLoading = false
            switch error {
            case .serverFailedToRenameNode, .invalidPath:
                errorMessage = L10n.Localizable.General.failure
            case .fileAlreadyExists:
                errorMessage = alreadyExistsErrorMessage
            }

            return false
        } catch {
            isLoading = false
            errorMessage = L10n.Localizable.General.failure
            WireLogger.wireCells.error("Renaming file failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func bindTextInput() {
        $filenameInput
            .flatMap(filenameValidator.validate)
            .sink(receiveValue: handleValidationResult)
            .store(in: &subscriptions)
    }

    private func handleValidationResult(_ result: Result<Void, FilenameValidator.Failure>) {
        switch result {
        case .success:
            isInputValid = true
            errorMessage = nil
        case let .failure(failure):
            isInputValid = false
            switch failure {
            case .tooLong:
                errorMessage = inputTooLongErrorMessage
            case .slashCharacter:
                errorMessage = Strings.Files.RenameFile.wrongCharacterError
            default:
                errorMessage = nil
            }
        }
    }

    // MARK: - Helpers

    static func removeFileExtension(from filename: String) -> String {
        URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
    }
}
