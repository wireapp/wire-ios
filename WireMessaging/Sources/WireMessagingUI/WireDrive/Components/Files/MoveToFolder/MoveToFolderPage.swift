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

import SwiftUI
import WireDesign

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

// MARK: - MoveToFolderPage

struct MoveToFolderPage<ViewModel>: View where ViewModel: MoveToFolderPageViewModelProtocol {

    @StateObject private var viewModel: ViewModel

    package init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack {
            switch viewModel.content {
            case .initialLoad:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(items, hasMore, isLoading):
                List {
                    Group {
                        ForEach(items) { item in
                            MoveToFolderItemView(item: item)
                                .onTapGesture {
                                    viewModel.select(item: item)
                                }
                        }
                        if hasMore {
                            LoadMoreView(isLoading: isLoading, onLoadMore: { Task { await viewModel.loadMore() } })
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(ColorTheme.Backgrounds.surface.color)
                }
                .listStyle(.plain)
                .refreshable { await viewModel.reload() }
            case let .empty(title, message, showsReload):
                MoveToFolderEmptyStateView(
                    title: title,
                    message: message,
                    onReload: showsReload ? { Task { await viewModel.reload() } } : nil
                ).frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            CreateFolderCTA(action: viewModel.createFolder)
                .disabled(!viewModel.isNewFolderEnabled)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear { Task { await viewModel.reload() } }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(L10n.Localizable.General.confirm, action: {})
            }
        )
        .sheet(item: $viewModel.sheetNavigation) { navigationItem in
            switch navigationItem {
            case .createFolder:
                viewModel.makeCreateFolderView()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        if viewModel.showCancelButton {
            ToolbarItem(placement: .navigationBarLeading) {
                cancelButton
            }
        }

        if !viewModel.navigationMenuOptions.isEmpty {
            ToolbarTitleMenu {
                toolBarTitleMenuContent()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            moveButton
        }
    }

    func toolBarTitleMenuContent() -> some View {
        ForEach(viewModel.navigationMenuOptions, id: \.self) { option in
            Button(
                option.title,
                systemImage: option.isRoot ? "rectangle.stack" : "folder"
            ) {
                viewModel.navigateTo(option: option)
            }
        }
    }

    var moveButton: some View {
        Button(
            action: { Task { await viewModel.move() } },
            label: {
                if viewModel.moveButtonState == .loading {
                    ProgressView()
                } else {
                    Text(Strings.Files.MoveToFolder.move)
                }
            }
        )
        .disabled(viewModel.moveButtonState == .disabled)
        .accessibilityLabel(Accessibility.Files.MoveToFolder.move)
        .accessibilityIdentifier("moveHere")
    }

    var cancelButton: some View {
        Button(
            action: {
                viewModel.cancel()
            },
            label: {
                Text(L10n.Localizable.General.cancel)
            }
        )
        .accessibilityLabel(L10n.Accessibility.General.cancel)
        .accessibilityIdentifier("cancel")
    }

}

private struct CreateFolderCTA: View {

    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: action) {
                HStack(alignment: .center, spacing: 20) {
                    Image(systemName: "plus")

                    Text(L10n.Localizable.Conversation.WireCells.Files.List.createFolder)
                        .font(for: .body2)
                    Spacer()
                }
            }
            .tint(ColorTheme.Backgrounds.onSurface.color)
            .padding()
        }
        .contentShape(Rectangle())
    }
}

// TODO: [WPB-21903] - Unify with FilesInfoView
package struct MoveToFolderEmptyStateView: View {

    let title: String?
    let message: String
    let onReload: (() -> Void)?

    var body: some View {
        VStack(spacing: 25) {
            if let title {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SemanticColors.Label.textDefault.color)
            }

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(SemanticColors.Label.baseSecondaryText.color)

            if let onReload {
                Button {
                    onReload()
                } label: {
                    Text(Strings.Files.Error.reload)
                        .padding()
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SemanticColors.Label.textDefault.color)
                        .frame(maxHeight: 35)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .stroke(SemanticColors.Button.borderSecondaryEnabled.color, lineWidth: 1)

                        )
                }
                .accessibilityLabel(Strings.Files.Error.reload)
                .accessibilityIdentifier("reloadButton")
            }
        }
        .frame(maxWidth: 420)
        .padding()
    }
}

private struct MoveToFolderItemView: View {

    @ScaledMetric private var imageHeight: CGFloat = 28

    let item: MoveToFolderItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {

                Image(FileIcon.folder.resource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: imageHeight)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(for: .body2)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    Text(item.subtitle ?? "")
                        .font(for: .subline1)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }

                Spacer()
            }
            .padding(.vertical, 8)

            Divider()
        }
        .contentShape(Rectangle()) // Tap area
    }
}

// MARK: - Previews

@MainActor
private func makePreview(
    title: String,
    content: MoveToFolderPageViewModel.ContentState,
    moveButtonState: MoveToFolderPageViewModel.MoveButtonState,
    isNewFolderEnabled: Bool,
    navigationMenuOptions: [NavigationMenuOption],
) -> some View {
    NavigationStack {
        MoveToFolderPage(
            viewModel: MockMoveToFolderPageViewModel(
                title: title,
                content: content,
                moveButtonState: moveButtonState,
                isNewFolderEnabled: isNewFolderEnabled,
                navigationMenuOptions: navigationMenuOptions
            )
        )
    }
}

#Preview("Initial load") {
    WireMessagingUI.makePreview(
        title: "Files",
        content: .initialLoad,
        moveButtonState: .disabled,
        isNewFolderEnabled: false,
        navigationMenuOptions: [],
    )
}

#Preview("Loaded") {
    WireMessagingUI.makePreview(
        title: "Files",
        content: .loaded(
            items: [
                MoveToFolderItem(id: UUID(), name: "Folder 1", subtitle: "Subtitle 1"),
                MoveToFolderItem(id: UUID(), name: "Folder 2", subtitle: "Subtitle 2")
            ],
            hasMore: true,
            isLoading: true
        ),
        moveButtonState: .enabled,
        isNewFolderEnabled: true,
        navigationMenuOptions: [
            NavigationMenuOption(path: "a/b/c", title: "c", isRoot: false),
            NavigationMenuOption(path: "a/b", title: "b", isRoot: false),
            NavigationMenuOption(path: "a", title: "a", isRoot: true)
        ],
    )
}

#Preview("Empty") {
    WireMessagingUI.makePreview(
        title: "Files",
        content: .empty(
            title: "Foo",
            message: "There are no subfolders in this folder.",
            showsReload: true
        ),
        moveButtonState: .loading,
        isNewFolderEnabled: false,
        navigationMenuOptions: [],
    )
}
