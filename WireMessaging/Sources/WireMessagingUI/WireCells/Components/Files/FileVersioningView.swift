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

import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FileVersioningView: View, Identifiable {
    @StateObject package var viewModel: FileVersioningViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreVersionAlert = false

    let id = UUID()

    init(viewModel: @autoclosure @escaping () -> FileVersioningViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            Form { sections }
                .scrollContentBackground(.hidden)
                .background(ColorTheme.Backgrounds.background.color)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Strings.FilesVersioning.navigationTitle)
                .toolbar { toolbarContent }
                .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
                .task { await viewModel.fetch() }
                .refreshable { await viewModel.fetch(isRefreshing: true) }
                .overlay { if viewModel.isLoading { ProgressView() } }
        }
        .alert(
            Strings.FilesVersioning.restoreAlertTitle,
            isPresented: $showRestoreVersionAlert
        ) {
            Button(Strings.FilesVersioning.restoreAlertAction, role: .cancel) {
                Task { await viewModel.restore() }
            }
            Button(L10n.Localizable.General.cancel) {}
        } message: {
            Text(Strings.FilesVersioning.restoreAlertMessage)
        }

    }
}

// MARK: - Toolbar

private extension FileVersioningView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { closeButton }
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
        .accessibilityIdentifier("closeButton")
    }
}

// MARK: - Sections & Rows

extension FileVersioningView {
    typealias VersionItem = FileVersioningViewModel.VersionModel.VersionItem

    var sections: some View {
        ForEach(viewModel.versions) { version in
            Section(version.header) {
                ForEach(version.items, content: row(for:))
            }
        }
    }

    func row(for item: VersionItem) -> some View {
        HStack {
            Image(systemName: "arrow.trianglehead.counterclockwise")

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                Text(item.subtitle)
                    .font(for: .h4)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)

            }.padding(.leading, 5)

            Spacer()

            Menu {
                rowMenuActions
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(ColorTheme.Base.primary(viewModel.accentColor).color)
            }
        }
    }

    @ViewBuilder var rowMenuActions: some View {
        Button(
            action: {
                showRestoreVersionAlert = true
            }, label: {
                HStack {
                    Text(Strings.FilesVersioning.restoreAlertTitle)

                    Image(systemName: "arrow.uturn.left")
                        .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                }

            }
        )

        Button(
            action: {
                Task { await viewModel.download() }
            }, label: {
                HStack {
                    Text(Strings.FilesVersioning.downloadVersion)

                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                }

            }
        )
    }

}

#Preview {
    FileVersioningView(viewModel: .preview())
}
