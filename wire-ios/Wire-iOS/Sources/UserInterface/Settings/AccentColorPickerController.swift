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
import WireFoundation
import WireSyncEngine
import WireUtilities

final class AccentColorPickerController: UIHostingController<AccentColorPicker> {

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(selfUser: EditableUserType, userSession: UserSession) {
        let accentColor = AccentColor(rawValue: selfUser.accentColorValue) ?? .default
        // Currently, using a `UIHostingController` to host SwiftUI views within a UIKit application makes it difficult to directly work with SwiftUI bindings.
        // The `UIHostingController` acts as a bridge between UIKit and SwiftUI, and managing SwiftUI bindings across this bridge can be complex and error-prone.
        // We plan to migrate our settings interface to SwiftUI in the future. Once the transition is complete, we can leverage SwiftUI's binding system more effectively.
        // This will simplify state management and improve code clarity. At that point, we can replace the closure with a binding to directly manage the selected color state.
        let colorPickerView = AccentColorPicker(
            selectedColor: accentColor,
            onColorSelect: { accentColor in
                userSession.perform {
                    selfUser.accentColorValue = accentColor.rawValue
                }
            }
        )

        super.init(rootView: colorPickerView)
    }
}
