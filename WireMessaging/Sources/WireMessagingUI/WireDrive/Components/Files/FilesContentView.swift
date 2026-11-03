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
import WireLocators

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// Common view used by both `FilesView` and `FilesBrowserView`.
///
/// - Parameters:
///   - viewModel: viewModel reference
///   - isBrowsing: bool for when we are on browsing view
///   - backgroundColor: background color for the ZStack.
///   - toolbarContent: toolbar content builder.
///   - sheetContent: sheet builder for navigation items.
package struct FilesContentView<Toolbar: ToolbarContent, Sheet: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject package var viewModel: FilesViewModel
    package let isBrowsing: Bool
    package let backgroundColor: Color
    package let trackerHeight: CGFloat

    @ToolbarContentBuilder package let toolbarContent: () -> Toolbar
    @ViewBuilder let sheetContent: (FilesViewModel.SheetNavigation) -> Sheet

    @State private var isSearchFocused = false
    @State private var floatingBarHeight: CGFloat = 0

    package var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea(.all)

            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.showFiltersBar {
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
                    }

                    if viewModel.showReadOnlyBanner {
                        ConversationViewerAccessBanner(backgroundColor: ColorTheme.Buttons.Secondary
                            .disabledOutline) {
                                viewModel.dismissReadOnlyBanner()
                            }.padding(.bottom, viewModel.isOffline ? 0 : 15)
                    }

                    if viewModel.showFiltersBar {
                        FilesSortingView(viewModel: viewModel.filesSortingViewModel())
                    }
                }
                .padding(.top, 4)

                Spacer()

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
                            }
                        }
                case let .error(isConnectionError):
                    FilesInfoView(
                        scope: .files(conversation: isBrowsing ? .all : .one),
                        kind: .error(isConnectionError: isConnectionError),
                        onRetry: {
                            reloadTask()
                        }
                    )
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.isOffline)
            .animation(.easeOut(duration: 0.25), value: isSearchFocused)
            .quickFilePreview($viewModel.quickPreviewItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbar { toolbarContent() }
            .if(viewModel.showSearchBar, transform: searchView(content:))
            .onAppear {
                viewModel.enableMultipleSelection(false)
            }
            .onDisappear {
                isSearchFocused = false
                viewModel.resetFilters()
            }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
            .sheet(
                item: $viewModel.sheetNavigation,
                content: { navigationItem in
                    sheetContent(navigationItem)
                }
            )
        }
        .onChange(of: viewModel.networkStatus) { _, newValue in
            guard let newValue else { return }

            if newValue == .disconnected {
                viewModel.enableMultipleSelection(false)
            }

            Task {
                await viewModel.reload(refreshing: true)
            }
        }
        .onChange(of: isSearchFocused) { _, newValue in
            guard newValue else { return }
            viewModel.enableMultipleSelection(false)
        }
        .task {
            await viewModel.setup()
            await viewModel.reload()
        }
    }

    private var isFilterBarPresented: Bool {
        isSearchFocused || !viewModel.searchText.isEmpty || viewModel.filtersSelection.hasFilterSelected
    }
}

// MARK: - List

private extension FilesContentView {

