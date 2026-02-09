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

private typealias Strings = L10n.Localizable.Conversation.WireCells

struct FilesFilterByTypeView: View {
    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.dismiss) private var dismiss
    
    @StateObject package var viewModel: ViewModel = .init()
    
    var body: some View {
        Text("Hello, World!")
    }
}

// MARK: - Toolbar

private extension FilesFilterByTypeView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { closeButton }
        ToolbarItem(placement: .topBarTrailing) { saveButton }
    }
}

// MARK: - Buttons

private extension FilesFilterByTypeView {
    var saveButton: some View {
        Button {
            Task {
                //onApply(viewModel.selectedTags)
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
        //.disabled(viewModel.selectedTags.isEmpty)
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
    FilesFilterByTypeView()
}
