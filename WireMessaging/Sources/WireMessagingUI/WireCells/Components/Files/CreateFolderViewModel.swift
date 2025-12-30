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
final class CreateFolderViewModel: ObservableObject {

    @Published var folderNameInput: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var didCreate: Bool = false

    var isCreateDisabled: Bool {
        errorMessage != nil || !isInputValid
    }

    private let createFolderUseCase: any WireCellsCreateFolderUseCaseProtocol
    private let folderPath: String
    private var subscriptions = Set<AnyCancellable>()
    private let filenameValidator = FilenameValidator()
    private var isInputValid = true

    init(
        createFolderUseCase: any WireCellsCreateFolderUseCaseProtocol,
        folderPath: String
    ) {
        self.createFolderUseCase = createFolderUseCase
        self.folderPath = folderPath

        bindTextInput()
    }

    func create() async -> Bool {
        isFocused = false

        do {
            isLoading = true

            try await createFolderUseCase.invoke(
                folderPath: folderPath,
                folderName: folderNameInput
            )

            didCreate = true
            isLoading = false

            return true

        } catch let error as WireCellsCreateFolderUseCaseError {
            isLoading = false
            switch error {
            case .serverFailedToCreateFolder:
                errorMessage = L10n.Localizable.General.failure
            case .folderAlreadyExists:
                errorMessage = Strings.Files.NewFolder.folderAlreadyExistsError
            }

            return false
        } catch {
            isLoading = false
            errorMessage = L10n.Localizable.General.failure
            WireLogger.wireCells.error("Creating folder failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func bindTextInput() {
        $folderNameInput
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
                errorMessage = Strings.Files.NewFolder.folderNameTooLongError
            case .slashCharacter, .dotPrefix:
                errorMessage = Strings.Files.RenameFile.wrongCharacterError
            case .empty, .containsWhitespace:
                errorMessage = nil
            }
        }
    }

}