    @ViewBuilder var filesList: some View {
        List(selection: $viewModel.selectedItems) {
            Group {
                itemsSection

                if showLoadMoreRow {
                    loadMoreRow
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(ColorTheme.Backgrounds.surface.color)
        }
        .environment(\.editMode, $viewModel.multipleSelection)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.multipleSelection)
        .listStyle(.plain)
        .refreshable { reloadTask(refreshing: true) }
        .overlay(listBackgroundView)
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                if viewModel.multipleSelection == .active {
                    FilesFloatingActionBar(actions: floatingBarActions)
                        .disabled(viewModel.selectedItems.isEmpty)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                            floatingBarHeight = $0
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.multipleSelection)
        }
        .animation(.default, value: viewModel.state)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: trackerHeight)
        }
        .overlay(alignment: .bottom) {
            if let warningID = viewModel.offlineActionWarningID {
                folderOfflineWarning
                    .padding(.horizontal, 16)
                    .padding(
                        .bottom,
                        trackerHeight + 12 + (viewModel.multipleSelection == .active ? floatingBarHeight + 12 : 0)
                    )
                    .transition(.opacity)
                    .task(id: warningID) {
                        try? await Task.sleep(for: .seconds(4))
                        guard viewModel.offlineActionWarningID == warningID else { return }
                        viewModel.offlineActionWarningID = nil
                    }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.offlineActionWarningID)

    }

    var folderOfflineWarning: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
                .accessibilityHidden(true)
            Text(viewModel.offlineActionWarningMessage)
                .foregroundStyle(ColorTheme.Backgrounds.onBackground.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(for: .subline1)
        .padding(16)
        .background(ColorTheme.Backgrounds.background.color, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.Backgrounds.onSurface.color.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.offlineActionWarningMessage)
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.folderOfflineWarning.rawValue)
    }

    var floatingBarActions: [FilesFloatingActionBar.Action] {
        var actions: [FilesFloatingActionBar.Action] = []

        if viewModel.isOffline {
            // remove offline access
            actions.append(
                .init(
                    id: Locators.WireDrive.FilesPage.removeAvailableOfflineFloatingButton.rawValue,
                    title: Strings.Files.Item.Menu.removeAvailableOffline,
                    systemImage: "xmark.circle",
                    isEnabled: !viewModel.selectedItems.isEmpty,
                    perform: { viewModel.removeAssetAvailableOffline(items: viewModel.selectedItems) }
                )
            )
        } else {
            if viewModel.isRecycleBin {
                // restore
                actions.append(
                    .init(
                        id: Locators.WireDrive.FilesPage.restoreFloatingButton.rawValue,
                        title: Strings.RecycleBin.Item.Menu.restore,
                        systemImage: "arrow.uturn.backward",
                        isEnabled: !viewModel.selectedItems.isEmpty,
                        perform: { viewModel.isPresentingRestoreConfirmation = true }
                    )
                )
            } else {
                // move to folder
                actions.append(
                    .init(
                        id: Locators.WireDrive.FilesPage.moveToFolderFloatingButton.rawValue,
                        title: Strings.Files.Item.Menu.moveToFolder,
                        systemImage: "folder",
                        isEnabled: !viewModel.selectedItems.isEmpty,
                        perform: viewModel.moveSelectedItemsToFolder
                    )
                )
            }

            // delete
            actions.append(
                .init(
                    id: Locators.WireDrive.FilesPage.deleteFloatingButton.rawValue,
                    title: Strings.Files.Item.Menu.delete,
                    systemImage: "trash",
                    isEnabled: !viewModel.selectedItems.isEmpty,
                    perform: { viewModel.isPresentingDeleteConfirmation = true }
                )
            )

            if !viewModel.isRecycleBin, viewModel.state.items.contains(where: { $0.kind == .file }) {
                let selectedIDs = Set(viewModel.selectedItems.filter { $0.kind == .file }.map(\.id))
                let availableOfflineIDs = Set(viewModel.availableOfflineAssets.map(\.nodeID))

                if !selectedIDs.isDisjoint(with: availableOfflineIDs) {
                    actions.append(
                        .init(
                            id: Locators.WireDrive.FilesPage.removeAvailableOfflineFloatingButton.rawValue,
                            title: Strings.Files.Item.Menu.removeAvailableOffline,
                            systemImage: "xmark.circle",
                            isEnabled: !viewModel.selectedItems.isEmpty,
                            perform: { viewModel.removeAssetAvailableOffline(items: viewModel.selectedItems) }
                        )
                    )
                }

                if !selectedIDs.isSubset(of: availableOfflineIDs) {
                    actions.append(
                        .init(
                            id: Locators.WireDrive.FilesPage.makeAvailableOfflineFloatingButton.rawValue,
                            title: Strings.Files.Item.Menu.makeAvailableOffline,
                            systemImage: "arrow.down.circle",
                            isEnabled: !viewModel.selectedItems.isEmpty,
                            perform: { viewModel.makeAssetsAvailableOffline(items: viewModel.selectedItems) }
                        )
                    )
                }
            }
        }

        return actions
    }

    @ViewBuilder var itemsSection: some View {
        ForEach(Array(viewModel.state.items.enumerated()), id: \.element) { index, item in
            itemRow(index: index)
                .onAppear { loadMoreIfNeededTask(index: index) }
                // otherwise interferes with the tappable area
                .if(viewModel.multipleSelection != .active) { view in
                    view.onTapGesture { Task { await viewModel.performPrimaryAction(item: item) } }

                }
                .accessibilityIdentifier(Locators.WireDrive.FilesContentPage.fileItem(index))
        }
    }

    private func infoViewScope() -> FilesInfoView.Scope {
        if viewModel.isRecycleBin {
            .recycleBin(isFolder: viewModel.isInFolder)
        } else if !viewModel.searchText.isEmpty || viewModel.filtersSelection != .empty {
            .search
        } else {
            .files(conversation: isBrowsing ? .all : .one, isFolder: viewModel.isInFolder)
        }
    }

    @ViewBuilder private var listBackgroundView: some View {
        let scope = infoViewScope()

        switch viewModel.state {
        case let .received(items) where items.isEmpty:
            VStack(spacing: 0) {
                if viewModel.isOffline {
                    FilesOfflineBarView(showHint: viewModel.shouldShowOfflineBarHint)
                }

                Spacer()

                FilesInfoView(scope: scope, kind: .empty)

                Spacer()
            }
        case .pending:
            FilesInfoView(scope: scope, kind: .preparing)
        default:
            EmptyView()
        }
    }

    private var showLoadMoreRow: Bool {
        // workaround: when filtering by conversation, BE returns sometimes empty payload with hasMore flag set to true
        // which wrongly displays the load more row on an empty state screen so we need here to explicitly check that
        // the items are empty.
        let hasMore = viewModel.filesController.hasMore
        let isEmptyItems = viewModel.state.items.isEmpty
        let isOffline = viewModel.isOffline

        return hasMore && !isEmptyItems && !isOffline
    }
}

