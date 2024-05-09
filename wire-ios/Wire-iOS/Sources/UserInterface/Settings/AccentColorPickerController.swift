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
import UIKit
import WireCommonComponents
import WireDataModel
import WireSyncEngine

class AccentColorPickerHostingController: UIHostingController<ColorPickerView> {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(selectedAccentColor: Binding<AccentColor?>) {
        let allAccentColors = AccentColor.allSelectable()
        var initialSelectedColor: AccentColor?

        if let bindingValue = selectedAccentColor.wrappedValue {
            // If the binding has an initial value, use it
            initialSelectedColor = bindingValue
        } else if let firstColor = allAccentColors.first {
            // If no initial value, use the first available color as a default
            initialSelectedColor = firstColor
        }
        
        super.init(rootView: ColorPickerView(selectedColor: initialSelectedColor, colors: allAccentColors, onColorSelect: { selectedColor in
            selectedAccentColor.wrappedValue = selectedColor
            if let colorIndex = allAccentColors.firstIndex(of: selectedColor) {
                ZMUserSession.shared()?.perform {
                    ZMUser.selfUser()?.accentColorValue = allAccentColors[colorIndex].zmAccentColor
                }
            }
        }))

    }
}
