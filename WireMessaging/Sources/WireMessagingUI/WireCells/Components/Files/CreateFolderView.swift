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
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct CreateFolderView: View, Identifiable {
    @StateObject package var viewModel: CreateFolderViewModel
    @Environment(\.dismiss) var dismiss

    var id = UUID()

    init(viewModel: @autoclosure @escaping () -> CreateFolderViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.Backgrounds.background.color
                    .ignoresSafeArea(.all)

                VStack {
                    ValidationTextField(
                        title: Strings.Files.NewFolder.title,
                        placeholder: Strings.Files.NewFolder.placeholder,
                        textInput: $viewModel.folderNameInput,
                        errorMessage: $viewModel.errorMessage,
                        isFocused: $viewModel.isFocused
                    )
                    .padding()
                    .submitLabel(.send)
                    .onSubmit {
                        if !isCreateDisabled() {
                            create()
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle(Strings.Files.NewFolder.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .toolbar { toolbarContent }
            .interactiveDismissDisabled(viewModel.isLoading)
        }
    }

    private func create() {
        Task {
            if await viewModel.create() {
                dismiss()
            }
        }
    }

    private func isCreateDisabled() -> Bool {
        viewModel.errorMessage != nil || viewModel.folderNameInput.isEmpty
    }

}

// MARK: - Toolbar

private extension CreateFolderView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { cancelButton }
        ToolbarItem(placement: .topBarTrailing) { createButton }
    }

    var cancelButton: some View {
        Button(
            action: {
                dismiss()
            },
            label: {
                Text(L10n.Localizable.General.cancel)
            }
        )
        .accessibilityIdentifier("cancelButton")
    }

    @ViewBuilder var createButton: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            Button(
                action: {
                    create()
                },
                label: {
                    Text(L10n.Localizable.General.create)
                }
            )
            .disabled(isCreateDisabled())
            .accessibilityIdentifier("createButton")
        }
    }
}

#Preview {
    CreateFolderView(viewModel: .preview())
}
