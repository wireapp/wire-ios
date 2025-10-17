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
package import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells

/// Allows browsing files shared across all conversations
package struct FilesBrowserView: FilesViewProtocol {
    @ObservedObject package var viewModel: FilesViewModel

    package init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        ZStack {
            ColorTheme.Backgrounds.surface.color
                .ignoresSafeArea(.all)
            Group {
                switch viewModel.state {
                case .initial:
                    Button(action: reloadTask) {
                        Image(systemName: "arrow.trianglehead.clockwise")
                            .wireTextStyle(.body3)
                            .foregroundStyle(SemanticColors.Label.textDefault.color)

                    }
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case let .received(items):
                    if items.isEmpty {
                        FilesInfoView(info: .noFilesFound(scope: .allConversations))
                    } else {
                        filesList
                            .listStyle(.plain)
                            .refreshable { reloadTask() }
                    }
                case .pending:
                    FilesInfoView(info: .preparingFiles)
                case .error:
                    FilesInfoView(info: .error, onReload: {
                        reloadTask()
                    })
                }
            }
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationTitle(Strings.AllFiles.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar) // shows navigation bar divider
            .toolbarBackground(ColorTheme.Backgrounds.surface.color, for: .navigationBar)
            .if(!viewModel.state.items.isEmpty || !viewModel.searchText.isEmpty) { view in
                view.searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer,
                    prompt: Strings.Files.Search.title
                )
            }
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

// MARK: - Helper

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

#Preview {
    NavigationStack {
        FilesBrowserView(viewModel: .preview())
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }
}
