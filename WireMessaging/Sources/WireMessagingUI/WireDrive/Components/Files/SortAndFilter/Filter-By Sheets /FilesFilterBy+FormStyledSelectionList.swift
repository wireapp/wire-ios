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

extension FilesFilterBy {
    struct FormStyledSelectionList<Item: Hashable, ItemView: View>: View {
        let items: [Item]
        let onSelected: (Item) -> Void
        let itemView: (Item) -> ItemView
        
        var body: some View {
            Form {
                ForEach(items, id: \.self) { item in
                    Button {
                        onSelected(item)
                    } label: {
                        itemView(item)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    VStack {
        FilesFilterBy.FormStyledSelectionList(
            items: ["one", "two", "three"],
            onSelected: { _ in },
            itemView: { item in
                Text(item)
            }
        )
    }
    .background(Color.gray)
}
