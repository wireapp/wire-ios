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

import Combine
import QuickLook
package import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// Allows browsing files shared across all conversations
package struct FilesBrowserView: FilesViewProtocol {
    @StateObject package var viewModel: FilesViewModel
    package var isBrowsing: Bool { true }
    @State private var isSearchFocused = false

    package init(
        viewModel: @autoclosure @escaping () -> FilesViewModel,
        onOpenRecycleBin: @escaping () -> Void = {},
        onDismissContainer: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    package var body: some View {
        ZStack {
            ColorTheme.Backgrounds.surface.color
                .ignoresSafeArea(.all)

            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    FilesFilteringView(
                        useCases: .init(fetchTagsUseCase: viewModel.useCases.getTagSuggestions),
                        filtersSelection: viewModel.filtersSelection,
                        isBrowsing: isBrowsing,
                        conversations: Set(viewModel.conversations),
                        onUpdate: { selection in
                            viewModel.filtersSelection = selection
                        }
                    )
                    .opacity(isFilterBarPresented ? 1 : 0)
                    .frame(height: isFilterBarPresented ? nil : 0)
                    .padding(.bottom, isFilterBarPresented ? 15 : 0)
                    
                    FilesSortingView(viewModel: viewModel.makeFilesSortingViewModel())
                }
                .padding(.top, 4)

                switch viewModel.state {
                case .loading:
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                case .received, .pending:
                    if viewModel.connectionState == .offline {
                        Spacer()
                        offlineBar.id(UUID())
                        Spacer()
                    }

                    filesList
                case let .error(isConnectionError):
                    FilesInfoView(info: .error(isConnectionError: isConnectionError), onRetry: {
                        reloadTask()
                    })
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.connectionState)
            .animation(.easeOut(duration: 0.25), value: isSearchFocused)
            .quickLookPreview($viewModel.viewingURL)
            .navigationTitle(Strings.AllFiles.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(ColorTheme.Backgrounds.surface.color, for: .navigationBar)
            .toolbar { toolbarContent }
            .if(viewModel.showSearchBar, transform: searchView(content:))
            .onAppear { reloadTask() }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
            .sheet(item: $viewModel.sheetNavigation) {
                Task { await viewModel.onSheetDismissed() }
            } content: { navigationItem in
                switch navigationItem {
                case .filterByTagsOld:
                    FilesFilterBy.TagsView(
                        fetchTagsUseCase: viewModel.useCases.getTagSuggestions,
                        selectedItems: viewModel.filterWithTags,
                        onApply: { selectedTags in
                            viewModel.filterWithTags = [String](selectedTags)
                            viewModel.shouldReload = true
                        }
                    )
                case let .shareLink(shareLinkView):
                    shareLinkView
                default:
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private func searchView(content: some View) -> some View {
        content.searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer,
            prompt: Strings.Files.Search.title
        )
        .onReceive(NotificationCenter.default.publisher(
            for: UISearchTextField.textDidBeginEditingNotification
        )) { _ in
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UISearchTextField.textDidEndEditingNotification
        )) { _ in
            isSearchFocused = false
        }
    }

    private var isFilterBarPresented: Bool {
        isSearchFocused || !viewModel.searchText.isEmpty || viewModel.filtersSelection.hasFilterSelected
    }
}

// MARK: - Toolbar

private extension FilesBrowserView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.openFilters()
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }

        }
    }

}

// MARK: - Helper

extension View {
    @ViewBuilder
    func `if`(
        _ condition: Bool,
        transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        FilesBrowserView(viewModel: .preview(isBrowsing: true))
    }
}
