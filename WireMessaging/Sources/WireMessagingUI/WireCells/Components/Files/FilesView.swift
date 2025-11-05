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
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

package struct FilesView: FilesViewProtocol {
    @ObservedObject package var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    package init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.Backgrounds.background.color
                    .ignoresSafeArea(.all)

                Group {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case let .received(items):
                        VStack(spacing: 0) {
                            if items.isEmpty {
                                Spacer()
                                FilesInfoView(info: .noFilesFound(scope: .oneConversation))
                                Spacer()
                            } else {
                                filesList
                                    .listStyle(.plain)
                                    .refreshable { reloadTask(refreshing: true) }
                            }
                            
                            createFolderView
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar) // shows navigation bar divider
                .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
                .toolbar { toolbarContent }
                .onAppear { reloadTask() }
                .alert(
                    item: $viewModel.alert,
                    title: { Text($0.title) },
                    message: { Text($0.message) },
                    actions: { _ in confirmButton }
                )
                .sheet(
                    item: $viewModel.createFolderView,
                    onDismiss: {
                        if viewModel.didCreateFolder {
                            reloadTask()
                            viewModel.didCreateFolder = false
                        }
                    },
                    content: { $0 }
                )

            }
        }
    }
    
    private var createFolderView: some View {
        VStack {
            Divider()

            HStack(spacing: 29) {
                Button {
                    viewModel.onCreateFolder()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                }

                Text(Strings.Files.NewFolder.title)
                    .wireTextStyle(.body2)
                Spacer()
            }
            .padding()
        }
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
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier("close")
    }
}

#Preview {
    FilesView(viewModel: .preview())
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}
