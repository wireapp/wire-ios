import SwiftUI
import WireDesign
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct CreateFolderView: View {
    @StateObject package var viewModel: CreateFolderViewModel
    @Environment(\.dismiss) var dismiss

    let id = UUID()

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
                        if !viewModel.isCreateDisabled {
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
            .disabled(viewModel.isCreateDisabled)
            .accessibilityIdentifier("createButton")
        }
    }
}

#Preview {
    CreateFolderView(viewModel: .preview())
}