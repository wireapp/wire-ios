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

import Foundation
import WireTransport

final class SwitchBackendViewModel: ObservableObject {
    // MARK: - Models

    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let value: EnvironmentType
    }

    enum Event {
        case itemTapped(Item)
    }

    // MARK: - State

    let items: [Item]

    @Published var selectedItemID: Item.ID

    @Published var alertItem: AlertItem?

    struct AlertItem: Identifiable {
        let id = UUID()
        let message: String
        let action: (() -> Void)?
    }

    // MARK: - Life cycle

    init() {
        var items = [
            Item(title: "Production", value: .production),
            Item(title: "Staging", value: .staging),
            Item(title: "Anta", value: .anta),
            Item(title: "Bella", value: .bella),
            Item(title: "Chala", value: .chala),
            Item(title: "Diya", value: .diya),
            Item(title: "Elna", value: .elna),
            Item(title: "Foma", value: .foma),
        ]

        let selectedType = BackendEnvironment.shared.environmentType.value

        // Initial selection
        var selectedItem = items.first { item in
            item.value == selectedType
        }

        if selectedItem == nil {
            selectedItem = Item(title: "custom", value: selectedType)
            items.append(selectedItem!)
        }
        self.items = items
        self.selectedItemID = selectedItem!.id
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case let .itemTapped(item):
            selectedItemID = item.id

            if let environment = BackendEnvironment(type: item.value) {
                BackendEnvironment.shared = environment
                alertItem = AlertItem(message: "Backend switched! App will terminate. Start again to log in") {
                    exit(1)
                }
            } else {
                alertItem = AlertItem(message: "Failed to switch backend") {}
            }
        }
    }
}
