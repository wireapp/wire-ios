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
    
    private enum Constants {
        static let maxInputLength = 64
    }

    struct FileRenameModel {
        let nodeID: UUID
        let filename: String
        let filepath: String
    }

    @Published var filenameInput: String
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFocused: Bool = true
    @Published var didRename: Bool = false

    private let renameNodeUseCase: any WireCellsRenameNodeUseCaseProtocol
    private let fileRenameModel: FileRenameModel
    private var subscriptions = Set<AnyCancellable>()

    init(
        renameNodeUseCase: any WireCellsRenameNodeUseCaseProtocol,
        fileRenameModel: FileRenameModel
    ) {
        self.renameNodeUseCase = renameNodeUseCase
        self.filenameInput = Self.removeFileExtension(from: fileRenameModel.filename)
        self.fileRenameModel = fileRenameModel

        bindTextInput()
    }

    func save() async -> Bool {
        isFocused = false

        do {
            isLoading = true
            let nodeID = fileRenameModel.nodeID
            let nodeFilePath = fileRenameModel.filepath

            try await renameNodeUseCase.invoke(
                nodeID: nodeID,
                nodeFilepath: nodeFilePath,
                newFilename: filenameInput
            )

            didRename = true

            return true

        } catch let error as WireCellsRenameNodeError {
            isLoading = false
            switch error {
            case .serverFailedToRenameNode, .invalidPath:
                errorMessage = L10n.Localizable.General.failure
            case .fileAlreadyExists:
                errorMessage = Strings.Files.RenameFile.fileAlreadyExistsError
            }

            return false
        } catch {
            isLoading = false
            WireLogger.wireCells.error("Renaming file failed: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func bindTextInput() {
        $filenameInput
            .sink { [weak self] input in
                self?.validateTextInput(input)
            }.store(in: &subscriptions)
    }

    private func validateTextInput(_ textInput: String) {
        if textInput.count > Constants.maxInputLength {
            errorMessage = Strings.Files.RenameFile.filenameTooLongError
        } else if textInput.contains("/") {
            errorMessage = Strings.Files.RenameFile.wrongCharacterError
        } else {
            errorMessage = nil
        }
    }

    // MARK: - Helpers

    static func removeFileExtension(from filename: String) -> String {
        URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
    }
}
