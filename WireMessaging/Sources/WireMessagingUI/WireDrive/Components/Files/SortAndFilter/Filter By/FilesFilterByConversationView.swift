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

private typealias Strings = L10n.Localizable.Conversation.WireCells

struct FilesFilterByConversationView: View {
    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: ViewModel
    
    let onApply: (Set<ViewModel.Item>) -> Void

    init(
        selectedItems: some Collection<ViewModel.Item>,
        onApply: @escaping (Set<ViewModel.Item>) -> Void
    ) {
        self.onApply = onApply
        self._viewModel = .init(
            wrappedValue: .init(
                selectedItems: selectedItems
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            content()
                .background {
                    ColorTheme.Backgrounds.background.color
                        .ignoresSafeArea(.all)
                }
                .toolbar { toolbarContent }
                .navigationTitle(Strings.Filter.FileType.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        VStack {
            Form {
                ForEach(viewModel.presentedItems, id: \.self) { item in
                    Button {
                        viewModel.toggleItemSelection(item)
                    } label: {
                        itemView(item)
                    }
                }
            }
            .scrollContentBackground(.hidden)

            removeFilterButton
                .padding(10)
        }
    }
    
    @ViewBuilder
    private func itemView(_ item: ViewModel.Item) -> some View {
        Label {
            HStack {
                Text(item)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                Spacer()

                if viewModel.isItemSelected(item) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(wireAccentColor)
                }
            }
        } icon: {
            Image(systemName: "questionmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

// MARK: - Toolbar

private extension FilesFilterByConversationView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { closeButton }
        ToolbarItem(placement: .topBarTrailing) { saveButton }
    }
}

// MARK: - Buttons

private extension FilesFilterByConversationView {
    var saveButton: some View {
        Button {
            Task {
                onApply(viewModel.selectedItems)
                dismiss()
            }
        } label: {
            Text(L10n.Localizable.General.save)
                .fontWeight(.semibold)
                .accessibilityIdentifier("saveButton")
        }
        .disabled(!viewModel.hasChanges)
    }

    var removeFilterButton: some View {
        Button {
            Task { viewModel.clearAll() }
        } label: {
            Text(Strings.Filter.removeFilter)
        }
        .accessibilityIdentifier("removeFilterButton")
        .disabled(viewModel.selectedItems.isEmpty)
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Text(L10n.Localizable.General.cancel)
            }
        )
        .accessibilityIdentifier("cancelButton")
    }
}

#Preview {
    FilesFilterByConversationView(
        selectedItems: [],
        onApply: { _ in }
    )
}
