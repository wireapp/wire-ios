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
import protocol WireDataModel.EditableUserType
import protocol WireSyncEngine.UserSession
import enum WireUtilities.AccentColor

final class AccentColorPickerController: UIHostingController<ColorPickerView> {

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(selfUser: EditableUserType, userSession: UserSession) {
        let accentColor = AccentColor(rawValue: selfUser.accentColorValue) ?? .default

        let colorPickerView = ColorPickerView(
            selectedColor: accentColor,
            colors: AccentColor.allCases,
            onColorSelect: { accentColor in
                userSession.perform {
                    selfUser.accentColorValue = accentColor.rawValue
                }
            }
        )

        super.init(rootView: colorPickerView)
    }
}
