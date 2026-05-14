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

import UIKit
import WireDomain
import WireMainNavigationUI
import WireMessagingAssembly
import WireMessagingDomain
import WireSyncEngine

final class StartUIViewControllerBuilder: ConnectViewControllerBuilderProtocol {

    let userSession: UserSession
    let mainCoordinator: AnyMainCoordinator
    let createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol
    let channelConversationFormFactory: WireConversationChannelCreationFormViewControllerFactory

    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    let featureConfigRepository: FeatureConfigRepositoryProtocol

    weak var delegate: StartUIDelegate?

    init(
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol,
        channelConversationFormFactory: WireConversationChannelCreationFormViewControllerFactory,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        featureConfigRepository: FeatureConfigRepositoryProtocol,
        conversationCreationRepository: ConversationCreationRepositoryProtocol,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.createGroupConversationUIBuilder = createGroupConversationUIBuilder
        self.channelConversationFormFactory = channelConversationFormFactory
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.featureConfigRepository = featureConfigRepository
        self.conversationCreationRepository = conversationCreationRepository
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    @MainActor
    func build() async -> UIViewController? {
        let isAppsFeatureEnabled = await featureConfigRepository.isFeatureEnabled(.apps)
        let areLegacyBotsAvailable = await conversationCreationRepository.areBotsSetUpInTheTeam()

        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation(
                areLegacyBotsAvailable: areLegacyBotsAvailable,
                isAppsFeatureEnabled: isAppsFeatureEnabled
            )
        }

        return buildLegacy(
            areLegacyBotsAvailable: areLegacyBotsAvailable,
            isAppsFeatureEnabled: isAppsFeatureEnabled
        )
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .startUI,
            isKMPImplementationAvailable: false
        )
    }

    @MainActor
    private func buildKMPViewModelImplementation(
        areLegacyBotsAvailable: Bool,
        isAppsFeatureEnabled: Bool
    ) -> UIViewController? {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy(
            areLegacyBotsAvailable: areLegacyBotsAvailable,
            isAppsFeatureEnabled: isAppsFeatureEnabled
        )
    }

    @MainActor
    private func buildLegacy(
        areLegacyBotsAvailable: Bool,
        isAppsFeatureEnabled: Bool
    ) -> UIViewController? {
        let rootViewController = StartUIViewController(
            areLegacyBotsAvailable: areLegacyBotsAvailable,
            isAppsFeatureEnabled: isAppsFeatureEnabled,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            createGroupConversationUIBuilder: createGroupConversationUIBuilder,
            channelConversationFormFactory: channelConversationFormFactory,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
        rootViewController?.delegate = delegate
        return rootViewController
    }
}
