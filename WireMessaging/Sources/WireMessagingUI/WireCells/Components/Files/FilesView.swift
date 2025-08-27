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
            List {
                Group {
                    ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                        FilesViewItemView(viewModel: viewModel.itemViewModel(index: index))
                            .onAppear { Task { await viewModel.loadMoreIfNeeded(index: index) } }
                            .onTapGesture { viewModel.viewAsset(item: item) }
                    }

                    if viewModel.hasMore {
                        LoadMoreView(isLoading: viewModel.isLoading, onLoadMore: loadMore)
                    }

                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .refreshable { Task { await viewModel.reload() } }
            .onAppear { Task { await viewModel.reload() } }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in
                    Button(L10n.Localizable.General.confirm, action: {})
                }
            )
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.Files.navigationTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SemanticColors.Label.textDefault.color)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(.close)
                            .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                    }
                    .accessibilityLabel(Accessibility.Files.close)
                    .accessibilityIdentifier("close")
                }
            }
        }
    }

    private func loadMore() {
        let lastRowIndex = viewModel.items.count - 1
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

#Preview {
    FilesView(viewModel: .preview())
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
