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

import UIKit
import WireDataModel
import WireMainNavigation
import WireSyncEngine

extension SelfProfileViewController {

    func presentNewLoginAlertControllerIfNeeded() -> Bool {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return false
        }
        let clientsRequiringUserAttention = Array(selfUser.clientsRequiringUserAttention)

        if clientsRequiringUserAttention.count > 0 {
            self.presentNewLoginAlertController(clientsRequiringUserAttention)
            return true
        } else {
            return false
        }
    }

    fileprivate func presentNewLoginAlertController(_ clients: [UserClientType]) {
        let newLoginAlertController = UIAlertController(forNewSelfClients: clients)

        let actionManageDevices = UIAlertAction(title: L10n.Localizable.Self.NewDeviceAlert.manageDevices, style: .default) { _ in
            // self.openControllerForCellWithIdentifier(SettingsCellDescriptorFactory.settingsDevicesCellIdentifier)
            fatalError("TODO: mainCoordinator.showSettings(content: .devices)")
        }

        newLoginAlertController.addAction(actionManageDevices)

        let actionTrustDevices = UIAlertAction(title: L10n.Localizable.Self.NewDeviceAlert.trustDevices, style: .default) { [weak self] _ in
            self?.presentUserSettingChangeControllerIfNeeded()
        }

        newLoginAlertController.addAction(actionTrustDevices)

        present(newLoginAlertController, animated: true, completion: .none)

        userSession.enqueue {
            clients.forEach {
                $0.needsToNotifyUser = false
            }
        }
    }

    // TODO: delete commented code
    /*
    @discardableResult
    func openControllerForCellWithIdentifier(_ identifier: String) -> UIViewController? {

        guard
            let tabBarController = ZClientViewController.shared?.mainTabBarController,
            let settingsViewController = tabBarController.viewControllers?
                .compactMap({ $0 as? UINavigationController })
                .compactMap({ $0.viewControllers.first as? SettingsTableViewController })
                .first,
            let navigationController = settingsViewController.navigationController
        else { return nil }

        var resultViewController: UIViewController? = .none
        // Let's assume for the moment that menu is only 2 levels deep
        let rootGroup = settingsViewController.group
        settingsViewController.group.allCellDescriptors().forEach { topCellDescriptor in

            if let cellIdentifier = topCellDescriptor.identifier,
               let cellGroupDescriptor = topCellDescriptor as? SettingsControllerGeneratorType,
               let viewController = cellGroupDescriptor.generateViewController(),
               cellIdentifier == identifier {

                presentingViewController?.dismiss(animated: true) {
                    tabBarController.selectedIndex = MainTabBarControllerContent.settings.rawValue
                    navigationController.pushViewController(viewController, animated: true)
                }
                resultViewController = viewController
            }

            if let topCellGroupDescriptor = topCellDescriptor as? SettingsInternalGroupCellDescriptorType & SettingsControllerGeneratorType {
                topCellGroupDescriptor.allCellDescriptors().forEach({ (cellDescriptor: SettingsCellDescriptorType) in
                    if let cellIdentifier = cellDescriptor.identifier,
                       let cellGroupDescriptor = cellDescriptor as? SettingsControllerGeneratorType,
                       let topViewController = topCellGroupDescriptor.generateViewController(),
                       let viewController = cellGroupDescriptor.generateViewController(),
                       cellIdentifier == identifier {

                        presentingViewController?.dismiss(animated: true) {
                            tabBarController.selectedIndex = MainTabBarControllerContent.settings.rawValue
                            navigationController.pushViewController(topViewController, animated: true)
                            navigationController.pushViewController(viewController, animated: true)
                        }
                        resultViewController = viewController
                    }
                })
            }
        }

        return resultViewController
    }
     */
}

extension UIAlertController {

    convenience init(forNewSelfClients clients: [UserClientType]) {
        var deviceNamesAndDates: [String] = []

        for userClient in clients {
            let deviceName: String

            if let model = userClient.model, !model.isEmpty {
                deviceName = model
            } else {
                deviceName = userClient.type.rawValue
            }

            let formattedDate: String
            if let activationDate = userClient.activationDate {
                formattedDate = activationDate.formattedDate
            } else {
                formattedDate = ""
            }

            let deviceActivationDate = L10n.Localizable.Registration.Devices.activated(formattedDate)

            deviceNamesAndDates.append("\(deviceName) \(deviceActivationDate)")
        }

        let title = L10n.Localizable.Self.NewDeviceAlert.title

        let messageBody = deviceNamesAndDates.joined(separator: "\n\n")

        let messageFormat: String

        if clients.count > 1 {
            messageFormat = L10n.Localizable.Self.NewDeviceAlert.messagePlural(messageBody)
        } else {
            messageFormat = L10n.Localizable.Self.NewDeviceAlert.message(messageBody)
        }

        self.init(title: title, message: messageFormat, preferredStyle: .alert)
    }
}
