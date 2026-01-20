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
import WireFoundation
import WireReusableUIComponents

/// A view that allows the user to pick a folder from a list

public struct FolderPicker: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var accentColor

    private let showCloseButton: Bool
    private let options: [FolderPickerOption]
    private let helpLink: URL
    @Binding private var selected: FolderPickerOption?

    /// Creates a new instance of `FolderPicker`
    /// - Parameters:
    ///   - showCloseButton: Whether to show a close button in the navigation bar
    ///   - options: An array of `FolderPickerOption` to display in the picker
    ///   - helpLink: A URL to a help page that explains how to add conversations to a folder
    ///   - selected: The `id` of the selected `FolderPickerOption`

    public init(
        showCloseButton: Bool,
        options: [FolderPickerOption],
        helpLink: URL,
        selected: Binding<FolderPickerOption?>
    ) {
        self.showCloseButton = showCloseButton
        self.options = options
        self.helpLink = helpLink
        _selected = selected
    }

    public var body: some View {
        content()
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text("folderPicker.title", tableName: "Localizable", bundle: .module)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton(
                            action: didTapClose,
                            accessibilityLabel: String(
                                localized: "folderPicker.close.label",
                                table: "Accessibility",
                                bundle: .module
                            )
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
        if options.isEmpty {
            EmptyState(
                image: Image(systemName: "folder"),
                description: Text("folderPicker.emptyState.description", tableName: "Localizable", bundle: .module),
                linkText: Text("folderPicker.emptyState.link.text", tableName: "Localizable", bundle: .module),
                url: helpLink
            )
        } else {
            if #available(iOS 17.0, *) {
                picker()
                    .contentMargins(.top, 16)
            } else {
                picker()
            }
        }
    }

    private func picker() -> some View {
        List {
            Picker(selection: $selected) {
                ForEach(options) { option in
                    Text(option.title)
                        .font(for: .body1)
                        .lineLimit(1)
                        .foregroundStyle(option.id == selected?.id ? Color(accentColor) : .primaryText)
                        .tag(option)
                }
            } label: {
                EmptyView()
            }
            .accentColor(Color(accentColor))
            .pickerStyle(.inline)
        }
    }

}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("With Data") {
    FolderPickerPreview(showCloseButton: true, options: FolderPickerOption.previewData)
}

@available(iOS 17.0, *)
#Preview("Empty State") {
    FolderPickerPreview(showCloseButton: false, options: [])
}

private struct FolderPickerPreview: View {
    @State private var isPresented = true
    @State private var selected: FolderPickerOption?

    let showCloseButton: Bool
    let options: [FolderPickerOption]

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text(verbatim: "Open Folder Picker")
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                FolderPicker(
                    showCloseButton: showCloseButton,
                    options: options,
                    helpLink: URL(string: "https://www.example.com")!,
                    selected: $selected
                )
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
    }
}

private extension FolderPickerOption {
    @MainActor static let previewData = [
        FolderPickerOption(id: .init(), title: "Folder name 1"),
        FolderPickerOption(id: .init(), title: "Folder name 2"),
        FolderPickerOption(id: .init(), title: "Folder name 3"),
        FolderPickerOption(id: .init(), title: "A super long folder name that can't fit on the screen")
    ]
}
