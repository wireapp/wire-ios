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

import Foundation
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
    
    private let collapsedTagsLimit = 7
    
    private var expandedTags: [TagModel] = []
    
    private var collapsedTags: [TagModel] {
        Array(expandedTags.prefix(collapsedTagsLimit))
    }
    
    var selectedTags: [TagModel] {
        expandedTags.filter(\.isSelected)
    }
    
    var expandButtonTitle: String {
        isExpanded ? Strings.AllFiles.Filters.Tags.showLess : Strings.AllFiles.Filters.Tags.showMore
    }
    
    var showExpandButton: Bool {
        expandedTags.count > collapsedTagsLimit
    }
    
    var navigationTitle: String {
        let selectedTagsCount = expandedTags.filter(\.isSelected).count
        return selectedTagsCount == 0 ? Strings.AllFiles.Filters.navigationTitle : "\(Strings.AllFiles.Filters.navigationTitle) (\(selectedTagsCount))"
    }
    
    @Published var presentedTags: [TagModel] = []
    @Published var isLoading: Bool = false
    @Published var appliedTags: [String]
    @Published var showError: Bool = false
    
    private var isExpanded = false
    private var preselectedTags: [String]?
    private let fetchTagsUseCase: any WireCellsGetTagSuggestionsUseCaseProtocol
    
    init(
        fetchTagsUseCase: any WireCellsGetTagSuggestionsUseCaseProtocol,
        appliedTags: [String]?
        
    ) {
        self.fetchTagsUseCase = fetchTagsUseCase
        self.appliedTags = appliedTags ?? []
    }
    
    // MARK: - Actions
    
    func fetch() async {
        do {
            isLoading = true
            defer { isLoading = false }
            let tags = try await fetchTagsUseCase.invoke()
            expandedTags = tags
                .filter { !$0.isEmpty }
                .map { .init(name: $0, isSelected: appliedTags.contains($0)) }
                .sorted { $0.isSelected && !$1.isSelected }
            presentedTags = collapsedTags
        } catch {
            showError = true
        }
    }
    
    func selectTag(tag: TagModel) {
        guard let tagIndex = expandedTags.firstIndex(where: { tag.id == $0.id }) else { return }
        expandedTags[tagIndex].isSelected.toggle()
        presentedTags[tagIndex].isSelected.toggle()
    }

    func toggleTagsVisibility() {
        isExpanded.toggle()
        presentedTags = isExpanded ? expandedTags : collapsedTags
    }
    
    func apply() async {
        appliedTags = selectedTags.map(\.name)
    }
    
    func clearAll() async {
        expandedTags.indices.forEach {
            expandedTags[$0].isSelected = false
        }
        presentedTags.indices.forEach {
            presentedTags[$0].isSelected = false
        }
    }
}
