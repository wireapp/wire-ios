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

public import SwiftUI

private typealias Strings = L10n.Localizable.Conversation.WireCells

// TODO: [WPB-21030] view + view model to implement, potentially reuse FilesView and FilesViewModel.
public struct AllFilesView: View {
    @State private var searchText = ""

    public init() {}

    public var body: some View {
        Text("")
            .navigationTitle(Strings.AllFiles.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer)
    }
}

#Preview {
    AllFilesView()
}
