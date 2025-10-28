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

struct TagsEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ViewModel
    
    init(fileItem: FilesViewItem) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem))
    }
    
    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(Text(L10n.Localizable.Conversation.WireCells.Tags.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text(L10n.Localizable.General.close)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.save()
                        } label: {
                            Text(L10n.Localizable.General.save)
                                .bold()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                normalText(L10n.Localizable.Conversation.WireCells.Tags.headline)
                
                tagNameInputArea()
                
                Spacer(minLength: 6)
                
                addedTagsArea()
                
                Spacer(minLength: 28)

                suggestedTagsArea()
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    @ViewBuilder private func tagNameInputArea() -> some View {
        VStack {
            HStack {
                Text("(TODO)")
            }
            
            validationText(viewModel.invalidCharactersErrorMessage)
        }
    }
    
    @ViewBuilder private func addedTagsArea() -> some View {
        VStack(spacing: 16) {
            sectionText(L10n.Localizable.Conversation.WireCells.Tags.addedTagsSection)
            
            normalText(L10n.Localizable.Conversation.WireCells.Tags.addedTagsSectionEmpty)
        }
    }
    
    @ViewBuilder private func suggestedTagsArea() -> some View {
        VStack(spacing: 16) {
            sectionText(L10n.Localizable.Conversation.WireCells.Tags.suggestedTagsSection)
            
            normalText(L10n.Localizable.Conversation.WireCells.Tags.suggestedTagsSectionEmpty)
        }
    }
    
    @ViewBuilder private func normalText(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder private func sectionText(_ text: String) -> some View {
        Text(text)
            .textCase(.uppercase)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder private func validationText(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.red) //TODO: use darker red
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        filename: "Hello World",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document
    )
    
    TagsEditView(fileItem: item)
}
