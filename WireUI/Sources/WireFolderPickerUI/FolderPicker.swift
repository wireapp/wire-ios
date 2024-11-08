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
import WireFoundation
import WireReusableUIComponents

/// A view that allows the user to pick a folder from a list

public struct FolderPicker: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var accentColor

    private let showCloseButton: Bool
    private let options: [FolderPickerOption]
    @Binding private var selected: UUID?

    /// Creates a new instance of `FolderPicker`
    /// - Parameters:
    ///   - showCloseButton: Whether to show a close button in the navigation bar
    ///   - options: An array of `FolderPickerOption` to display in the picker
    ///   - selected: The `id` of the selected `FolderPickerOption`

    public init(
        showCloseButton: Bool,
        options: [FolderPickerOption],
        selected: Binding<UUID?>
    ) {
        self.showCloseButton = showCloseButton
        self.options = options
        _selected = selected
    }

    public var body: some View {
        List {
            Picker(selection: $selected) {
                ForEach(options) { option in
                    Text(option.title)
                        .font(.textStyle(.body1))
                        .lineLimit(1)
                        .foregroundStyle(option.id == selected ? Color(accentColor) : .primaryText)
                        .tag(option.id)
                }
            } label: {
                Text(verbatim: "")
            }
            .accentColor(Color(accentColor))
            .pickerStyle(.inline)
        }
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

}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isPresented = false
    @Previewable @State var selected: UUID? = FolderPickerOption.previewData.first?.id

    Button {
        isPresented.toggle()
    } label: {
        Text(verbatim: "Show Picker")
    }
    .sheet(isPresented: $isPresented) {
        NavigationStack {
            FolderPicker(
                showCloseButton: true,
                options: FolderPickerOption.previewData,
                selected: $selected
            )
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
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
