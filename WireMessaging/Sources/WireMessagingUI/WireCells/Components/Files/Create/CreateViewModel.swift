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
import Foundation
import SwiftUI
import WireLogging
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

@MainActor
final class CreateViewModel: ObservableObject {

    @Published var nameInput: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var createdNode: WireCellsNode?

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
            switch template.templateKind {
            case .document:
                Strings.Files.NewFile.navigationTitle(".docx")
            case .presentation:
                Strings.Files.NewFile.navigationTitle(".pptx")
            case .spreadsheet:
                Strings.Files.NewFile.navigationTitle(".xlsx")
            }
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

    private let creationTarget: CreationTarget
    private let createUseCase: any WireCellsCreateUseCaseProtocol
    private let path: String
    private var subscriptions = Set<AnyCancellable>()
    private let filenameValidator = FilenameValidator()
    private var isInputValid = true

    init(
        creationTarget: CreationTarget,
        path: String,
        createUseCase: any WireCellsCreateUseCaseProtocol,
    ) {
        self.creationTarget = creationTarget
        self.createUseCase = createUseCase
        self.path = path

        bindTextInput()
    }

    func create() async -> Bool {
        isFocused = false

        do {
            isLoading = true

            createdNode = try await createUseCase.invoke(
                creationTarget: creationTarget,
                path: path,
                name: nameInput
            )

            isLoading = false

            return true

        } catch let error as WireCellsCreateUseCaseError {
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
            WireLogger.wireCells.error("Creating file or folder failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func bindTextInput() {
        $nameInput
            .compactMap { [weak self] input in
                self?.filenameValidator.validate(input)
            }
            .flatMap(\.self)
            .sink { [weak self] result in
                self?.handleValidationResult(result)
            }.store(in: &subscriptions)
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
            case .dotPrefix:
                errorMessage = Strings.Files.RenameFile.dotPrefix
            case .empty:
                errorMessage = nil
            }
        }
    }

}
