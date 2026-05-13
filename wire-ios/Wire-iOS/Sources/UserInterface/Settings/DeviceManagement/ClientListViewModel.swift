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

final class ClientListViewModel {

    struct RowModel {
        let cellViewModel: ClientTableViewCellModel
        let isEditable: Bool
        let canDelete: Bool
        fileprivate let client: UserClient
    }

    struct SectionModel {
        let headerTitle: String?
        let footerTitle: String?
        let rows: [RowModel]
    }

    enum DisplayState {
        case sections([SectionModel])
    }

    enum Action {
        case delete(UserClient)
    }

    enum Route {
        case deviceDetails(UserClient)
    }

    private let selfClient: UserClient?
    private let showTemporary: Bool
    private let showLegalHold: Bool
    private let showsDeviceDetails: Bool

    private var clients: [UserClient] = []

    private(set) var isEditing = false
    private(set) var displayState: DisplayState = .sections([])

    init(
        clientsList: [UserClient],
        selfClient: UserClient?,
        showTemporary: Bool,
        showLegalHold: Bool,
        showsDeviceDetails: Bool
    ) {
        self.selfClient = selfClient
        self.showTemporary = showTemporary
        self.showLegalHold = showLegalHold
        self.showsDeviceDetails = showsDeviceDetails

        updateClients(clientsList)
    }

    var numberOfSections: Int {
        sections.count
    }

    var showsEditButton: Bool {
        !clients.isEmpty
    }

    var hidesBackButton: Bool {
        isEditing
    }

    var activeClients: [UserClient] {
        clients
    }

    func updateClients(_ clientsList: [UserClient]) {
        clients = Self.displayedClients(
            from: clientsList,
            selfClient: selfClient,
            showTemporary: showTemporary,
            showLegalHold: showLegalHold
        )

        if clients.isEmpty {
            isEditing = false
        }

        updateDisplayState()
    }

    func setEditing(_ isEditing: Bool) {
        self.isEditing = clients.isEmpty ? false : isEditing
    }

    func numberOfRows(in section: Int) -> Int {
        sectionModel(at: section)?.rows.count ?? 0
    }

    func headerTitle(for section: Int) -> String? {
        sectionModel(at: section)?.headerTitle
    }

    func footerTitle(for section: Int) -> String? {
        sectionModel(at: section)?.footerTitle
    }

    func rowModel(at indexPath: IndexPath) -> RowModel? {
        guard let section = sectionModel(at: indexPath.section),
              section.rows.indices.contains(indexPath.row)
        else {
            return nil
        }

        return section.rows[indexPath.row]
    }

    func actionForDeletingRow(at indexPath: IndexPath) -> Action? {
        guard let rowModel = rowModel(at: indexPath), rowModel.canDelete else {
            return nil
        }

        return .delete(rowModel.client)
    }

    func routeForSelectingRow(at indexPath: IndexPath) -> Route? {
        guard showsDeviceDetails, let client = rowModel(at: indexPath)?.client else {
            return nil
        }

        return .deviceDetails(client)
    }

    func clientForUpdatedDetails(selectedClient: UserClient?, selectedClientIsSelfClient: Bool) -> UserClient? {
        if selectedClientIsSelfClient {
            return selfClient
        }

        guard let selectedClient else {
            return nil
        }

        return clients.first { $0.clientId == selectedClient.clientId }
    }

    private var sections: [SectionModel] {
        switch displayState {
        case let .sections(sections):
            sections
        }
    }

    private func sectionModel(at index: Int) -> SectionModel? {
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }

    private func updateDisplayState() {
        var sections = [SectionModel]()

        if let selfClient {
            sections.append(SectionModel(
                headerTitle: L10n.Localizable.Registration.Devices.currentListHeader,
                footerTitle: nil,
                rows: [
                    RowModel(
                        cellViewModel: .init(userClient: selfClient, shouldSetType: false),
                        isEditable: false,
                        canDelete: false,
                        client: selfClient
                    )
                ]
            ))
        }

        if selfClient == nil || !clients.isEmpty {
            sections.append(SectionModel(
                headerTitle: L10n.Localizable.Registration.Devices.activeListHeader,
                footerTitle: L10n.Localizable.Registration.Devices.activeListSubtitle,
                rows: clients.map { client in
                    RowModel(
                        cellViewModel: .init(userClient: client, shouldSetType: false),
                        isEditable: true,
                        canDelete: client.type != .legalHold,
                        client: client
                    )
                }
            ))
        }

        displayState = .sections(sections)
    }

    private static func displayedClients(
        from clientsList: [UserClient],
        selfClient: UserClient?,
        showTemporary: Bool,
        showLegalHold: Bool
    ) -> [UserClient] {
        clientsList
            .filter {
                $0 != selfClient &&
                    !$0.isSelfClient() &&
                    (showTemporary || $0.type != .temporary) &&
                    (showLegalHold || $0.type != .legalHold)
            }
            .sorted {
                guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else {
                    return false
                }
                return leftDate.compare(rightDate) == .orderedDescending
            }
    }

}
