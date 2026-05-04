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

import Foundation
import WireSyncEngine

final class ColorSchemeController: NSObject {

    var userObserverToken: Any?

    init(userSession: UserSession) {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsColorSchemeDidChange),
            name: .SettingsColorSchemeChanged,
            object: nil
        )

    }

    @objc
    private func settingsColorSchemeDidChange() {
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = Settings.shared.colorScheme.userInterfaceStyle
        }

        ColorScheme.default.variant = Settings.shared.colorSchemeVariant

        NSAttributedString.invalidateMarkdownStyle()
    }
}
