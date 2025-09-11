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
import QuickLook
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

package struct FilesView: View {
    @ObservedObject var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    package init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .received:
                    filesList
                        .listStyle(.plain)
                        .refreshable { reloadTask() }
                case .noData:
                    InfoView(info: .noFilesFound)
                case .pending:
                    InfoView(info: .preparingFiles)
                }
            }
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { reloadTask() }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
        }
    }
}

// MARK: - List

private extension FilesView {

    @ViewBuilder var filesList: some View {
        List {
            Group {
                itemsSection
                if viewModel.hasMore { loadMoreRow }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder var itemsSection: some View {
        ForEach(Array(viewModel.state.items.enumerated()), id: \.element) { index, item in
            itemRow(index: index)
                .onAppear { loadMoreIfNeededTask(index: index) }
                .onTapGesture { Task { await viewModel.viewAsset(item: item) } }
        }
    }
}

// MARK: - Rows

private extension FilesView {

    @ViewBuilder
    func itemRow(index: Int) -> some View {
        FilesViewItemView(viewModel: viewModel.itemViewModel(index: index))
    }

    var loadMoreRow: some View {
        LoadMoreView(isLoading: viewModel.isLoading, onLoadMore: loadMore)
    }
}

// MARK: - Toolbar

private extension FilesView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) { titleView }
        ToolbarItem(placement: .navigationBarTrailing) { closeButton }
    }

    var titleView: some View {
        Text(Strings.Files.navigationTitle)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(SemanticColors.Label.textDefault.color)
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Image(.close)
                    .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier("close")
    }
}

// MARK: - Buttons

private extension FilesView {

    var confirmButton: some View {
        Button(L10n.Localizable.General.confirm, action: {})
    }
}

// MARK: - Tasks

private extension FilesView {

    func reloadTask() {
        Task { await viewModel.reload() }
    }

    func loadMoreIfNeededTask(index: Int) {
        Task { await viewModel.loadMoreIfNeeded(index: index) }
    }

    func loadMore() {
        let lastRowIndex = viewModel.state.items.count - 1
        Task { await viewModel.loadMoreIfNeeded(index: lastRowIndex) }
    }
}

private struct LoadMoreView: View {
    let isLoading: Bool
    let onLoadMore: () -> Void

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Button(Strings.Files.LoadMore.title, action: onLoadMore)
                    .accessibilityLabel(Accessibility.Files.LoadMore.title)
                    .accessibilityIdentifier("load-more")
                    .buttonStyle(.borderless)
                    .wireTextStyle(.body3)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)

            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    }

}

private struct InfoView: View {

    enum Info {
        case preparingFiles
        case noFilesFound
    }

    let info: Info

    var body: some View {
        VStack(spacing: 25) {
            Text(info == .preparingFiles ? Strings.Files.PendingCells.title : Strings.Files.NoData.title)
                .padding([.leading, .trailing], info == .preparingFiles ? 30 : 0)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.textDefault.color)
                .accessibilityLabel(
                    info == .preparingFiles ? Accessibility.Files.PendingCells.title : Accessibility
                        .Files.NoData.title
                )
                .accessibilityIdentifier(info == .preparingFiles ? "preparing-files-title" : "no-files-title")

            Text(info == .preparingFiles ? Strings.Files.PendingCells.message : Strings.Files.NoData.message)
                .padding([.leading, .trailing], info == .preparingFiles ? 0 : 30)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.baseSecondaryText.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(
                    info == .preparingFiles ? Accessibility.Files.PendingCells.message : Accessibility
                        .Files.NoData.message
                )
                .accessibilityIdentifier(info == .preparingFiles ? "preparing-files-message" : "no-files-message")
        }
        .padding(20)
        .frame(maxWidth: 420)
        .padding()
    }
}

#Preview {
    FilesView(viewModel: .preview())
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
