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
import WireNetwork
import WireSyncEngine

final class ServiceDetailViewModel {

    struct ViewState {
        let navigationTitle: String?
        let actionButton: ActionButtonState
        let sections: [Section]
    }

    struct ActionButtonState {
        enum Kind {
            case addApp
            case removeParticipant
            case openConversation
        }

        let kind: Kind
        let title: String
        let isHidden: Bool
    }

    enum Section: Equatable {
        case summary(title: String?, provider: String?, category: String?)
        case description(String?)
    }

    enum DetailsFetch {
        case app(teamID: WireNetwork.Team.ID, appID: UUID)
        case bot
    }

    private(set) var service: Service

    private let actionType: ServiceDetailViewController.ActionType
    private let selfUser: any WireDataModel.UserType

    init(
        user: any WireDataModel.UserType,
        actionType: ServiceDetailViewController.ActionType,
        selfUser: any WireDataModel.UserType
    ) {
        self.service = Service(user: user)
        self.actionType = actionType
        self.selfUser = selfUser
    }

    var viewState: ViewState {
        ViewState(
            navigationTitle: service.user.name,
            actionButton: actionButtonState,
            sections: sections
        )
    }

    var detailsFetch: DetailsFetch {
        if
            !service.isLegacyBot,
            let teamID = service.user.teamIdentifier,
            let appID = service.user.remoteIdentifier {
            return .app(teamID: teamID, appID: appID)
        } else {
            return .bot
        }
    }

    func applyLocalAppDetails() {
        let appInfo = service.user.appInfo
        service.serviceUserDetails = makeServiceDetails(
            category: appInfo?.category ?? "",
            description: appInfo?.appDescription ?? ""
        )
        service.provider = ServiceProvider(
            identifier: "",
            name: service.user.teamName ?? "",
            email: "",
            url: "",
            providerDescription: ""
        )
    }

    func applyRemoteAppInfo(_ appInfo: AppInfo) {
        service.serviceUserDetails = makeServiceDetails(
            category: appInfo.category,
            description: appInfo.description
        )
    }

    func applyProvider(_ provider: ServiceProvider?) {
        service.provider = provider
    }

    func applyServiceDetails(_ serviceDetails: ServiceDetails?) {
        service.serviceUserDetails = serviceDetails
    }

    private var actionButtonState: ActionButtonState {
        switch actionType {
        case let .addApp(conversation), let .addBot(conversation):
            ActionButtonState(
                kind: .addApp,
                title: L10n.Localizable.Peoplepicker.Apps.AddApp.button.capitalized,
                isHidden: !selfUser.canAddService(to: conversation)
            )

        case let .removeParticipant(conversation):
            ActionButtonState(
                kind: .removeParticipant,
                title: L10n.Localizable.Participants.Apps.RemoveIntegration.button.capitalized,
                isHidden: !selfUser.canRemoveService(from: conversation)
            )

        case .openConversation:
            ActionButtonState(
                kind: .openConversation,
                title: L10n.Localizable.Peoplepicker.Apps.OpenConversation.item.capitalized,
                isHidden: !selfUser.canCreateService
            )
        }
    }

    private var sections: [Section] {
        [
            .summary(
                title: service.user.name,
                provider: service.provider?.name,
                category: service.serviceUserDetails?.category
            ),
            .description(service.serviceUserDetails?.serviceDescription)
        ]
    }

    private func makeServiceDetails(
        category: String,
        description: String
    ) -> ServiceDetails {
        ServiceDetails(
            serviceIdentifier: "",
            providerIdentifier: "",
            name: service.user.name ?? "",
            category: category,
            serviceDescription: description
        )
    }

}
