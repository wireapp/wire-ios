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

    @Published var isE2eIdentityViewEnabled: Bool = DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled {
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
                    Item(title: $0.titleForStatus(), value: $0.titleForStatus())
                })
            )
        ]
        selectedItemID = UUID()
        let status = E2EIdentityCertificateStatus.allCases.filter({
                $0.titleForStatus() == Self.selectedE2eIdentiyStatus ?? ""
            }
        ).first
        // Initial selection
        let selectedItem = sections.flatMap(\.items).first { item in
            item.value == status?.titleForStatus() ?? ""
        }!
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
}
