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
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FileRenameView: View {
    @StateObject package var viewModel: FileRenameViewModel
    @Environment(\.dismiss) var dismiss

    let id = UUID()

    init(viewModel: @autoclosure @escaping () -> FileRenameViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.Backgrounds.background.color
                    .ignoresSafeArea(.all)

                VStack {
                    ValidationTextField(
                        title: viewModel.title,
                        placeholder: viewModel.placeholder,
                        textInput: $viewModel.filenameInput,
                        errorMessage: $viewModel.errorMessage,
                        isFocused: $viewModel.isFocused
                    )
                    .padding()
                    .submitLabel(.send)
                    .onSubmit {
                        if !viewModel.isSaveDisabled {
                            save()
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .toolbar { toolbarContent }
            .interactiveDismissDisabled(viewModel.isLoading)
        }
    }

    private func save() {
        Task {
            if await viewModel.save() {
                dismiss()
            }
        }
    }

}

// MARK: - Toolbar

private extension FileRenameView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { cancelButton }
        ToolbarItem(placement: .topBarTrailing) { saveButton }
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
        .accessibilityLabel(L10n.Accessibility.General.cancel)
        .accessibilityIdentifier("cancel")
    }

    var saveButton: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button(
                    action: {
                        save()
                    },
                    label: {
                        Text(L10n.Localizable.General.save)
                    }
                )
                .disabled(viewModel.isSaveDisabled)
                .accessibilityLabel(L10n.Accessibility.General.save)
                .accessibilityIdentifier("save")
            }
        }
    }
}

#Preview {
    FileRenameView(viewModel: .preview(kind: .file))
}
