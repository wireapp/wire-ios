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
import WireDesign

final class GroupIconPickerViewModel: ObservableObject {
    let items: [GroupIconPickerDisplayModel.Item] = [
        // blue
        .init(uiColor: BaseColorPalette.LightUI.MainColorShade.blue300),
        .init(uiColor: BaseColorPalette.LightUI.MainColor.blue500),
        .init(uiColor: BaseColorPalette.LightUI.MainColorShade.blue700),

        // green
        .init(uiColor: BaseColorPalette.LightUI.MainColorShade.green300),
        .init(uiColor: BaseColorPalette.LightUI.MainColor.green500),
        .init(uiColor: BaseColorPalette.LightUI.MainColorShade.green700),

        .init(uiColor: BaseColorPalette.LightUI.MainColor.petrol500),
        .init(uiColor: BaseColorPalette.LightUI.MainColor.purple500),
        .init(uiColor: BaseColorPalette.LightUI.MainColor.red500),
        .init(uiColor: BaseColorPalette.LightUI.MainColor.amber500),

        .init(uiColor: BaseColorPalette.Grays.gray70)

        // TODO: add more colors
    ]

    @Published var selectedItem: GroupIconPickerDisplayModel.Item?
    let conversation: ZMConversation
    private let updateGroupIconUseCase: UpdateGroupIconUseCase

    init(conversation: ZMConversation, syncContext: NSManagedObjectContext) {
        self.conversation = conversation
        self.updateGroupIconUseCase = UpdateGroupIconUseCase(conversationId: conversation.qualifiedID!, context: syncContext)
        selectedItem = conversation.groupColor.flatMap { GroupIconPickerDisplayModel.Item(hexColor: $0) }
        print(selectedItem)
    }

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

        updateGroupIcon(item)
    }

    private func updateGroupIcon(_ item: GroupIconPickerDisplayModel.Item) {
        Task {
            await updateGroupIconUseCase.invoke(colorString: selectedItem?.color.toHexString(), emoji: nil)
        }
    }
}

extension Color {
    func toHexString() -> String? {
        // Convert SwiftUI Color to UIColor to extract RGB components
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Extract RGBA components
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        // Convert components to hex string
        let redInt = Int(red * 255)
        let greenInt = Int(green * 255)
        let blueInt = Int(blue * 255)
        let alphaInt = Int(alpha * 255)

        // Format the string with or without alpha channel
        if alphaInt == 255 {
            return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
        } else {
            return String(format: "#%02X%02X%02X%02X", redInt, greenInt, blueInt, alphaInt)
        }
    }
}
