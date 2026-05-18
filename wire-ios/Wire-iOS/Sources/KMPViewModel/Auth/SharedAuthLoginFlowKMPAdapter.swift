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
import WireAuthenticationAPI
import WireLogging
import WireNetwork

#if canImport(WireIosShared)
import WireIosShared

@MainActor
final class SharedAuthLoginFlowKMPGraph {

    private let graph: WireIosSharedGraph

    init(
        environment: BackendEnvironment2,
        storageRootURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("wire-ios-shared-auth-flow", isDirectory: true)
    ) throws {
        try FileManager.default.createDirectory(
            at: storageRootURL,
            withIntermediateDirectories: true
        )

        let serverLinks = LoginServerLinks(environment: environment)
        let runtimeConfig = WireIosSharedConfigKt.createIosKaliumRuntimeConfig(
            appGroupRootPath: storageRootURL.path,
            sqlDelightRootPath: storageRootURL.appendingPathComponent("sqldelight", isDirectory: true).path,
            backendDomain: environment.config.endpoints.restAPIURL.host ?? "wire.com",
            serverLinks: serverLinks,
            migrationMode: .cleaninstallprobe
        )

        self.graph = WireIosSharedGraphKt.createWireIosSharedAuthGraph(
            defaultServerLinks: serverLinks,
            runtimeConfig: runtimeConfig
        )

        WireLogger.authentication.info(
            "Using shared Kalium auth flow",
            attributes: .safePublic
        )
    }

    func makeAuthLoginFlowViewModel() -> KMPViewModelAdapter<
        AuthLoginFlowState,
        AuthLoginFlowEffect,
        AuthLoginFlowIntent
    > {
        KMPViewModelAdapter(
            source: SharedAuthLoginFlowKMPViewModelSource(
                viewModel: graph.authLoginFlowViewModel
            )
        )
    }

    func makeSharedAuthLoginFlow() -> any SharedAuthLoginFlowManaging {
        SharedAuthLoginFlowManagingAdapter(
            graph: self,
            viewModel: graph.authLoginFlowViewModel
        )
    }

    func close() {
        graph.close()
    }
}

@MainActor
private final class SharedAuthLoginFlowManagingAdapter: SharedAuthLoginFlowManaging {

    private let graph: SharedAuthLoginFlowKMPGraph
    private let viewModel: AuthLoginFlowIosViewModel

    var currentState: SharedAuthLoginFlowState {
        viewModel.currentState.sharedState
    }

    init(
        graph: SharedAuthLoginFlowKMPGraph,
        viewModel: AuthLoginFlowIosViewModel
    ) {
        self.graph = graph
        self.viewModel = viewModel
    }

    func observeState(
        _ observer: @escaping @MainActor (SharedAuthLoginFlowState) -> Void
    ) -> any SharedAuthLoginFlowObservation {
        SharedAuthLoginFlowObservationAdapter(
            closeable: viewModel.observeState { state in
                Task { @MainActor in
                    observer(state.sharedState)
                }
            }
        )
    }

    func observeEffect(
        _ observer: @escaping @MainActor (SharedAuthLoginFlowEffect) -> Void
    ) -> any SharedAuthLoginFlowObservation {
        SharedAuthLoginFlowObservationAdapter(
            closeable: viewModel.observeEffect { effect in
                guard let sharedEffect = effect.sharedEffect else { return }
                Task { @MainActor in
                    observer(sharedEffect)
                }
            }
        )
    }

    func send(_ intent: SharedAuthLoginFlowIntent) {
        viewModel.sendIntent(intent: intent.kmpIntent)
    }

    func close() {
        viewModel.close()
        graph.close()
    }
}

@MainActor
private final class SharedAuthLoginFlowObservationAdapter: SharedAuthLoginFlowObservation {
    private let closeable: IosCloseable
    private var isCancelled = false

    init(closeable: IosCloseable) {
        self.closeable = closeable
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        closeable.close()
    }
}

@MainActor
private final class SharedAuthLoginFlowKMPViewModelSource: KMPViewModelSource {
    typealias State = AuthLoginFlowState
    typealias Effect = AuthLoginFlowEffect
    typealias Intent = AuthLoginFlowIntent

    private let viewModel: AuthLoginFlowIosViewModel

    var currentState: AuthLoginFlowState {
        viewModel.currentState
    }

    init(viewModel: AuthLoginFlowIosViewModel) {
        self.viewModel = viewModel
    }

    func observeState(
        _ observer: @escaping @MainActor (AuthLoginFlowState) -> Void
    ) -> KMPViewModelObservation {
        SharedAuthLoginFlowKMPObservation(
            closeable: viewModel.observeState { state in
                Task { @MainActor in
                    observer(state)
                }
            }
        )
    }

    func observeEffect(
        _ observer: @escaping @MainActor (AuthLoginFlowEffect) -> Void
    ) -> KMPViewModelObservation {
        SharedAuthLoginFlowKMPObservation(
            closeable: viewModel.observeEffect { effect in
                Task { @MainActor in
                    observer(effect)
                }
            }
        )
    }

    func send(_ intent: AuthLoginFlowIntent) {
        viewModel.sendIntent(intent: intent)
    }

    func close() {
        viewModel.close()
    }
}

@MainActor
private final class SharedAuthLoginFlowKMPObservation: KMPViewModelObservation {
    private let closeable: IosCloseable
    private var isCancelled = false

    init(closeable: IosCloseable) {
        self.closeable = closeable
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        closeable.close()
    }
}

