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

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// View model for the `FilesFiltersView`.
@MainActor
package final class FilesFiltersViewModel: ObservableObject {
    
    struct TagModel: Hashable {
        let name: String
        var isSelected: Bool
    }
    
    private var allTags = [
        TagModel(name: "Test1", isSelected: false),
        TagModel(name: "Test2", isSelected: false),
        TagModel(name: "Test3", isSelected: false),
        TagModel(name: "Test4", isSelected: false),
        TagModel(name: "Test5", isSelected: false),
        TagModel(name: "Test6", isSelected: false),
        TagModel(name: "Test7", isSelected: false),
        TagModel(name: "Test8", isSelected: false),
        TagModel(name: "Test9", isSelected: false),
        TagModel(name: "Test10", isSelected: false),
        TagModel(name: "Test11", isSelected: false),
        TagModel(name: "Test12", isSelected: false),
        TagModel(name: "Test13", isSelected: false),
        TagModel(name: "Test14", isSelected: false),
        TagModel(name: "Test15", isSelected: false)
    ]
    
    private var mainTags: [TagModel] {
        Array(allTags.prefix(7))
    }
    
    var selectedTags: [TagModel] {
        allTags.filter(\.isSelected)
    }
    
    var showAllTagsButtonTitle: String {
        showAllTags ? Strings.AllFiles.Filters.Tags.showLess : Strings.AllFiles.Filters.Tags.showMore
    }
    
    var navigationTitle: String {
        let selectedTagsCount = allTags.filter(\.isSelected).count
        return selectedTagsCount == 0 ? Strings.AllFiles.Filters.navigationTitle : "\(Strings.AllFiles.Filters.navigationTitle) (\(selectedTagsCount))"
    }
    
    @Published var presentedTags: [TagModel] = []
    @Published var isLoading: Bool = false
    @Published var didApplyTags: [TagModel] = []
    private var showAllTags = false
    
    init() {
        presentedTags = mainTags
    }
    
    func selectTag(tag: TagModel) {
        guard let tagIndex = allTags.firstIndex(where: { tag.name == $0.name }) else { return }
        allTags[tagIndex].isSelected.toggle()
        presentedTags[tagIndex].isSelected.toggle()
    }

    func expandOrCollapse() {
        showAllTags.toggle()
        presentedTags = showAllTags ? allTags : mainTags
        
    }
    
    func apply() async {
        didApplyTags = selectedTags
    }
    
    func clearAll() async {
        allTags.indices.forEach {
            allTags[$0].isSelected = false
        }
        presentedTags.indices.forEach {
            presentedTags[$0].isSelected = false
        }
    }
}
