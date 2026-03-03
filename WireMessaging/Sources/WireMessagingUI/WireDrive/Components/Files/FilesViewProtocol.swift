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

package import SwiftUI
import WireDesign

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// Since `FilesView` and `FilesBrowserView` share many UI components, the extension of this protocol expose
/// common reusable views.
package protocol FilesViewProtocol: View {
    var viewModel: FilesViewModel { get }
    var isBrowsing: Bool { get }
    init(
        viewModel: @autoclosure @escaping () -> FilesViewModel,
        onOpenRecycleBin: @escaping () -> Void,
        onDismissContainer: @escaping () -> Void
    )
}

// MARK: - Default container

extension FilesViewProtocol {
        /// Common container used by both `FilesView` and `FilesBrowserView`.
        ///
        /// - Parameters:
        ///   - backgroundColor: background color for the ZStack.
        ///   - navigationTitle: title shown in the navigation bar.
        ///   - toolbarContent: toolbar content builder.
        ///   - sheetContent: sheet builder for navigation items.
    @ViewBuilder
    func defaultContainer(
        backgroundColor: Color,
        navigationTitle: String,
        @ToolbarContentBuilder toolbarContent: @escaping () -> some ToolbarContent,
        @ViewBuilder sheetContent: @escaping (FilesViewModel.SheetNavigation) -> some View
    ) -> some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea(.all)

            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    FilesFilteringView(
                        useCases: .init(fetchTagsUseCase: viewModel.useCases.getTagSuggestions),
                        filtersSelection: viewModel.filtersSelection,
                        isBrowsing: isBrowsing,
                        conversations: Set(viewModel.conversations),
                        onUpdate: viewModel.onUpdate(of:),
                        onSearchFocused: { isSearchFocused = $0 }
                    )
                    .opacity(isFilterBarPresented ? 1 : 0)
                    .frame(height: isFilterBarPresented ? nil : 0)
                    .padding(.bottom, isFilterBarPresented ? 15 : 0)

                    FilesSortingView(viewModel: viewModel.makeFilesSortingViewModel())
                }
                .padding(.top, 4)

                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .received, .pending:
                    filesList
                        .safeAreaInset(edge: .top) {
                            if viewModel.shouldShowOfflineBar {
                                offlineBar
                                    .id(UUID())
                                    .background(backgroundColor)
                            }
                        }
                case let .error(isConnectionError):
                    Spacer()
                    FilesInfoView(info: .error(isConnectionError: isConnectionError), onRetry: {
                        reloadTask()
                    })
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.connectionState)
            .animation(.easeOut(duration: 0.25), value: isSearchFocused)
            .quickLookPreview(bindableViewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbar { toolbarContent() }
            .if(viewModel.showSearchBar, transform: searchView(content:))
            .onAppear { reloadTask() }
            .onDisappear {
                isSearchFocused = false
                viewModel.resetFilters()
            }
            .alert(
                item: bindableViewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
            .sheet(
                item: bindableViewModel.sheetNavigation,
                onDismiss: {
                    Task { await viewModel.onSheetDismissed() }
                },
                content: { navigationItem in
                    sheetContent(navigationItem)
                }
            )
        }
    }

    private var isFilterBarPresented: Bool {
        isSearchFocused || !viewModel.searchText.isEmpty || viewModel.filtersSelection.hasFilterSelected
    }
}

private extension FilesViewProtocol {
    /// A helper to extract bindings from the protocol's view model.
    var bindableViewModel: ObservedObject<FilesViewModel>.Wrapper {
        ObservedObject(wrappedValue: viewModel).projectedValue
    }
}


// MARK: - List

private extension FilesViewProtocol {

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
        .listStyle(.plain)
        .refreshable { reloadTask(refreshing: true) }
        .overlay(listBackgroundView)
        .animation(.default, value: viewModel.state)
    }

    @ViewBuilder var itemsSection: some View {
        ForEach(Array(viewModel.state.items.enumerated()), id: \.element) { index, item in
            itemRow(index: index)
                .onAppear { loadMoreIfNeededTask(index: index) }
                .onTapGesture { Task { await viewModel.openItem(item: item) } }
        }
    }

    @ViewBuilder private var listBackgroundView: some View {
        switch viewModel.state {
        case let .received(items) where items.isEmpty:
            FilesInfoView(
                info: .noFilesFound(
                    scope: viewModel.isRecycleBin ? .recycleBin : isBrowsing ? .allConversations : .oneConversation,
                    isSearch: !viewModel.searchText.isEmpty || viewModel.filtersSelection != .empty
                )
            )
        case .pending:
            FilesInfoView(info: .preparingFiles)
        default:
            EmptyView()
        }
    }
}

// MARK: - Rows

private extension FilesViewProtocol {

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        FilesItemView(viewModel: viewModel.itemViewModel(index: index))
    }

    var loadMoreRow: some View {
        LoadMoreView(isLoading: viewModel.isLoading, onLoadMore: loadMore)
    }
}

// MARK: - Buttons

private extension FilesViewProtocol {

    var confirmButton: some View {
        Button(L10n.Localizable.General.confirm, action: {})
    }
}

// MARK: - Tasks

private extension FilesViewProtocol {

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

// MARK: - Offline bar

private extension FilesViewProtocol {

    var offlineBar: some View {
        FilesOfflineBarView()
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
            )
    }

}

// MARK: - SearchView

private extension FilesViewProtocol {

    @ViewBuilder
    private func searchView(content: some View) -> some View {
        content.searchable(
            text: bindableViewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Strings.Files.Search.title
        )
    }
}

// MARK: - Global helpers

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
