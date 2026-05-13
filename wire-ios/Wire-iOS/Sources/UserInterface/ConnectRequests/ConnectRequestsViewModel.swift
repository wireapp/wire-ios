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
import WireDataModel
import WireSyncEngine

final class ConnectRequestsViewModel {

    struct Row {
        let user: UserType
    }

    enum Route {
        case hideRequests
        case selectConversation(ZMConversation)
        case showNextRequest(IndexPath)
        case showError(LocalizedError)
    }

    private(set) var connectionRequests: [ConversationLike]
    private(set) var isAccepting = false
    private(set) var isIgnoring = false

    init(connectionRequests: [ConversationLike] = []) {
        self.connectionRequests = connectionRequests
    }

    var rowCount: Int {
        connectionRequests.count
    }

    var hasMultipleRequests: Bool {
        connectionRequests.count > 1
    }

    func update(connectionRequests: [ConversationLike]) {
        self.connectionRequests = connectionRequests
    }

    func row(at indexPath: IndexPath) -> Row? {
        guard let request = request(at: indexPath), let user = request.connectedUserType else { return nil }

        return Row(user: user)
    }

    func accept(rowAt indexPath: IndexPath, completion: @escaping ([Route]) -> Void) {
        guard let user = row(at: indexPath)?.user else { return }

        accept(user: user, completion: completion)
    }

    func accept(user: UserType, completion: @escaping ([Route]) -> Void) {
        isAccepting = true
        user.accept { [weak self] error in
            guard let self else { return }

            isAccepting = false
            if let error = error as? LocalizedError {
                completion([.showError(error)])
            } else {
                var routes = [Route]()

                if connectionRequests.isEmpty {
                    routes.append(.hideRequests)

                    if let oneToOneConversation = user.oneToOneConversation {
                        routes.append(.selectConversation(oneToOneConversation))
                    }
                }

                completion(routes)
            }
        }
    }

    func ignore(rowAt indexPath: IndexPath, completion: @escaping ([Route]) -> Void) {
        guard let user = row(at: indexPath)?.user else { return }

        ignore(user: user, completion: completion)
    }

    func ignore(user: UserType, completion: @escaping ([Route]) -> Void) {
        isIgnoring = true
        user.ignore { [weak self] error in
            guard let self else { return }

            isIgnoring = false
            if let error = error as? LocalizedError {
                completion([.showError(error)])
            } else {
                completion(routesForCurrentRequests())
            }
        }
    }

    func routesAfterReloadIfIdle() -> [Route] {
        guard !isAccepting, !isIgnoring else { return [] }

        return routesForCurrentRequests()
    }

    private func request(at indexPath: IndexPath) -> ConversationLike? {
        let index = (connectionRequests.count - 1) - indexPath.row

        guard connectionRequests.indices.contains(index) else { return nil }

        return connectionRequests[index]
    }

    private func routesForCurrentRequests() -> [Route] {
        if connectionRequests.isEmpty {
            return [.hideRequests]
        } else {
            return [.showNextRequest(IndexPath(row: connectionRequests.count - 1, section: 0))]
        }
    }
}
