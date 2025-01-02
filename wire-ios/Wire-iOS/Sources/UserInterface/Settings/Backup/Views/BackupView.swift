//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public struct BackupView: View {
    @ObservedObject private var viewModel: BackupViewModel
    @State private var isSheetPresented: Bool = false
    @State private var selectedOption: String = ""
//    private lazy var activityIndicator = BlockingActivityIndicator(view: self)

    public init(
        viewModel: BackupViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(
                    footer: Text(section.type.footer)
                ) {
                    Button(action: {
                        print("Action for Section 1 triggered!")
                        withAnimation {
                            isSheetPresented = true
                        }
                    }) {
                        //Button(action: section.action) {
                        HStack {
                            Text(section.type.title)
                                .font(.textStyle(.body2))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            Image(.chevronRight).foregroundStyle(Color.primary)
                        }
                    }
//                    BackupPasswordPickerView(
//                        isPresented: $isSheetPresented,
//                        onCancel: {
//                            print("Picker canceled")
//                        },
//                        onConfirm: { password in
//                            print("Password entered: \(password)")
//                        }
//                    )
                    .sheet(isPresented: $isSheetPresented) {
//                        FolderPicker11(showCloseButton: true,
//                                      helpLink: WireURLs.shared.howToAddConversationToCustomFolder)
//                        BackupPasswordView()
                        NavigationStack {
                            PickerTestView(
                                title: "Choose an Option",
                                options: ["Option 1", "Option 2", "Option 3"],
                                selectedOption: $selectedOption,
                                onDone: {
                                    print("Selected Option: \(selectedOption)")
                                    isSheetPresented = false
                                }
                            )
                        }
                    }
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
                }
            }
        }
        .listStyle(.grouped)
        .listRowBackground(Color(ColorTheme.Backgrounds.background))
    }
}

#Preview {
    BackupView(viewModel: BackupViewModel())
}

struct PickerTestView: View {
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    let onDone: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $selectedOption, label: Text(title)) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .padding()

                Button(action: onDone) {
                    Text("Done")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct BackupPasswordPickerView: View {
    @Binding var isPresented: Bool
    @State private var password: String = ""

    var onCancel: () -> Void
    var onConfirm: (String) -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismiss()
                    }
            }

            // Bottom sheet content
            if isPresented {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Button("Cancel") {
                            dismiss()
                            onCancel()
                        }
                        Spacer()
                        Text("Set password")
                            .font(.headline)
                        Spacer()
                        Button(" ") {} // Placeholder to balance layout
                            .hidden()
                    }
                    .padding(.horizontal)

                    // Description
                    Text("The backup will be compressed and encrypted with a password. Make sure to store it in a secure place.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password (OPTIONAL)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            SecureField("Enter password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                // Add "show/hide password" logic here
                            }) {
                                Image(systemName: "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        Text("Use at least 8 characters, with one lowercase letter, one capital letter, a number, and a special character.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Backup Button
                    Button(action: {
                        dismiss()
                        onConfirm(password)
                    }) {
                        Text("Back Up Now")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isPresented)
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
    }
}



struct FolderPicker11: View {

    @Environment(\.dismiss) private var dismiss

    private let showCloseButton: Bool
    private let helpLink: URL

    /// Creates a new instance of `FolderPicker`
    /// - Parameters:
    ///   - showCloseButton: Whether to show a close button in the navigation bar
    ///   - options: An array of `FolderPickerOption` to display in the picker
    ///   - helpLink: A URL to a help page that explains how to add conversations to a folder
    ///   - selected: The `id` of the selected `FolderPickerOption`

    public init(
        showCloseButton: Bool,
        helpLink: URL
    ) {
        self.showCloseButton = showCloseButton
        self.helpLink = helpLink
    }

    public var body: some View {
        content()
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text("Folders")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton(
                            action: didTapClose, accessibilityLabel: "CloseButton"
                        )
                    }
                }
            }
    }

    private func didTapClose() {
        dismiss()
    }

    @ViewBuilder
    private func content() -> some View {
        EmptyState1(
            image: Image(systemName: "folder"),
            description: Text("EmptyState"),
            linkText: Text("Link"),
            url: helpLink
        )

    }

}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("With Data") {
    FolderPickerPreview(showCloseButton: true)
}

private struct FolderPickerPreview: View {
    @State private var isPresented = true

    let showCloseButton: Bool

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text(verbatim: "Open Folder Picker")
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                FolderPicker11(
                    showCloseButton: showCloseButton,
                    helpLink: URL(string: "https://www.example.com")!
                )
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
    }
}

struct EmptyState1: View {
    let image: Image
    let description: Text
    let linkText: Text
    let url: URL

    var body: some View {
        Group {
            VStack {
                image
                    .font(.system(size: 40))
                    .foregroundStyle(Color.secondaryText)
                    .padding(.bottom, 16)

                description
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)

                Link(destination: url) {
                    linkText
                        .multilineTextAlignment(.center)
                        .underline()
                }
            }
            .font(.textStyle(.body1))
            .foregroundStyle(Color.primaryText)
            .frame(maxWidth: 272)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyState1(
        image: Image(systemName: "folder"),
        description: Text(verbatim: "Add your conversations to folders to stay organized."),
        linkText: Text(verbatim: "How to add a conversation to a folder"),
        url: URL(string: "http://example.com")!
    )
}
