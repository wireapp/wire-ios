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

final class SettingsClientViewModel {

    enum Section {
        case info
        case fingerprintAndVerify
        case resetSession
        case removeDevice
    }

    enum Row {
        case info(ClientTableViewCellModel)
        case fingerprint(Data?)
        case verified(VerifiedRow)
        case resetSession(SettingsRow)
        case removeDevice(SettingsRow)
    }

    struct VerifiedRow {
        let title: String
        let isOn: Bool
        let labelAccessibilityIdentifier: String
        let switchAccessibilityIdentifier: String
        let accessibilityIdentifier: String
    }

    struct SettingsRow {
        let title: String
        let accessibilityIdentifier: String
    }

    enum Action {
        case resetSession(UserClient)
        case removeDevice(UserClient)
        case setVerified(UserClient, isVerified: Bool)
    }

    let userClient: UserClient
    private let selfUserClient: UserClient?
    private let getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol
    private(set) var fingerprintData: Data?

    var fingerprintDataClosure: ((Data?) -> Void)?

    private var isSelfClient: Bool {
        userClient == selfUserClient
    }

    private var sections: [Section] {
        if isSelfClient {
            [.info, .fingerprintAndVerify]
        } else if userClient.type == .legalHold {
            [.info, .fingerprintAndVerify, .resetSession]
        } else {
            [.info, .fingerprintAndVerify, .resetSession, .removeDevice]
        }
    }

    var numberOfSections: Int {
        sections.count
    }

    var navigationTitle: String? {
        userClient.deviceClass?.localizedDescription.capitalized
    }

    init(
        userClient: UserClient,
        selfUserClient: UserClient?,
        getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol
    ) {
        self.userClient = userClient
        self.selfUserClient = selfUserClient
        self.getUserClientFingerprint = getUserClientFingerprint
    }

    func loadData() {
        Task {
            self.fingerprintData = await getUserClientFingerprint.invoke(userClient: userClient)

            await MainActor.run { [fingerprintData] in
                self.fingerprintDataClosure?(fingerprintData)
            }
        }
    }

    func numberOfRows(in sectionIndex: Int) -> Int {
        guard let section = section(at: sectionIndex) else {
            return 0
        }

        switch section {
        case .info, .resetSession, .removeDevice:
            return 1
        case .fingerprintAndVerify:
            return isSelfClient ? 1 : 2
        }
    }

    func row(at indexPath: IndexPath) -> Row? {
        guard let section = section(at: indexPath.section) else {
            return nil
        }

        switch section {
        case .info:
            guard indexPath.row == 0 else { return nil }
            return .info(.init(userClient: userClient, shouldSetType: false))

        case .fingerprintAndVerify:
            switch indexPath.row {
            case 0:
                return .fingerprint(fingerprintData)
            case 1 where !isSelfClient:
                return .verified(
                    .init(
                        title: L10n.Localizable.Device.verified,
                        isOn: userClient.verified,
                        labelAccessibilityIdentifier: "device verified label",
                        switchAccessibilityIdentifier: "device verified",
                        accessibilityIdentifier: "device verified"
                    )
                )
            default:
                return nil
            }

        case .resetSession:
            guard indexPath.row == 0 else { return nil }
            return .resetSession(
                .init(
                    title: L10n.Localizable.Profile.Devices.Detail.ResetSession.title,
                    accessibilityIdentifier: "reset session"
                )
            )

        case .removeDevice:
            guard indexPath.row == 0 else { return nil }
            return .removeDevice(
                .init(
                    title: L10n.Localizable.Self.Settings.AccountDetails.RemoveDevice.title,
                    accessibilityIdentifier: "remove device"
                )
            )
        }
    }

    func footerTitle(for sectionIndex: Int) -> String? {
        guard let section = section(at: sectionIndex) else {
            return nil
        }

        switch section {
        case .fingerprintAndVerify:
            return L10n.Localizable.Self.Settings.DeviceDetails.Fingerprint.subtitle
        case .resetSession:
            return L10n.Localizable.Self.Settings.DeviceDetails.ResetSession.subtitle
        case .removeDevice:
            return L10n.Localizable.Self.Settings.DeviceDetails.RemoveDevice.subtitle
        case .info:
            return nil
        }
    }

    func actionForSelectingRow(at indexPath: IndexPath) -> Action? {
        switch row(at: indexPath) {
        case .some(.resetSession):
            return .resetSession(userClient)
        case .some(.removeDevice):
            return .removeDevice(userClient)
        case .some(.info), .some(.fingerprint), .some(.verified), nil:
            return nil
        }
    }

    func actionForVerifiedChanged(isOn: Bool) -> Action {
        .setVerified(userClient, isVerified: isOn)
    }

    func shouldShowCopyMenu(for indexPath: IndexPath) -> Bool {
        if case .some(.info) = row(at: indexPath) {
            return true
        }

        return false
    }

    func copyText(for indexPath: IndexPath) -> String? {
        guard shouldShowCopyMenu(for: indexPath) else {
            return nil
        }

        return userClient.information
    }

    private func section(at index: Int) -> Section? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }
}
