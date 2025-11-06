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
import WireLogging
import WireMessagingDomain

extension TagsEditView {
    @MainActor
    final class ViewModel: ObservableObject {
        private let fileItem: FilesViewItem
        private let useCases: UseCases
        private let postSaveAction: () async -> Void

        let invalidCharacters: [Character] = [",", ";", "/", "\\", "\"", "'", "<", ">"]

        @Published var enteredTag = ""
        @Published var currentTags: [String] = []
        @Published var allExistingTags: [String] = []
        @Published var isPerformingSave = false
        @Published var isSaveErrorMessagePresented = false

        let dismiss = PassthroughSubject<Void, Never>()

        enum ValidationState {
            case valid
            case empty
            case tooLong
            case invalidCharacters
        }

        init(fileItem: FilesViewItem, useCases: UseCases, postSaveAction: @escaping () async -> Void) {
            self.fileItem = fileItem
            self.currentTags = fileItem.tags
            self.useCases = useCases
            self.postSaveAction = postSaveAction

            Task {
                await loadAllExistingTags()
            }
        }

        var suggestedTags: [String] {
            allExistingTags.filter { tag in
                let isEmpty = tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let isAlreadyAdded = currentTags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
                return !isEmpty && !isAlreadyAdded
            }
        }

        var filteredSuggestedTags: [String] {
            suggestedTags.filter { tag in
                let containsEnteredText = tag
                    .localizedCaseInsensitiveContains(enteredTag.trimmingCharacters(in: .whitespacesAndNewlines))
                let enteredTextIsEmpty = enteredTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return containsEnteredText || enteredTextIsEmpty
            }
        }

        var validationState: ValidationState {
            let isEmpty = enteredTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let tooLong = enteredTag.count > 30
            let containsInvalidCharacters = enteredTag.contains { invalidCharacters.contains($0) }

            return if isEmpty {
                .empty
            } else if tooLong {
                .tooLong
            } else if containsInvalidCharacters {
                .invalidCharacters
            } else {
                .valid
            }
        }

        func validationErrorMessage(for validationState: ValidationState) -> String? {
            switch validationState {
            case .tooLong:
                return L10n.Localizable.Conversation.WireCells.Tags.Error.nameTooLong
            case .invalidCharacters:
                let message = L10n.Localizable.Conversation.WireCells.Tags.Error.specialCharacters
                let nonBreakingSpace = "\u{A0}"
                let invalidCharactersFormatted = invalidCharacters.map { String($0) }
                    .joined(separator: nonBreakingSpace)
                return message.replacing("{0}", with: invalidCharactersFormatted)
            default:
                return nil
            }
        }

        var hasChanges: Bool {
            Set(fileItem.tags) != Set(currentTags)
        }

        func addTag(_ tag: String) {
            let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let alreadyExists = currentTags.contains { $0.localizedCaseInsensitiveCompare(trimmedTag) == .orderedSame }
            if !alreadyExists {
                currentTags.append(trimmedTag)
            }
        }

        func removeTag(_ tag: String) {
            currentTags.removeAll { $0 == tag }
        }

        func loadAllExistingTags() async {
            allExistingTags = (try? await useCases.getSuggestions.invoke()) ?? []
        }

        var isSaveEnabled: Bool {
            let hasEnteredTagName = !enteredTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasChanges && !hasEnteredTagName
        }

        func save() async {
            isPerformingSave = true
            defer { isPerformingSave = false }

            do {
                try await useCases.updateTags.invoke(nodeID: fileItem.id, tags: currentTags)
                await postSaveAction()
                dismiss.send()
            } catch {
                WireLogger.wireCells.error("Error while saving tags: \(error)", attributes: .safePublic)
                isSaveErrorMessagePresented = true
            }
        }
    }
}
