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
    
    struct CreateFolderModel {
        let cellName: String
        let subfoldersPath: String?
    }
    
    @Published var folderNameInput: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var didCreate: Bool = false
    
    private let createFolderUseCase: any WireCellsCreateFolderUseCaseProtocol
    private let model: CreateFolderModel
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        createFolderUseCase: any WireCellsCreateFolderUseCaseProtocol,
        model: CreateFolderModel
    ) {
        self.createFolderUseCase = createFolderUseCase
        self.model = model
        
        bindTextInput()
    }

    func create() async -> Bool {
        isFocused = false

        do {
            isLoading = true

            try await createFolderUseCase.invoke(
                rootPath: model.cellName,
                subfoldersPath: model.subfoldersPath,
                folderName: folderNameInput
            )

            didCreate = true

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
            WireLogger.wireCells.error("Creating folder failed: \(error)")
            return false
        }
    }
    
    // MARK: - Private

    private func bindTextInput() {
        $folderNameInput
            .sink { [weak self] input in
                self?.validateTextInput(input)
            }.store(in: &subscriptions)
    }

    private func validateTextInput(_ textInput: String) {
        if textInput.count > 64 {
            errorMessage = Strings.Files.NewFolder.folderNameTooLongError
        } else if textInput.contains("/") {
            errorMessage = Strings.Files.NewFolder.wrongCharacterError
        } else {
            errorMessage = nil
        }
    }
    
}
