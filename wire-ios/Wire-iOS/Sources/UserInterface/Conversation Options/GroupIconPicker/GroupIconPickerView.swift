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
import WireDataModel

struct GroupIconPickerView: View {

    private static let cellSize: CGFloat = 60

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60))
    ]

    @StateObject var viewModel: GroupIconPickerViewModel

    init(conversation: ZMConversation, syncContext: NSManagedObjectContext) {
        print("🕵🏽 conversation")
        _viewModel = StateObject(wrappedValue: .init(conversation: conversation, syncContext: syncContext))
    }

    var body: some View {
        Self._printChanges()
        return
        VStack(alignment: .leading) {
            Text("Select a color for the group avatar:")

            grid
        }
        .padding()
        .background(.background)
    }

    @ViewBuilder
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.selectItem(item)
                } label: {
                    let cornerRadius: CGFloat = 12

                    ZStack {
                        Rectangle()
                            .foregroundColor(item.color)
                            .frame(
                                width: Self.cellSize,
                                height: Self.cellSize
                            )
                            .cornerRadius(cornerRadius)

                        if viewModel.selectedItem == item {
                            Image(systemName: "checkmark.circle.fill")
                                .tint(.white)
                        }
                    }
                }
            }
        }
    }
}
