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
import WireNetwork
import WireSyncEngine

protocol ServiceDetailFetchHandling {

    func fetchDetails(
        using viewModel: ServiceDetailViewModel,
        updateService: @escaping (Service) -> Void
    )

}

final class LegacyServiceDetailFetchHandler: ServiceDetailFetchHandling {

    private let userSession: UserSession
    private let usersAPI: (any UsersAPI)?

    init(
        userSession: UserSession,
        usersAPI: (any UsersAPI)?
    ) {
        self.userSession = userSession
        self.usersAPI = usersAPI
    }

    func fetchDetails(
        using viewModel: ServiceDetailViewModel,
        updateService: @escaping (Service) -> Void
    ) {
        switch viewModel.detailsFetch {
        case let .app(teamID, appID):
            fetchAppDetails(
                for: teamID,
                with: appID,
                using: viewModel,
                updateService: updateService
            )
        case .bot:
            fetchBotDetails(
                using: viewModel,
                updateService: updateService
            )
        }
    }

    private func fetchAppDetails(
        for _: WireNetwork.Team.ID,
        with _: UUID,
        using viewModel: ServiceDetailViewModel,
        updateService: @escaping (Service) -> Void
    ) {
        viewModel.applyLocalAppDetails()
        updateService(viewModel.service)

        let localDomain = userSession.resolvedBackendMetadata.domain
        if let usersAPI, let userID = viewModel.service.user.qualifiedID(localDomain: localDomain) {
            Task { @MainActor [weak viewModel] in
                do {
                    guard let viewModel else { return }
                    guard let appInfo = try await usersAPI.getUser(for: .init(userID)).app else { return }

                    viewModel.applyRemoteAppInfo(appInfo)
                    updateService(viewModel.service)
                } catch {
                    let errorType = Swift.type(of: error)
                    WireLogger.search.error("Failed to fetch app info: \(String(describing: errorType))")
                }
            }
        }
    }

    private func fetchBotDetails(
        using viewModel: ServiceDetailViewModel,
        updateService: @escaping (Service) -> Void
    ) {
        guard let userSession = userSession as? ZMUserSession else { return }

        viewModel.service.user.fetchProvider(in: userSession) { [weak viewModel] provider in
            guard let viewModel else { return }
            viewModel.applyProvider(provider)
            updateService(viewModel.service)
        }
        viewModel.service.user.fetchDetails(in: userSession) { [weak viewModel] details in
            guard let viewModel else { return }
            viewModel.applyServiceDetails(details)
            updateService(viewModel.service)
        }
    }

}
