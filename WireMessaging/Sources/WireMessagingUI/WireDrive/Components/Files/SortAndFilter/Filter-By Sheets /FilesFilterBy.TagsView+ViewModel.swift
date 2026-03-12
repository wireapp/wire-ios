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
import WireFoundation
import WireMessagingDomain
import WireUtilitiesPackage

extension FilesFilterBy.TagsView {
    @MainActor
    final class ViewModel: ObservableObject {
        typealias Item = String

        @Published var presentedTags: [Item] = []
        @Published var selectedTags: Set<Item>
        @Published var searchText = "" {
            didSet {
                applySearchFilter()
            }
        }

        @Published var isLoading: Bool = false
        @Published var showError: Bool = false

        private var availableTags: [Item] = []
        private let initiallySelectedTags: Set<Item>

        private let fetchTagsUseCase: any WireDriveGetTagSuggestionsUseCaseProtocol

        init(
            fetchTagsUseCase: any WireDriveGetTagSuggestionsUseCaseProtocol,
            selectedTags: some Collection<Item>
        ) {
            self.fetchTagsUseCase = fetchTagsUseCase

            let selectedtagsSet = Set(selectedTags)

            self.selectedTags = selectedtagsSet
            self.initiallySelectedTags = selectedtagsSet

            Task {
                await fetch()
            }
        }

        var hasChanges: Bool {
            selectedTags != initiallySelectedTags
        }

        func isTagSelected(_ tag: Item) -> Bool {
            selectedTags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
        }

        // MARK: - Actions

        func fetch() async {
            do {
                isLoading = true
                defer { isLoading = false }

                let tags = try await fetchTagsUseCase.invoke()

                availableTags = tags
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .reduce(into: [String](), removingDuplicates)
                    .sorted { a, b in
                        if isTagSelected(a) != isTagSelected(b) {
                            return isTagSelected(a)
                        }

                        if a.containsEmoji != b.containsEmoji {
                            return !a.containsEmoji
                        }

                        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
                    }

                applySearchFilter()
            } catch {
                showError = true
            }
        }

        private func removingDuplicates(tags: inout [String], tag: String) {
            let normalized = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isDuplicate = tags.contains {
                $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
            }

            if !isDuplicate {
                tags.append(tag)
            }
        }

        private func applySearchFilter() {
            presentedTags = availableTags.filter { tag in
                let cleanSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                return if cleanSearchText.isEmpty {
                    true
                } else {
                    tag.localizedCaseInsensitiveContains(cleanSearchText)
                }
            }
        }

        func toggleTag(_ tag: Item) {
            if isTagSelected(tag) {
                selectedTags = selectedTags.filter { $0.localizedCaseInsensitiveCompare(tag) != .orderedSame }
            } else {
                selectedTags.insert(tag)
            }
        }

        func clearAll() {
            selectedTags = []
        }
    }
}
