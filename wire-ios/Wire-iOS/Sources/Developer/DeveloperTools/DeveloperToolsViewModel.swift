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

import SwiftUI
import WireCommonComponents
import WireDataModel
import WireRequestStrategy
import WireSyncEngine
import WireTransport

/// Data Structure containing contextual information currently displayed view
struct DeveloperToolsContext {
    var currentUserClient: UserClient?
}

final class DeveloperToolsViewModel: ObservableObject {
    static var context = DeveloperToolsContext()

    // MARK: - Models

    struct Section: Identifiable {
        let id = UUID()
        var header: String
        var items: [Item]
    }

    enum Item: Identifiable {
        case button(ButtonItem)
        case text(TextItem)
        case destination(DestinationItem)

        var id: UUID {
            switch self {
            case let .button(item):
                item.id

            case let .text(item):
                item.id

            case let .destination(item):
                item.id
            }
        }
    }

    struct ButtonItem: Identifiable {
        let id = UUID()
        let title: String
        let action: () -> Void
    }

    struct TextItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    struct DestinationItem: Identifiable {
        let id = UUID()
        let title: String
        let makeView: () -> AnyView
    }

    enum Event {
        case dismissButtonTapped
        case itemTapped(Item)
        case itemCopyRequested(Item)
    }

    // MARK: - Properties

    let router: AppRootRouter?
    let onDismiss: (_ completion: @escaping () -> Void) -> Void

    // MARK: - State

    var sections: [Section]

    @Published var isPresentingAlert = false

    var alertTitle: String?
    var alertBody: String?

    // MARK: - Computed

    private var userSession: ZMUserSession? {
        ZMUserSession.shared()
    }

    // MARK: - Life cycle

    init(
        router: AppRootRouter? = nil,
        onDismiss: @escaping (_ completion: @escaping () -> Void) -> Void = { $0() }
    ) {
        self.router = router
        self.onDismiss = onDismiss
        self.sections = []

        setupSections()
    }

    private func setupSections() {
        setupContextualItems()

        setupActions()

        setupAppInfo()

        sections.append(backendInfoSection)

        setupSelfUser()

        setupPushToken()

        setupDatadog()
    }

    // MARK: - Section Builders

    private func setupAppInfo() {
        sections.append(Section(
            header: "App info",
            items: [
                .text(TextItem(title: "App version", value: appVersion)),
                .text(TextItem(title: "Build number", value: buildNumber)),
                .text(TextItem(title: "Bundle Identifier", value: bundleIdentifier)),
            ]
        ))
    }

    private func setupSelfUser() {
        if let selfUser {
            sections.append(Section(
                header: "Self user",
                items: [
                    .text(TextItem(title: "Handle", value: selfUser.handleDisplayString(withDomain: true) ?? "None")),
                    .text(TextItem(title: "Email", value: selfUser.emailAddress ?? "None")),
                    .text(TextItem(title: "User ID", value: selfUser.remoteIdentifier.uuidString)),
                    .text(TextItem(title: "Analytics ID", value: selfUser.analyticsIdentifier?.uppercased() ?? "None")),
                    .text(TextItem(title: "Client ID", value: selfClient?.remoteIdentifier?.uppercased() ?? "None")),
                    .text(TextItem(
                        title: "Supported protocols",
                        value: selfUser.supportedProtocols.map(\.rawValue).joined(separator: ", ")
                    )),
                    .text(TextItem(
                        title: "MLS public key",
                        value: selfClient?.mlsPublicKeys.allKeys.first?.uppercased() ?? "None"
                    )),
                ]
            ))
        }
    }

    private func setupPushToken() {
        if let pushToken = PushTokenStorage.pushToken {
            sections.append(Section(
                header: "Push token",
                items: [
                    .text(TextItem(title: "Token type", value: String(describing: pushToken.tokenType))),
                    .text(TextItem(title: "Token data", value: pushToken.deviceTokenString)),
                    .button(ButtonItem(title: "Check registered tokens", action: { [weak self] in
                        self?.checkRegisteredTokens()
                    })),
                ]
            ))
        }
    }

    private func setupDatadog() {
        if let datadogUserIdentifier = WireAnalytics.Datadog.userIdentifier {
            sections.append(Section(
                header: "Datadog",
                items: [
                    .text(TextItem(title: "User ID", value: datadogUserIdentifier)),
                    .button(.init(title: "Crash Report Test", action: { fatal("crash app") })),
                ]
            ))
        }
    }

    private func setupContextualItems() {
        let actionsProviders: [DeveloperToolsContextItemsProvider?] = [
            UserClientDeveloperItemsProvider(context: Self.context),
            // add new builder here
        ]

        let actions = actionsProviders.reduce(into: []) { $0 += ($1?.getActionItems() ?? []) }
        guard !actions.isEmpty else { return }

        sections.append(
            Section(
                header: "Contextual Menu",
                items: actions
            )
        )
    }

