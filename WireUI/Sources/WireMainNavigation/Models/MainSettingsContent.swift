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

public enum MainSettingsContent {
    case account, todo
}

public protocol MainSettingsContentRepresentable: Sendable {

    init(_ mainSettingsContent: MainSettingsContent)
    init?<SettingsContent: MainSettingsContentRepresentable>(mappingFrom settingsContent: SettingsContent?)

    func mapToMainSettingsContent() -> MainSettingsContent
}

public extension MainSettingsContentRepresentable {

    init?(mappingFrom settingsContent: (some MainSettingsContentRepresentable)?) {
        guard let settingsContent else { return nil }
        self.init(settingsContent.mapToMainSettingsContent())
    }
}
