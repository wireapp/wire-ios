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

struct ShareLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor

    @StateObject private var viewModel: ViewModel
    
    init(fileItem: FilesViewItem) {
        _viewModel = .init(wrappedValue: .init(fileItem: fileItem))
    }
    
    var body: some View {
        NavigationStack {
            content()
                .sheet(item: $viewModel.sheetNavigation) { navigationItem in
                    switch navigationItem {
                    case .password:
                        Text("TODO: Password view")
                    case .expiration:
                        Text("TODO: Expiration view")
                    }
                }
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack {
                Button {
                    viewModel.sheetNavigation = .password
                } label: {
                    Text("Password (dummy)")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.sheetNavigation = .expiration
                } label: {
                    Text("Expiration (dummy)")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        kind: .file,
        name: "some_file.pdf",
        filePath: "some/path",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: []
    )
    
    ShareLinkView(fileItem: item)
}
