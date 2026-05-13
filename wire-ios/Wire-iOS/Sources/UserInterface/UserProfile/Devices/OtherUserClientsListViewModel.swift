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
import WireLogging
import WireSyncEngine

final class OtherUserClientsListViewModel {

    struct RowModel {
        let cellModel: ClientTableViewCellModel
        fileprivate let client: UserClientType
    }

    enum DisplayState {
        case empty
        case items([RowModel])
    }

    enum Route {
        case deviceDetails(UserClient)
    }

    private(set) var displayState: DisplayState = .empty
    private(set) var showsUnencryptedLabel = false
    let userName: String

    private var clients: [UserClientType] = [] {
        didSet {
            displayState = clients.isEmpty
                ? .empty
                : .items(clients.map { RowModel(cellModel: .init(userClient: $0), client: $0) })
        }
    }

    init(user: UserType) {
        self.userName = user.name ?? ""
        refresh(from: user)
    }

    var numberOfItems: Int {
        switch displayState {
        case .empty:
            0
        case let .items(rowModels):
            rowModels.count
        }
    }

    var clientsForCertificateUpdate: [UserClientType] {
        clients
    }

    func refresh(from user: UserType) {
        showsUnencryptedLabel = (user as? ZMUser)?.clients.isEmpty == true
        clients = Self.clientsSortedByRelevance(for: user)
    }

    func updateClients(_ clients: [UserClientType]) {
        self.clients = clients
    }

    func rowModel(at indexPath: IndexPath) -> RowModel? {
        switch displayState {
        case .empty:
            return nil
        case let .items(rowModels):
            guard rowModels.indices.contains(indexPath.row) else {
                return nil
            }

            return rowModels[indexPath.row]
        }
    }

    func routeForSelectingRow(at indexPath: IndexPath) -> Route? {
        guard let client = rowModel(at: indexPath)?.client as? UserClient else {
            return nil
        }

        return .deviceDetails(client)
    }

    private static func clientsSortedByRelevance(for user: UserType) -> [UserClientType] {
        user.allClients.sortedByRelevance().filter { !$0.isSelfClient() }
    }

}

extension Array where Element: UserClientType {

    @MainActor
    func updateCertificates(mlsGroupId: MLSGroupID, userSession: UserSession) async -> [UserClientType] {
        guard let userClients = self as? [UserClient] else {
            return self
        }
        var updatedUserClients = [UserClientType]()
        let mlsClients: [Int: MLSClientID] = Dictionary(uniqueKeysWithValues: userClients.compactMap {
            if let mlsClientId = MLSClientID(userClient: $0, localDomain: userSession.resolvedBackendMetadata.domain) {
                ($0.clientId.hashValue, mlsClientId)
            } else {
                nil
            }
        })
        let mlsClientIds = mlsClients.values.map(\.self)
        do {
            let certificates = try await userSession.getE2eIdentityCertificates.invoke(
                mlsGroupId: mlsGroupId,
                clientIds: mlsClientIds
            )
            if !certificates.isEmpty {
                for client in userClients {
                    let mlsClientIdRawValue = mlsClients[client.clientId.hashValue]?.rawValue
                    if let e2eiCertificate = certificates.first(where: { $0.clientId == mlsClientIdRawValue }) {
                        if userSession.e2eiFeature.isEnabled {
                            client.e2eIdentityCertificate = e2eiCertificate
                        }
                        client.mlsThumbPrint = e2eiCertificate.mlsThumbprint
                    }
                    updatedUserClients.append(client)
                }
                return updatedUserClients
            } else {
                return self
            }
        } catch {
            WireLogger.e2ei.error(error.localizedDescription)
            return self
        }
    }

}