private extension LoginServerLinks {

    convenience init(environment: BackendEnvironment2) {
        let endpoints = environment.config.endpoints

        self.init(
            api: endpoints.restAPIURL.absoluteString,
            accounts: endpoints.accountsURL.absoluteString,
            webSocket: endpoints.websocketURL.absoluteString,
            blackList: endpoints.blacklistURL.absoluteString,
            teams: endpoints.teamsURL.absoluteString,
            website: endpoints.websiteURL.absoluteString,
            title: environment.title,
            isOnPremises: environment.environmentType != .default,
            apiProxy: nil
        )
    }
}

private extension AuthLoginFlowState {

    var sharedState: SharedAuthLoginFlowState {
        SharedAuthLoginFlowState(
            step: step.sharedStep,
            identifier: identifier,
            password: password,
            secondFactorCode: secondFactorCode,
            secondFactorEmail: secondFactorEmail,
            ssoCode: ssoCode,
            canSubmitIdentifier: canSubmitIdentifier,
            canSubmitCredentials: canSubmitCredentials,
            canSubmitSecondFactor: canSubmitSecondFactor,
            canSubmitSsoCode: canSubmitSsoCode,
            isLoading: isLoading,
            error: error?.sharedError
        )
    }
}

private extension AuthLoginFlowStep {

    var sharedStep: SharedAuthLoginFlowStep {
        switch self {
        case is AuthLoginFlowStepIdentifierEntry:
            .identifierEntry
        case is AuthLoginFlowStepEmailCredentialsEntry:
            .emailCredentialsEntry
        case is AuthLoginFlowStepSecondFactorEntry:
            .secondFactorEntry
        case let success as AuthLoginFlowStepSuccess:
            .success(
                initialSyncCompleted: success.initialSyncCompleted,
                isE2EIRequired: success.isE2EIRequired
            )
        default:
            .identifierEntry
        }
    }
}

private extension AuthLoginFlowError {

    var sharedError: SharedAuthLoginFlowError {
        switch self {
        case is AuthLoginFlowErrorInvalidIdentifier:
            .invalidIdentifier
        case is AuthLoginFlowErrorInvalidCredentials:
            .invalidCredentials
        case is AuthLoginFlowErrorInvalidSecondFactorCode:
            .invalidSecondFactorCode
        case is AuthLoginFlowErrorTooManyDevices:
            .tooManyDevices
        case let generic as AuthLoginFlowErrorGeneric:
            .generic(message: generic.message)
        default:
            .generic(message: nil)
        }
    }
}

private extension AuthLoginFlowEffect {

    var sharedEffect: SharedAuthLoginFlowEffect? {
        switch self {
        case let openSsoURL as AuthLoginFlowEffectOpenSsoUrl:
            guard let url = URL(string: openSsoURL.url) else { return nil }
            return .openSsoURL(
                url: url,
                userIdentifier: openSsoURL.userIdentifier
            )
        case let loginSucceeded as AuthLoginFlowEffectLoginSucceeded:
            return .loginSucceeded(payload: loginSucceeded.payload.sharedPayload)
        default:
            return nil
        }
    }
}

private extension AuthLoginSuccessPayload {

    var sharedPayload: SharedAuthLoginSuccessPayload {
        SharedAuthLoginSuccessPayload(
            userIdValue: userIdValue,
            userIdDomain: userIdDomain,
            accessTokenValue: accessTokenValue,
            accessTokenType: accessTokenType,
            accessTokenExpiresInSeconds: accessTokenExpiresInSeconds?.intValue,
            refreshTokenValue: refreshTokenValue,
            refreshTokenCookieName: refreshTokenCookieName,
            refreshTokenCookieDomain: refreshTokenCookieDomain,
            refreshTokenCookiePath: refreshTokenCookiePath,
            refreshTokenCookieSecure: refreshTokenCookieSecure,
            refreshTokenCookieHttpOnly: refreshTokenCookieHttpOnly,
            email: email,
            password: password,
            secondFactorCode: secondFactorCode,
            initialSyncCompleted: initialSyncCompleted,
            isE2EIRequired: isE2EIRequired,
            clientId: clientId
        )
    }
}

private extension SharedAuthLoginFlowIntent {

    var kmpIntent: AuthLoginFlowIntent {
        switch self {
        case let .identifierChanged(value):
            AuthLoginFlowIntentIdentifierChanged(value: value)
        case let .passwordChanged(value):
            AuthLoginFlowIntentPasswordChanged(value: value)
        case let .secondFactorCodeChanged(value):
            AuthLoginFlowIntentSecondFactorCodeChanged(value: value)
        case let .ssoCodeChanged(value):
            AuthLoginFlowIntentSsoCodeChanged(value: value)
        case .submitIdentifier:
            AuthLoginFlowIntentSubmitIdentifier.shared
        case let .submitCredentials(usernameAllowed):
            AuthLoginFlowIntentSubmitCredentials(usernameAllowed: usernameAllowed)
        case let .submitSecondFactor(usernameAllowed):
            AuthLoginFlowIntentSubmitSecondFactor(usernameAllowed: usernameAllowed)
        case .submitSsoCode:
            AuthLoginFlowIntentSubmitSsoCode.shared
        case .back:
            AuthLoginFlowIntentBack.shared
        case .cancel:
            AuthLoginFlowIntentCancel.shared
        case .clearError:
            AuthLoginFlowIntentClearError.shared
        }
    }
}
#endif
