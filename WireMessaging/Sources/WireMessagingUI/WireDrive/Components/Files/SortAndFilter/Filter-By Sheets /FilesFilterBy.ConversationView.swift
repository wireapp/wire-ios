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

extension FilesFilterBy {
    struct ConversationView: View {
        @Environment(\.wireAccentColor) private var wireAccentColor
        @Environment(\.dismiss) private var dismiss
        
        @StateObject private var viewModel: ViewModel
        
        let onApply: (Set<ViewModel.Item>) -> Void
        
        init(
            availableItems: some Collection<ViewModel.Item>,
            selectedItems: some Collection<ViewModel.Item>,
            onApply: @escaping (Set<ViewModel.Item>) -> Void
        ) {
            self.onApply = onApply
            self._viewModel = .init(
                wrappedValue: .init(
                    availableItems: availableItems,
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
                    .navigationTitle(Strings.Filter.Conversation.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        
        @ViewBuilder
        private func content() -> some View {
            VStack {
                FormStyledSelectionList(
                    items: viewModel.presentedItems,
                    onSelected: viewModel.toggleItemSelection,
                    itemView: itemView
                )
                
                Buttons.RemoveFilter {
                    viewModel.clearAll()
                }
                .padding(10)
                .disabled(viewModel.selectedItems.isEmpty)
            }
        }
        
        @ViewBuilder
        private func itemView(_ item: ViewModel.Item) -> some View {
            Label {
                HStack {
                    Text(item.name)
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
}

// MARK: - Toolbar

private extension FilesFilterBy.ConversationView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            FilesFilterBy.Buttons.Cancel {
                dismiss()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            FilesFilterBy.Buttons.Save {
                onApply(viewModel.selectedItems)
                dismiss()
            }
            .disabled(!viewModel.hasChanges)
        }
    }
}

// MARK: - Preview

#Preview {
    FilesFilterBy.ConversationView(
        availableItems: [],
        selectedItems: [],
        onApply: { _ in }
    )
}
