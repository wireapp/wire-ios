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

    @Published var filenameInput: String {
        didSet {
            validate()
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var didRename: Bool = false

    var isSaveDisabled: Bool {
        errorMessage != nil || !isInputValid
    }

    private let renameNodeUseCase: any WireDriveRenameNodeUseCaseProtocol
    private let model: Model
    private let kind: FilesViewItem.Kind
    private let validator = TextValidator()
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

    private let trimmed: (String) -> String = {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        renameNodeUseCase: any WireDriveRenameNodeUseCaseProtocol,
        model: Model,
        kind: FilesViewItem.Kind
    ) {
        self.renameNodeUseCase = renameNodeUseCase
        self.filenameInput = kind == .folder ? model.filename : Self.removeFileExtension(from: model.filename)
        self.model = model
        self.kind = kind
    }

    func save() async -> Bool {
        isFocused = false

        do {
            isLoading = true
            let nodeID = model.nodeID
            let nodeFilePath = model.filepath

            let originalFilename = URL(fileURLWithPath: model.filename).deletingPathExtension().lastPathComponent

            // The backend doesn't allow to only change the case so we consider case changes as no changes.
            let fileNameChanged = originalFilename.caseInsensitiveCompare(filenameInput) != .orderedSame

            if fileNameChanged {
                try await renameNodeUseCase.invoke(
                    nodeID: nodeID,
                    nodeFilepath: nodeFilePath,
                    newFilename: trimmed(filenameInput),
                    isFolder: kind == .folder
                )

                didRename = true
            }

            return true

        } catch let error as WireDriveRenameNodeError {
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
            WireLogger.wireDrive.error("Renaming file failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func validate() {
        let validatorKind: TextValidator.Kind = switch kind {
        case .file: .fileName
        case .folder: .folderName
        }
        
        let validationResult = validator.validate(trimmed(filenameInput), for: validatorKind)
        
        isInputValid = switch validationResult {
        case .valid: true
        case .invalid: false
        }
        
        errorMessage = validationResult.firstLocalizedViolationMessage(for: validatorKind)
    }

    // MARK: - Helpers

    static func removeFileExtension(from filename: String) -> String {
        URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
    }
}
