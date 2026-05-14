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

import WireDataModel
import WireMainNavigationUI
import WireMessagingDomain
import WireSyncEngine

struct SearchUserViewControllerBuilder {

    private let userSession: UserSession
    private let mainCoordinator: AnyMainCoordinator
    private let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    private let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversationCreationRepository = conversationCreationRepository
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    @MainActor
    func build(
        qualifiedID: QualifiedID,
        profileViewControllerDelegate: ProfileViewControllerDelegate?
    ) -> SearchUserViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation(
                qualifiedID: qualifiedID,
                profileViewControllerDelegate: profileViewControllerDelegate
            )
        }

        return buildLegacy(
            qualifiedID: qualifiedID,
            profileViewControllerDelegate: profileViewControllerDelegate
        )
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .searchUser,
            isKMPImplementationAvailable: false
        )
    }

    @MainActor
    private func buildKMPViewModelImplementation(
        qualifiedID: QualifiedID,
        profileViewControllerDelegate: ProfileViewControllerDelegate?
    ) -> SearchUserViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy(
            qualifiedID: qualifiedID,
            profileViewControllerDelegate: profileViewControllerDelegate
        )
    }

    @MainActor
    private func buildLegacy(
        qualifiedID: QualifiedID,
        profileViewControllerDelegate: ProfileViewControllerDelegate?
    ) -> SearchUserViewController {
        SearchUserViewController(
            qualifiedID: qualifiedID,
            profileViewControllerDelegate: profileViewControllerDelegate,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
    }
}
