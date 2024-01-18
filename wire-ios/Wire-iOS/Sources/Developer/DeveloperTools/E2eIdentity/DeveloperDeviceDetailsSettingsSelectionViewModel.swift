//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel

// TODO: Remove this once this feature/e2ei is ready to be merged to develop

class DeveloperDeviceDetailsSettingsSelectionViewModel: ObservableObject {

    static var isE2eIdentityViewEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "isE2eIdentityViewEnabled")
        }
    }

    static var selectedE2eIdentiyStatus: String? {
        get {
            UserDefaults.standard.string(forKey: "E2EIdentityCertificateStatus")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "E2EIdentityCertificateStatus")
        }
    }

    struct Section: Identifiable {
        let id = UUID()
        let header: String
        let items: [Item]
    }

    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    enum Event {
        case itemTapped(Item)
    }

    // MARK: - State

    let sections: [Section]

    @Published
    var selectedItemID: Item.ID

    @Published
    var isE2eIdentityViewEnabled: Bool = DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled {
        didSet {
            Self.isE2eIdentityViewEnabled = isE2eIdentityViewEnabled
        }
    }
    // MARK: - Life cycle

    init() {
        sections = [
            Section(
                header: "Select E2eIdentity Status",
                items: E2EIdentityCertificateStatus.allCases.map({
                    Item(title: $0.titleForStatus(), value: $0.titleForStatus().count == 0 ? "None" : $0.titleForStatus())
                })
            )
        ]
        selectedItemID = UUID()
        guard let status = E2EIdentityCertificateStatus.allCases
                                                        .first(where: {$0.titleForStatus() == Self.selectedE2eIdentiyStatus ?? ""}),
              let selectedItem = sections.flatMap(\.items).first(where: {
            $0.value == status.titleForStatus()
        }) else {
            return
        }
        // Initial selection
        selectedItemID = selectedItem.id
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case let .itemTapped(item):
            selectedItemID = item.id
            Self.selectedE2eIdentiyStatus = item.value
        }
    }

    static func mockCertifiateForSelectedStatus() -> E2eIdentityCertificate? {
        guard let selectedE2eIdentiyStatus = selectedE2eIdentiyStatus,
              let selectedStatus = E2EIdentityCertificateStatus.status(for: selectedE2eIdentiyStatus) else {
            return nil
        }
        switch selectedStatus {
        case .notActivated:
            return .mockNotActivated
        case .revoked:
            return .mockRevoked
        case .expired:
            return .mockExpired
        case .valid:
            return .mockValid
        }
    }

}

private extension E2EIdentityCertificateStatus {
    static func status(for string: String) -> E2EIdentityCertificateStatus? {
        E2EIdentityCertificateStatus.allCases.filter({
            $0.titleForStatus() == string
        }).first
    }
}
