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
final class CreateFileViewModel: ObservableObject {

    @Published var nameInput: String = "" {
        didSet {
            validate()
        }
    }

    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var createdNode: WireDriveNode?

    var isCreateDisabled: Bool {
        errorMessage != nil || !isInputValid
    }

    var title: String {
        switch creationTarget {
        case .folder:
            Strings.Files.NewFolder.title
        case .file:
            Strings.Files.FileName.title
        }
    }

    var navigationTitle: String {
        switch creationTarget {
        case .folder:
            Strings.Files.NewFolder.navigationTitle
        case let .file(template):
            Strings.Files.NewFile.navigationTitle(
                localizedFileExtensionName(for: template.kind),
                "." + template.fileExtension
            )
        }
    }

    var placeholder: String {
        switch creationTarget {
        case .folder:
            Strings.Files.RenameFolder.placeholder
        case .file:
            Strings.Files.RenameFile.placeholder
        }
    }

    private var inputTooLongErrorMessage: String {
        switch creationTarget {
        case .folder:
            Strings.Files.RenameFolder.folderNameTooLongError
        case .file:
            Strings.Files.RenameFile.filenameTooLongError
        }
    }

    private var alreadyExistsErrorMessage: String {
        switch creationTarget {
        case .folder:
            Strings.Files.RenameFolder.folderAlreadyExistsError
        case .file:
            Strings.Files.RenameFile.fileAlreadyExistsError
        }
    }

    private func localizedFileExtensionName(for kind: WireDriveFileTemplate.Kind) -> String {
        switch kind {
        case .document:
            Strings.Files.NewFile.document
        case .spreadsheet:
            Strings.Files.NewFile.spreadsheet
        case .presentation:
            Strings.Files.NewFile.presentation
        }
    }

    private let creationTarget: WireDriveCreateFileUseCase.Target
    private let createFileUseCase: any WireDriveCreateFileUseCaseProtocol
    private let path: String
    private let validator = TextValidator()
    private var isInputValid = true

    init(
        creationTarget: WireDriveCreateFileUseCase.Target,
        path: String,
        createFileUseCase: any WireDriveCreateFileUseCaseProtocol,
    ) {
        self.creationTarget = creationTarget
        self.createFileUseCase = createFileUseCase
        self.path = path
    }

    func create() async -> Bool {
        isFocused = false

        do {
            isLoading = true

            createdNode = try await createFileUseCase.invoke(
                creationTarget: creationTarget,
                path: path,
                name: trimmed(nameInput)
            )

            isLoading = false

            return true

        } catch let error as WireDriveCreateFileUseCaseError {
            isLoading = false
            switch error {
            case .serverFailedToCreate, .invalidPath:
                errorMessage = L10n.Localizable.General.failure
            case .alreadyExists:
                errorMessage = alreadyExistsErrorMessage
            }

            return false
        } catch {
            isLoading = false
            errorMessage = L10n.Localizable.General.failure
            WireLogger.wireDrive.error("Creating file or folder failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private let trimmed: (String) -> String = {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validate() {
        let validatorKind: TextValidator.Kind = switch creationTarget {
        case .file: .fileName
        case .folder: .folderName
        }

        let validationResult = validator.validate(trimmed(nameInput), for: validatorKind)

        isInputValid = switch validationResult {
        case .valid: true
        case .invalid: false
        }

        errorMessage = validationResult.firstLocalizedViolationMessage(for: validatorKind)
    }

}
