//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireRequestStrategy
import WireSyncEngine
import WireTransport
import UIKit
import SwiftUI
import WireCommonComponents

final class DeveloperToolsViewModel: ObservableObject {

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
            case .button(let item):
                return item.id

            case .text(let item):
                return item.id

            case .destination(let item):
                return item.id
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

    var onDismiss: (() -> Void)?

    // MARK: - State

    var sections: [Section]

    @Published
    var isPresentingAlert = false

    var alertTitle: String?
    var alertBody: String?

    // MARK: - Life cycle

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        sections = []

        sections.append(Section(
            header: "Actions",
            items: [
                .button(ButtonItem(title: "Send debug logs", action: sendDebugLogs)),
                .button(ButtonItem(title: "Perform quick sync", action: performQuickSync)),
                .button(ButtonItem(title: "Break next quick sync", action: breakNextQuickSync)),
                .button(ButtonItem(title: "Enroll e2ei certificate", action: enrollE2EICertificate)),
                .destination(DestinationItem(title: "Configure flags", makeView: {
                    AnyView(DeveloperFlagsView(viewModel: DeveloperFlagsViewModel()))
                }))
            ]
        ))

        sections.append(Section(
            header: "App info",
            items: [
                .text(TextItem(title: "App version", value: appVersion)),
                .text(TextItem(title: "Build number", value: buildNumber)),
                .text(TextItem(title: "Bundle Identifier", value: bundleIdentifier))
            ]
        ))

        sections.append(backendInfoSection)

        if let selfUser = selfUser {
            sections.append(Section(
                header: "Self user",
                items: [
                    .text(TextItem(title: "Handle", value: selfUser.handle ?? "None")),
                    .text(TextItem(title: "Email", value: selfUser.emailAddress ?? "None")),
                    .text(TextItem(title: "User ID", value: selfUser.remoteIdentifier.uuidString)),
                    .text(TextItem(title: "Analytics ID", value: selfUser.analyticsIdentifier?.uppercased() ?? "None")),
                    .text(TextItem(title: "Client ID", value: selfClient?.remoteIdentifier?.uppercased() ?? "None")),
                    .text(TextItem(title: "MLS public key", value: selfClient?.mlsPublicKeys.ed25519?.uppercased() ?? "None"))
                ]
            ))
        }

        if let pushToken = PushTokenStorage.pushToken {
            sections.append(Section(
                header: "Push token",
                items: [
                    .text(TextItem(title: "Token type", value: String(describing: pushToken.tokenType))),
                    .text(TextItem(title: "Token data", value: pushToken.deviceTokenString)),
                    .button(ButtonItem(title: "Check registered tokens", action: checkRegisteredTokens))
                ]
            ))
        }

        if let dataDogUserId = DatadogWrapper.shared?.datadogUserId {
            sections.append(Section(
                header: "Datadog",
                items: [
                    .text(TextItem(title: "User ID", value: String(describing: dataDogUserId))),
                    .button(.init(title: "Crash Report Test", action: { fatalError("crash app") }))
                ]
            ))
        }
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
        items.append(.button(ButtonItem(title: "Stop federating with Foma", action: stopFederatingFoma)))
        items.append(.button(ButtonItem(title: "Stop federating with Bella", action: stopFederatingBella)))
        items.append(.button(ButtonItem(title: "Stop Bella Foma federating", action: stopBellaFomaFederating)))
        items.append(.destination(DestinationItem(title: "Device details view settings", makeView: {
            AnyView(DeveloperDeviceDetailsSettingsSelectionView(viewModel: DeveloperDeviceDetailsSettingsSelectionViewModel()))
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
            onDismiss?()

        case let .itemCopyRequested(.text(textItem)):
            UIPasteboard.general.string = textItem.value

        case let .itemTapped(.button(buttonItem)):
            buttonItem.action()

        default:
            break
        }
    }

    // MARK: - Actions

    private func breakNextQuickSync() {
        ZMUserSession.shared()?.setBogusLastEventID()
    }

    private func sendDebugLogs() {
        DebugLogSender.sendLogsByEmail(message: "Send logs")
    }

    private func performQuickSync() {
        Task {
            guard let session = ZMUserSession.shared() else { return }
            await session.syncStatus?.performQuickSync()
        }
    }

    private func enrollE2EICertificate() {
        guard let session = ZMUserSession.shared() else { return }
        let e2eiCertificateUseCase = session.enrollE2eICertificate
        guard let rootViewController = AppDelegate.shared.window?.rootViewController else {
            return
        }
        let oauthUseCase = OAuthUseCase(rootViewController: rootViewController)

        guard
            let selfUser = selfUser,
            let userName = selfUser.name,
            let handle = selfUser.handle,
            let e2eiClientId = E2eIClientID(user: selfUser)
        else {
            return
        }

        Task {
            _ = try await e2eiCertificateUseCase?.invoke(e2eiClientId: e2eiClientId,
                                                         userName: userName,
                                                         userHandle: handle,
                                                         authenticate: oauthUseCase.invoke)
        }
    }

    private func checkRegisteredTokens() {
        guard
            let selfClient = selfClient,
            let clientID = selfClient.remoteIdentifier,
            let context = selfClient.managedObjectContext?.notificationContext
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
        return Bundle.main.shortVersionString ?? "Unknown"
    }

    private var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "Unknown"
    }

    private var buildNumber: String {
        return Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"
    }

    private var backendName: String {
        return BackendEnvironment.shared.title
    }

    private var backendDomain: String {
        return BackendInfo.domain ?? "None"
    }

    private var apiVersion: String {
        guard let version = BackendInfo.apiVersion else { return "None" }
        return String(describing: version.rawValue)
    }

    private var isFederationEnabled: String {
        return String(describing: BackendInfo.isFederationEnabled)
    }

    private var selfUser: ZMUser? {
        guard let session = ZMUserSession.shared() else { return nil }
        return ZMUser.selfUser(inUserSession: session)
    }

    private var selfClient: UserClient? {
        guard let session = ZMUserSession.shared() else { return nil }
        return session.selfUserClient
    }

    private func stopFederatingBella() {
        stopFederatingDomain(domain: "bella.wire.link")
    }

    private func stopFederatingFoma() {
        stopFederatingDomain(domain: "foma.wire.link")
    }

    private func stopBellaFomaFederating() {
        guard
            let selfClient = selfClient,
            let context = selfClient.managedObjectContext
        else {
            return
        }

        let manager = FederationTerminationManager(with: context)
        manager.handleFederationTerminationBetween("bella.wire.link", otherDomain: "foma.wire.link")
    }

    private func stopFederatingDomain(domain: String) {
        guard
            let selfClient = selfClient,
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
            return "Standard"

        case .voip:
            return "VoIP"

        }
    }

}

extension PushToken: CustomDebugStringConvertible {

    public var debugDescription: String {
        return """
        token: \(deviceTokenString),
        type: \(tokenType),
        transport: \(transportType)
        app: \(appIdentifier)
        """
    }

}
