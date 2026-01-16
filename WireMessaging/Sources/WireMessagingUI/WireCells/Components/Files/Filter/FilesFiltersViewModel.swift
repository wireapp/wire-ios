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

/// View model for the `FilesFiltersView`.
@MainActor
package final class FilesFiltersViewModel: ObservableObject {

    struct TagModel: Identifiable, Hashable {
        let id = UUID()
        let name: String
        var isSelected: Bool
    }

    private let tagsBatchCount = 7
    private var tags: [TagModel] = []
    let accentColorProvider: () -> WireAccentColor

    var selectedTags: [TagModel] {
        tags.filter(\.isSelected)
    }

    var hasMore: Bool {
        presentedTags.count < tags.count
    }

    var navigationTitle: String {
        let selectedTagsCount = selectedTags.count
        return selectedTagsCount == 0 ? Strings.AllFiles.Filters.navigationTitle : "\(Strings.AllFiles.Filters.navigationTitle) (\(selectedTagsCount))"
    }

    @Published var presentedTags: [TagModel] = []
    @Published var isLoading: Bool = false
    @Published var savedTags: [String]
    @Published var showError: Bool = false

    private let fetchTagsUseCase: any WireCellsGetTagSuggestionsUseCaseProtocol

    init(
        fetchTagsUseCase: any WireCellsGetTagSuggestionsUseCaseProtocol,
        savedTags: [String]?,
        accentColorProvider: @escaping () -> WireAccentColor

    ) {
        self.fetchTagsUseCase = fetchTagsUseCase
        self.savedTags = savedTags ?? []
        self.accentColorProvider = accentColorProvider
    }

    // MARK: - Actions

    func fetch(isRefreshing: Bool = false) async {
        do {
            if !isRefreshing { isLoading = true }
            defer { isLoading = false }
            let tags = try await fetchTagsUseCase.invoke()
            self.tags = tags
                .filter { !$0.isEmpty }
                .map { .init(name: $0, isSelected: savedTags.contains($0)) }
                .sorted { $0.isSelected && !$1.isSelected }
            showMore()
        } catch {
            showError = true
        }
    }

    func selectTag(_ tag: TagModel) {
        guard let tagIndex = tags.firstIndex(where: { tag.id == $0.id }) else { return }
        tags[tagIndex].isSelected.toggle()
        presentedTags[tagIndex].isSelected.toggle()
    }

    func showMore() {
        presentedTags += Array(tags[presentedTags.count...].prefix(tagsBatchCount))
    }

    func apply() async {
        savedTags = selectedTags.map(\.name)
    }

    func clearAll() async {
        tags.indices.forEach { tags[$0].isSelected = false }
        presentedTags.indices.forEach { presentedTags[$0].isSelected = false }
    }
}
