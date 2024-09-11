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
import WireSyncEngine

extension SelfProfileViewController {
    func presentNewLoginAlertControllerIfNeeded() -> Bool {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return false
        }
        let clientsRequiringUserAttention = Array(selfUser.clientsRequiringUserAttention)

        if !clientsRequiringUserAttention.isEmpty {
            self.presentNewLoginAlertController(clientsRequiringUserAttention)
            return true
        } else {
            return false
        }
    }

    private func presentNewLoginAlertController(_ clients: [UserClientType]) {
        let newLoginAlertController = UIAlertController(forNewSelfClients: clients)

        let actionManageDevices = UIAlertAction(
            title: L10n.Localizable.Self.NewDeviceAlert.manageDevices,
            style: .default
        ) { _ in
            self.openControllerForCellWithIdentifier(SettingsCellDescriptorFactory.settingsDevicesCellIdentifier)
        }

        newLoginAlertController.addAction(actionManageDevices)

        let actionTrustDevices = UIAlertAction(
            title: L10n.Localizable.Self.NewDeviceAlert.trustDevices,
            style: .default
        ) { [weak self] _ in
            self?.presentUserSettingChangeControllerIfNeeded()
        }

        newLoginAlertController.addAction(actionTrustDevices)

        present(newLoginAlertController, animated: true, completion: .none)

        userSession.enqueue {
            for client in clients {
                client.needsToNotifyUser = false
            }
        }
    }

    @discardableResult
    func openControllerForCellWithIdentifier(_ identifier: String) -> UIViewController? {
        var resultViewController: UIViewController? = .none
        // Let's assume for the moment that menu is only 2 levels deep
        rootGroup?.allCellDescriptors().forEach { (topCellDescriptor: SettingsCellDescriptorType) in

            if let cellIdentifier = topCellDescriptor.identifier,
               let cellGroupDescriptor = topCellDescriptor as? SettingsControllerGeneratorType,
               let viewController = cellGroupDescriptor.generateViewController(),
               cellIdentifier == identifier {
                self.navigationController?.pushViewController(viewController, animated: false)
                resultViewController = viewController
            }

            if let topCellGroupDescriptor = topCellDescriptor as? SettingsInternalGroupCellDescriptorType &
                SettingsControllerGeneratorType {
                for cellDescriptor in topCellGroupDescriptor.allCellDescriptors() {
                    if let cellIdentifier = cellDescriptor.identifier,
                       let cellGroupDescriptor = cellDescriptor as? SettingsControllerGeneratorType,
                       let topViewController = topCellGroupDescriptor.generateViewController(),
                       let viewController = cellGroupDescriptor.generateViewController(),
                       cellIdentifier == identifier {
                        self.navigationController?.pushViewController(topViewController, animated: false)
                        self.navigationController?.pushViewController(viewController, animated: false)
                        resultViewController = viewController
                    }
                }
            }
        }

        return resultViewController
    }
}

extension UIAlertController {
    convenience init(forNewSelfClients clients: [UserClientType]) {
        var deviceNamesAndDates: [String] = []

        for userClient in clients {
            let deviceName: String = if let model = userClient.model, !model.isEmpty {
                model
            } else {
                userClient.type.rawValue
            }

            let formattedDate: String = if let activationDate = userClient.activationDate {
                activationDate.formattedDate
            } else {
                ""
            }

            let deviceActivationDate = L10n.Localizable.Registration.Devices.activated(formattedDate)

            deviceNamesAndDates.append("\(deviceName) \(deviceActivationDate)")
        }

        let title = L10n.Localizable.Self.NewDeviceAlert.title

        let messageBody = deviceNamesAndDates.joined(separator: "\n\n")

        let messageFormat: String = if clients.count > 1 {
            L10n.Localizable.Self.NewDeviceAlert.messagePlural(messageBody)
        } else {
            L10n.Localizable.Self.NewDeviceAlert.message(messageBody)
        }

        self.init(title: title, message: messageFormat, preferredStyle: .alert)
    }
}
