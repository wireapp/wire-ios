//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireMainNavigationUI
import WireSettingsUI
import WireSyncEngine

@MainActor
final class SettingsViewControllerBuilder: MainSettingsUIBuilderProtocol, MainSettingsContentUIBuilderProtocol {

    let userSession: UserSession
    let trackingManager: (any TrackingInterface)?
    weak var settingsPropertyFactoryDelegate: SettingsPropertyFactoryDelegate?

    private var settingsPropertyFactory: SettingsPropertyFactory {
        let settingsPropertyFactory = SettingsPropertyFactory(
            userSession: userSession,
            selfUser: userSession.editableSelfUser,
            trackingManager: trackingManager
        )
        settingsPropertyFactory.delegate = settingsPropertyFactoryDelegate
        return settingsPropertyFactory
    }

    private func settingsCellDescriptorFactory(settingsCoordinator: AnySettingsCoordinator)
        -> SettingsCellDescriptorFactory {
        .init(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: UserRight.self,
            settingsCoordinator: settingsCoordinator,
            localDomain: userSession.resolvedBackendMetadata.domain,
            isFederationEnabled: userSession.resolvedBackendMetadata.isFederationEnabled
        )
    }

    private var isAnalyticsTrackingAvailable: Bool {
        guard let domain = userSession.selfUser.domain,
              let isAnalyticsTrackingAvailable = trackingManager?.isAnalyticsTrackingAvailable(for: domain)
        else { return false }
        return isAnalyticsTrackingAvailable
    }

    init(
        userSession: UserSession,
        trackingManager: (any TrackingInterface)?
    ) {
        self.userSession = userSession
        self.trackingManager = trackingManager
    }

    func build(mainCoordinator: some MainCoordinatorProtocol) -> SettingsTableViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.settingsGroup(
            isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: false,
            mainCoordinator: mainCoordinator
        )
        return .init(group: group, settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
    }

    func build(
        topLevelMenuItem: SettingsTopLevelMenuItem,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UIViewController {
        let viewController = switch topLevelMenuItem {
        case .account:
            buildAccount(mainCoordinator)
        case .devices:
            buildDevices()
        case .options:
            buildOptions(mainCoordinator)
        case .advanced:
            buildAdvanced(mainCoordinator)
        case .support:
            buildSupport(mainCoordinator)
        case .about:
            buildAbout(mainCoordinator)
        case .developerOptions:
            buildDeveloperOptions(mainCoordinator)
        }
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }

    private func buildAccount(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.accountGroup(
            isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: false
        ) as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }

    private func buildDevices() -> UIViewController {
        ClientListViewController(clientsList: .none, credentials: .none, detailedView: true)
    }

    private func buildOptions(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.optionsGroup as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }

    private func buildAdvanced(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.advancedGroup(
            userSession: userSession,
            mainCoordinator: mainCoordinator
        ) as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }

    private func buildSupport(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.helpSection() as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }

    private func buildAbout(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.aboutSection() as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }

    private func buildDeveloperOptions(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.developerGroup as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator)
        )
    }
}
