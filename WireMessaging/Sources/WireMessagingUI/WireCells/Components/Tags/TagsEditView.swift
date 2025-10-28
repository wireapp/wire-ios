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
            VStack(alignment: .leading) {
                Text(L10n.Localizable.Conversation.WireCells.Tags.headline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text(viewModel.invalidCharactersErrorMessage)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
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
