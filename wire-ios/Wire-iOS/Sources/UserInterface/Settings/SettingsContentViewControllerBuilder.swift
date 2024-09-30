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

import WireMainNavigation
import WireSyncEngine
import WireSettings

struct SettingsViewControllerBuilder: MainCoordinatorInjectingViewControllerBuilder, MainSettingsContentBuilderProtocol {

    // TODO: can selfUser be taken from the userSession?
    var userSession: UserSession
    var selfUser: SettingsSelfUser

    private var settingsPropertyFactory: SettingsPropertyFactory {
        .init(
            userSession: userSession,
            selfUser: selfUser
        )
    }

    private var settingsCellDescriptorFactory: SettingsCellDescriptorFactory {
        .init(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: UserRight.self
        )
    }

    @MainActor
    func build(mainCoordinator _: some MainCoordinatorProtocol) -> SettingsMainViewController {
        let group = settingsCellDescriptorFactory.settingsGroup(
            isTeamMember: userSession.selfUser.isTeamMember,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: false
        )
        return .init(group: group)
    }

    @MainActor
    func build(content: SettingsTopLevelContent) -> SettingsContentViewController {
        switch content {
        case .account:
            fatalError("TODO")
        case .devices:
            fatalError("TODO")
        case .options:
            fatalError("TODO")
        case .advanced:
            fatalError("TODO")
        case .support:
            fatalError("TODO")
        case .about:
            fatalError("TODO")
        case .developerOptions:
            fatalError("TODO")
        }
    }
}
