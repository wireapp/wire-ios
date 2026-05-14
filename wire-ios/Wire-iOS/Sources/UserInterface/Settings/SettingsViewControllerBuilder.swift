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

import SwiftUI
import WireMainNavigationUI
import WireSettingsUI
import WireSyncEngine

@MainActor
final class SettingsViewControllerBuilder: MainSettingsUIBuilderProtocol, MainSettingsContentUIBuilderProtocol {

    let userSession: UserSession
    let trackingManager: (any TrackingInterface)?
    let kmpViewModelEnvironment: KMPViewModelEnvironment
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
            isFederationEnabled: userSession.resolvedBackendMetadata.isFederationEnabled,
            userSession: userSession,
            kmpViewModelEnvironment: kmpViewModelEnvironment
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
        trackingManager: (any TrackingInterface)?,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.userSession = userSession
        self.trackingManager = trackingManager
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    func build(mainCoordinator: some MainCoordinatorProtocol) -> SettingsTableViewController {
        if shouldBuildKMPViewModelImplementation(for: .settingsRoot) {
            return buildKMPViewModelRootImplementation(mainCoordinator: mainCoordinator)
        }

        return buildLegacyRoot(mainCoordinator: mainCoordinator)
    }

    private func buildKMPViewModelRootImplementation(
        mainCoordinator: some MainCoordinatorProtocol
    ) -> SettingsTableViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacyRoot(mainCoordinator: mainCoordinator)
    }

    private func buildLegacyRoot(mainCoordinator: some MainCoordinatorProtocol) -> SettingsTableViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.settingsGroup(
            isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: false,
            mainCoordinator: mainCoordinator
        )
        let vc = SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
        vc.footerViewController = makeShareDebugBannerVC(mainCoordinator: mainCoordinator)
        return vc
    }

    private func makeShareDebugBannerVC(mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let presenter = ShareDebugReportPresenter()
        let bannerVC = UIHostingController(rootView: ShareDebugBannerView {
            presenter.present(from: UIApplication.shared.topmostViewController(onlyFullScreen: false))
        })
        bannerVC.view.backgroundColor = .clear
        return bannerVC
    }

    func build(
        topLevelMenuItem: SettingsTopLevelMenuItem,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UIViewController {
        if shouldBuildKMPViewModelImplementation(for: topLevelMenuItem.kmpViewModelScreenID) {
            return buildKMPViewModelTopLevelMenuItemImplementation(
                topLevelMenuItem: topLevelMenuItem,
                mainCoordinator: mainCoordinator
            )
        }

        return buildLegacyTopLevelMenuItem(
            topLevelMenuItem: topLevelMenuItem,
            mainCoordinator: mainCoordinator
        )
    }

    private func shouldBuildKMPViewModelImplementation(for screenID: KMPViewModelScreenID) -> Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: screenID,
            isKMPImplementationAvailable: false
        )
    }

    private func buildKMPViewModelTopLevelMenuItemImplementation(
        topLevelMenuItem: SettingsTopLevelMenuItem,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UIViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacyTopLevelMenuItem(
            topLevelMenuItem: topLevelMenuItem,
            mainCoordinator: mainCoordinator
        )
    }

    private func buildLegacyTopLevelMenuItem(
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
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
    }

    private func buildDevices() -> UIViewController {
        ClientListViewController(
            clientsList: .none,
            selfClient: userSession.selfUserClient,
            userSession: userSession,
            contextProvider: userSession.contextProvider,
            detailedView: true
        )
    }

    private func buildOptions(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.optionsGroup as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
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
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
    }

    private func buildSupport(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.helpSection() as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
    }

    private func buildAbout(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.aboutSection() as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
    }

    private func buildDeveloperOptions(_ mainCoordinator: some MainCoordinatorProtocol) -> UIViewController {
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let factory =
            settingsCellDescriptorFactory(settingsCoordinator: .init(settingsCoordinator: settingsCoordinator))
        let group = factory.developerGroup as! SettingsGroupCellDescriptor
        return SettingsTableViewController(
            group: group,
            settingsCoordinator: .init(settingsCoordinator: settingsCoordinator),
            userSession: userSession
        )
    }
}

extension SettingsTopLevelMenuItem {

    var kmpViewModelScreenID: KMPViewModelScreenID {
        switch self {
        case .account:
            .settingsAccount
        case .devices:
            .settingsDevices
        case .options:
            .settingsOptions
        case .advanced:
            .settingsAdvanced
        case .support:
            .settingsSupport
        case .about:
            .settingsAbout
        case .developerOptions:
            .settingsDeveloper
        }
    }
}