    private func setupActions() {
        sections.append(Section(
            header: "Actions",
            items: [
                .destination(DestinationItem(title: "E2E Identity", makeView: {
                    AnyView(DeveloperE2eiView(viewModel: DeveloperE2eiViewModel()))
                })),
                .destination(DestinationItem(title: "Debug actions", makeView: { [weak self] in
                    AnyView(DeveloperDebugActionsView(viewModel: DeveloperDebugActionsViewModel(
                        selfClient: self?
                            .selfClient
                    )))
                })),
                .destination(DestinationItem(title: "Configure feature flags", makeView: {
                    AnyView(DeveloperFlagsView(viewModel: DeveloperFlagsViewModel()))
                })),
                .destination(DestinationItem(title: "Deep links", makeView: { [weak self] in
                    AnyView(DeepLinksView(viewModel: DeepLinksViewModel(
                        router: self?.router,
                        onDismiss: self?.onDismiss ?? { $0() }
                    )))
                })),
            ]
        ))
    }

    private lazy var backendInfoSection: Section = {
        let header = "Backend info"
        var items = [Item]()

        items.append(.text(TextItem(title: "Name", value: backendName)))

        if canSwitchBackend {
            items.append(.destination(DestinationItem(title: "Switch backend", makeView: {
                AnyView(SwitchBackendView(viewModel: SwitchBackendViewModel()))
            })))
        }

        items.append(.text(TextItem(title: "Domain", value: backendDomain)))
        items.append(.text(TextItem(title: "API version", value: apiVersion)))
        items.append(.destination(DestinationItem(title: "Preferred API version", makeView: {
            AnyView(PreferredAPIVersionView(viewModel: PreferredAPIVersionViewModel()))
        })))

        items.append(.text(TextItem(title: "Is federation enabled?", value: isFederationEnabled)))
        items.append(.button(ButtonItem(title: "Stop federating with Foma", action: { [weak self] in
            self?.stopFederatingFoma()
        })))
        items.append(.button(ButtonItem(title: "Stop federating with Bella", action: { [weak self] in
            self?.stopFederatingBella()
        })))
        items.append(.button(ButtonItem(title: "Stop Bella Foma federating", action: { [weak self] in
            self?.stopBellaFomaFederating()
        })))
        return Section(
            header: header,
            items: items
        )
    }()

    private var canSwitchBackend: Bool {
        guard let sessionManager = SessionManager.shared else { return false }
        return sessionManager.canSwitchBackend() == nil
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case .dismissButtonTapped:
            onDismiss {}

        case let .itemCopyRequested(.text(textItem)):
            UIPasteboard.general.string = textItem.value

        case let .itemTapped(.button(buttonItem)):
            buttonItem.action()

        default:
            break
        }
    }

    // MARK: - Actions

    private func checkRegisteredTokens() {
        guard
            let clientID = selfClient?.remoteIdentifier,
            let context = userSession?.notificationContext
        else {
            return
        }

        let action = GetPushTokensAction(clientID: clientID) { result in
            switch result {
            case .success([]):
                self.alertTitle = "No registered tokens"
                self.alertBody = nil

            case let .success(tokens):
                self.alertTitle = "Registered push tokens"
                self.alertBody = tokens.map(\.debugDescription).joined(separator: "\n\n")

            case let .failure(error):
                self.alertTitle = "Registered push tokens"
                self.alertBody = "Failed to fetch push tokens: \(String(describing: error))"
            }

            self.isPresentingAlert = true
        }

        action.send(in: context)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.shortVersionString ?? "Unknown"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"
    }

    private var backendName: String {
        BackendEnvironment.shared.title
    }

    private var backendDomain: String {
        BackendInfo.domain ?? "None"
    }

    private var apiVersion: String {
        guard let version = BackendInfo.apiVersion else { return "None" }
        return String(describing: version.rawValue)
    }

    private var isFederationEnabled: String {
        String(describing: BackendInfo.isFederationEnabled)
    }

    private var selfUser: ZMUser? {
        guard let userSession else { return nil }
        return ZMUser.selfUser(inUserSession: userSession)
    }

    private var selfClient: UserClient? {
        guard let userSession else { return nil }
        return userSession.selfUserClient
    }

    private func stopFederatingBella() {
        stopFederatingDomain(domain: "bella.wire.link")
    }

    private func stopFederatingFoma() {
        stopFederatingDomain(domain: "foma.wire.link")
    }

    private func stopBellaFomaFederating() {
        guard
            let selfClient,
            let context = selfClient.managedObjectContext
        else {
            return
        }

        let manager = FederationTerminationManager(with: context)
        manager.handleFederationTerminationBetween("bella.wire.link", otherDomain: "foma.wire.link")
    }

    private func stopFederatingDomain(domain: String) {
        guard
            let selfClient,
            let context = selfClient.managedObjectContext
        else {
            return
        }

        let manager = FederationTerminationManager(with: context)
        manager.handleFederationTerminationWith(domain)
    }
}

extension PushToken.TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .standard:
            "Standard"

        case .voip:
            "VoIP"
        }
    }
}

extension PushToken: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        token: \(deviceTokenString),
        type: \(tokenType),
        transport: \(transportType)
        app: \(appIdentifier)
        """
    }
}
