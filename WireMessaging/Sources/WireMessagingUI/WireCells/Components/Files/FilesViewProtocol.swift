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

package import SwiftUI
import WireDesign

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// Since `FilesView` and `FilesBrowserView` share many UI components, the extension of this protocol expose
/// common reusable views.
package protocol FilesViewProtocol: View {
    var viewModel: FilesViewModel { get }
    var isBrowsing: Bool { get }
    init(viewModel: @autoclosure @escaping () -> FilesViewModel)
}

// MARK: - List

extension FilesViewProtocol {

    @ViewBuilder var filesList: some View {
        List {
            Group {
                itemsSection
                if viewModel.hasMore { loadMoreRow }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(ColorTheme.Backgrounds.surface.color)
        }
        .animation(.default, value: viewModel.state)
    }

    @ViewBuilder var itemsSection: some View {
        ForEach(Array(viewModel.state.items.enumerated()), id: \.element) { index, item in
            itemRow(index: index)
                .onAppear { loadMoreIfNeededTask(index: index) }
                .onTapGesture { Task { await viewModel.openItem(item: item) } }
        }
    }
}

// MARK: - Rows

extension FilesViewProtocol {

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        FilesViewItemView(
            viewModel: viewModel.itemViewModel(index: index),
            canRenameFile: !isBrowsing, // action not allowed when browsing files
            canEditTags: !isBrowsing, // action not allowed when browsing files
        )
    }

    var loadMoreRow: some View {
        LoadMoreView(isLoading: viewModel.isLoading, onLoadMore: loadMore)
    }
}

// MARK: - Buttons

extension FilesViewProtocol {

    var confirmButton: some View {
        Button(L10n.Localizable.General.confirm, action: {})
    }
}

// MARK: - Tasks

extension FilesViewProtocol {

    func reloadTask(refreshing: Bool = false) {
        Task { await viewModel.reload(refreshing: refreshing) }
    }

    func loadMoreIfNeededTask(index: Int) {
        Task { await viewModel.loadMoreIfNeeded(index: index) }
    }

    func loadMore() {
        let lastRowIndex = viewModel.state.items.count - 1
        Task { await viewModel.loadMoreIfNeeded(index: lastRowIndex) }
    }
}
