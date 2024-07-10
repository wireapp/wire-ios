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

final class GroupIconPickerViewModel: ObservableObject {
    let items: [GroupIconPickerDisplayModel.Item] = [
        GroupIconPickerDisplayModel.Item(color: .red),
        GroupIconPickerDisplayModel.Item(color: .blue),
        GroupIconPickerDisplayModel.Item(color: .green),
        GroupIconPickerDisplayModel.Item(color: .orange),
        GroupIconPickerDisplayModel.Item(color: .gray),
        GroupIconPickerDisplayModel.Item(color: .brown),
        GroupIconPickerDisplayModel.Item(color: .indigo),
        GroupIconPickerDisplayModel.Item(color: .yellow)
    ]

    @Published var selectedItem: GroupIconPickerDisplayModel.Item?

    func selectItem(_ item: GroupIconPickerDisplayModel.Item) {
        if selectedItem == item {
            // unselect
            selectedItem = nil
            print("unselect item")
        } else {
            // select
            selectedItem = item
            print("select item with color: \(item.color)")
        }
    }
}