// MARK: - Rows

private extension FilesContentView {

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        FilesItemView(viewModel: viewModel.itemViewModel(index: index))
            .transaction { transaction in
                // Keep row content still while the list animates its native selection controls.
                transaction.animation = nil
            }
    }

    var loadMoreRow: some View {
        LoadMoreView(isLoading: viewModel.filesController.isLoading, onLoadMore: loadMoreTask)
    }
}

// MARK: - Buttons

private extension FilesContentView {

    var confirmButton: some View {
        Button(L10n.Localizable.General.confirm, action: {})
            .accessibilityIdentifier(Locators.WireDrive.FilesContentPage.confirm)
    }
}

// MARK: - Tasks

private extension FilesContentView {

    func reloadTask(refreshing: Bool = false) {
        Task { await viewModel.reload(refreshing: refreshing) }
    }

    func loadMoreIfNeededTask(index: Int) {
        Task { await viewModel.loadMoreIfNeeded(index: index) }
    }

    func loadMoreTask() {
        let lastRowIndex = viewModel.state.items.count - 1
        Task { await viewModel.loadMoreIfNeeded(index: lastRowIndex) }
    }
}

// MARK: - Offline bar

private extension FilesContentView {

    var offlineBar: some View {
        FilesOfflineBarView(showHint: viewModel.shouldShowOfflineBarHint)
            .background(backgroundColor)
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
            )
    }

}

// MARK: - SearchView

private extension FilesContentView {

    @ViewBuilder
    private func searchView(content: some View) -> some View {
        content.searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Strings.Files.Search.title
        )
    }
}

// MARK: - View helper

private extension View {
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
