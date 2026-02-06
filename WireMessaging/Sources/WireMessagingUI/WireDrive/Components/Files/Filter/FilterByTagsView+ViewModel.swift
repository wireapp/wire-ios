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

private typealias Strings = L10n.Localizable.Conversation.WireCells

extension FilterByTagsView {
    @MainActor
    package final class ViewModel: ObservableObject {

        private let tagsBatchCount = 7
        private var tags: Set<String> = []

        var navigationTitle: String {
            let selectedTagsCount = selectedTags.count
            return selectedTagsCount == 0 ? Strings.AllFiles.Filters.navigationTitle : "\(Strings.AllFiles.Filters.navigationTitle) (\(selectedTagsCount))"
        }

        @Published var presentedTags: [String] = []
        @Published var selectedTags: Set<String>
        @Published var isLoading: Bool = false
        @Published var showError: Bool = false

        private let fetchTagsUseCase: any WireDriveGetTagSuggestionsUseCaseProtocol

        init(
            fetchTagsUseCase: any WireDriveGetTagSuggestionsUseCaseProtocol,
            selectedTags: some Collection<String>
        ) {
            self.fetchTagsUseCase = fetchTagsUseCase
            self.selectedTags = Set(selectedTags)
            
            Task {
                await fetch()
            }
        }
        
        func isTagSelected(_ tag: String) -> Bool {
            selectedTags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
        }

        // MARK: - Actions

        private func fetch() async {
            do {
                isLoading = true
                defer { isLoading = false }
                let tags = try await fetchTagsUseCase.invoke()
                self.tags = Set(tags.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                self.presentedTags = tags.sorted { isTagSelected($0) && !isTagSelected($1) }
            } catch {
                showError = true
            }
        }

        func selectTag(_ tag: String) {
            if isTagSelected(tag) {
                selectedTags = selectedTags.filter { $0.localizedCaseInsensitiveCompare(tag) != .orderedSame }
            } else {
                selectedTags.insert(tag)
            }
        }

        func clearAll() async {
            selectedTags = []
        }
    }
}
