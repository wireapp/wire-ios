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
import UIKit

#if canImport(WireIosShared)
import WireIosShared
#endif

// TODO: Remove this file with the temporary WireIosShared login probe once real shared ViewModel wiring starts.
struct KMPLoginIdentifierDebugProbeReport {
    let title: String
    let details: String
}

struct KMPLoginIdentifierDebugProbeInput {
    let userIdentifier: String
    let password: String
    let secondFactorCode: String?
}

@MainActor
final class KMPLoginIdentifierDebugProbeRunner {

    func run() async -> KMPLoginIdentifierDebugProbeReport {
        await run(
            input: KMPLoginIdentifierDebugProbeInput(
                userIdentifier: "invalid-login-probe@wire.com",
                password: "invalid-password",
                secondFactorCode: nil
            )
        )
    }

    func run(input: KMPLoginIdentifierDebugProbeInput) async -> KMPLoginIdentifierDebugProbeReport {
        #if canImport(WireIosShared)
        await runWireIosSharedProbe(input: input)
        #else
        KMPLoginIdentifierDebugProbeReport(
            title: "WireIosShared unavailable",
            details: """
            WireIosShared is not linked into this target yet.

            Expected framework:
            shared/export-ios/build/bin/iosSimulatorArm64/debugFramework/WireIosShared.framework
            """
        )
        #endif
    }

    #if canImport(WireIosShared)
    private func runWireIosSharedProbe(
        input: KMPLoginIdentifierDebugProbeInput
    ) async -> KMPLoginIdentifierDebugProbeReport {
        let serverLinks = makeDefaultServerLinks()
        let graph = WireIosSharedGraphKt.createWireIosSharedProbe(
            defaultServerLinks: serverLinks,
            runtimeConfig: makeCleanInstallRuntimeConfig(serverLinks: serverLinks)
        )
        defer {
            graph.close()
        }

        let source = LoginEmailKMPViewModelSource(
            viewModel: graph.loginEmailViewModel
        )
        let adapter = KMPViewModelAdapter(source: source)

        var timeline = [String]()
        appendState("Initial", adapter.state, to: &timeline)

        adapter.send(
            LoginEmailIntentUserIdentifierChanged(
                value: input.userIdentifier
            )
        )
        await waitUntil(timeout: 3) {
            adapter.state.userIdentifier == input.userIdentifier
        }
        appendState("After identifier accepted", adapter.state, to: &timeline)

        adapter.send(
            LoginEmailIntentPasswordChanged(
                value: input.password
            )
        )
        await waitUntil(timeout: 3) {
            !adapter.state.password.isEmpty
        }
        appendState("After password accepted", adapter.state, to: &timeline)

        adapter.send(LoginEmailIntentSubmitLogin(usernameAllowed: true))
        await waitUntil(timeout: 3) {
            adapter.state.flowState is LoginEmailFlowStateLoading
        }
        appendState("After submit accepted", adapter.state, to: &timeline)

        await waitUntil(timeout: 20) {
            adapter.effect != nil || !(adapter.state.flowState is LoginEmailFlowStateLoading)
        }

        appendState("After terminal wait", adapter.state, to: &timeline)

        if adapter.state.secondFactorVerificationCode.isCodeInputNecessary {
            if let secondFactorCode = input.secondFactorCode, !secondFactorCode.isEmpty {
                adapter.send(LoginEmailIntentSecondFactorCodeChanged(value: secondFactorCode))
                await waitUntil(timeout: 3) {
                    adapter.state.secondFactorVerificationCode.code == secondFactorCode
                }
                appendState("After second factor code accepted", adapter.state, to: &timeline)

                adapter.send(LoginEmailIntentSubmitLogin(usernameAllowed: true))
                await waitUntil(timeout: 3) {
                    adapter.state.flowState is LoginEmailFlowStateLoading
                }
                appendState("After second factor submit accepted", adapter.state, to: &timeline)

                await waitUntil(timeout: 30) {
                    adapter.effect != nil || !(adapter.state.flowState is LoginEmailFlowStateLoading)
                }
                appendState("After second factor terminal wait", adapter.state, to: &timeline)
            } else {
                timeline.append("Second factor required but no code was provided.")
            }
        }

        let effect = adapter.effect.map(describe) ?? "none"

        adapter.close()

        return KMPLoginIdentifierDebugProbeReport(
            title: "WireIosShared login email probe succeeded",
            details: """
            Timeline:
            \(timeline.joined(separator: "\n\n"))

            Effect:
            \(effect)
            """
        )
    }

    private func appendState(
        _ label: String,
        _ state: LoginEmailState,
        to timeline: inout [String]
    ) {
        timeline.append(
            """
            \(label):
            \(describe(state))
            """
        )
    }

    private func waitUntil(
        timeout: TimeInterval,
        condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func makeCleanInstallRuntimeConfig(
        serverLinks: LoginServerLinks
    ) -> IosKaliumRuntimeConfig {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("wire-ios-shared-probe", isDirectory: true)
        try? FileManager.default.removeItem(at: rootURL)
        try? FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let rootPath = rootURL.path

        return WireIosSharedConfigKt.createIosKaliumRuntimeConfig(
            appGroupRootPath: rootPath,
            sqlDelightRootPath: "\(rootPath)/sqldelight",
            backendDomain: "wire.com",
            serverLinks: serverLinks,
            migrationMode: .cleaninstallprobe
        )
    }

    private func makeDefaultServerLinks() -> LoginServerLinks {
        LoginServerLinks(
            api: "https://prod-nginz-https.wire.com",
            accounts: "https://account.wire.com",
            webSocket: "wss://prod-nginz-ssl.wire.com",
            blackList: "https://clientblacklist.wire.com/prod",
            teams: "https://teams.wire.com",
            website: "https://wire.com",
            title: "Wire",
            isOnPremises: false,
            apiProxy: nil
        )
    }

    private func describe(_ state: LoginEmailState) -> String {
        """
        userIdentifier=\(state.userIdentifier)
        passwordEmpty=\(state.password.isEmpty)
        loginEnabled=\(state.loginEnabled)
        userIdentifierEnabled=\(state.userIdentifierEnabled)
        flowState=\(describe(state.flowState))
        secondFactorRequired=\(state.secondFactorVerificationCode.isCodeInputNecessary)
        secondFactorInvalid=\(state.secondFactorVerificationCode.isCurrentCodeInvalid)
        """
    }

    private func describe(_ flowState: LoginEmailFlowState) -> String {
        switch flowState {
        case is LoginEmailFlowStateDefault:
            "default"
        case is LoginEmailFlowStateLoading:
            "loading"
        case let error as LoginEmailFlowStateError:
            "error(\(describe(error.type)))"
        case let success as LoginEmailFlowStateSuccess:
            "success(initialSyncCompleted=\(success.initialSyncCompleted), isE2EIRequired=\(success.isE2EIRequired))"
        case is LoginEmailFlowStateCanceled:
            "canceled"
        default:
            String(describing: flowState)
        }
    }

    private func describe(_ error: LoginEmailError) -> String {
        switch error {
        case is LoginEmailErrorInvalidCredentials:
            "invalidCredentials"
        case is LoginEmailErrorInvalidUserIdentifier:
            "invalidUserIdentifier"
        case is LoginEmailErrorTooManyDevices:
            "tooManyDevices"
        case is LoginEmailErrorRequestSecondFactorWithHandle:
            "requestSecondFactorWithHandle"
        case let generic as LoginEmailErrorGeneric:
            "generic(\(generic.message ?? "nil"))"
        case is LoginEmailErrorServerVersionNotSupported:
            "serverVersionNotSupported"
        case is LoginEmailErrorClientUpdateRequired:
            "clientUpdateRequired"
        case is LoginEmailErrorAccountPendingActivation:
            "accountPendingActivation"
        case is LoginEmailErrorAccountSuspended:
            "accountSuspended"
        case is LoginEmailErrorPasswordNeededToRegisterClient:
            "passwordNeededToRegisterClient"
        case is LoginEmailErrorProxyAuthenticationFailed:
            "proxyAuthenticationFailed"
        case is LoginEmailErrorUserAlreadyExists:
            "userAlreadyExists"
        default:
            String(describing: error)
        }
    }

    private func describe(_ effect: LoginEmailEffect) -> String {
        switch effect {
        case let succeeded as LoginEmailEffectLoginSucceeded:
            "loginSucceeded(initialSyncCompleted=\(succeeded.initialSyncCompleted), isE2EIRequired=\(succeeded.isE2EIRequired))"
        case is LoginEmailEffectRemoveDeviceNeeded:
            "removeDeviceNeeded"
        default:
            String(describing: effect)
        }
    }
    #endif
}

extension DebugActions {

    static func askKMPLoginProbeInput(
        _ callback: @escaping (KMPLoginIdentifierDebugProbeInput) -> Void
    ) {
        guard let controllerToPresentOver = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        else { return }

        let controller = UIAlertController(
            title: "KMP login email probe",
            message: "Use clean-install temp storage. 2FA code is optional.",
            preferredStyle: .alert
        )

        controller.addTextField { textField in
            textField.placeholder = "Email or handle"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        controller.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        controller.addTextField { textField in
            textField.placeholder = "2FA code (optional)"
            textField.keyboardType = .numberPad
        }

        let runAction = UIAlertAction(title: "Run", style: .default) { [controller] _ in
            let fields = controller.textFields ?? []
            let userIdentifier = fields.indices.contains(0) ? fields[0].text?.trim() ?? "" : ""
            let password = fields.indices.contains(1) ? fields[1].text ?? "" : ""
            let secondFactorCode = fields.indices.contains(2) ? fields[2].text?.trim() : nil

            callback(
                KMPLoginIdentifierDebugProbeInput(
                    userIdentifier: userIdentifier,
                    password: password,
                    secondFactorCode: secondFactorCode?.isEmpty == false ? secondFactorCode : nil
                )
            )
        }

        controller.addAction(.cancel {})
        controller.addAction(runAction)
        controllerToPresentOver.present(controller, animated: true, completion: nil)
    }

}

#if canImport(WireIosShared)
@MainActor
private final class LoginEmailKMPViewModelSource: KMPViewModelSource {
    typealias State = LoginEmailState
    typealias Effect = LoginEmailEffect
    typealias Intent = LoginEmailIntent

    private let viewModel: LoginEmailIosViewModel

    var currentState: LoginEmailState {
        viewModel.currentState
    }

    init(viewModel: LoginEmailIosViewModel) {
        self.viewModel = viewModel
    }

    func observeState(
        _ observer: @escaping @MainActor (LoginEmailState) -> Void
    ) -> KMPViewModelObservation {
        KMPLoginIdentifierObservation(
            closeable: viewModel.observeState { state in
                Task { @MainActor in
                    observer(state)
                }
            }
        )
    }

    func observeEffect(
        _ observer: @escaping @MainActor (LoginEmailEffect) -> Void
    ) -> KMPViewModelObservation {
        KMPLoginIdentifierObservation(
            closeable: viewModel.observeEffect { effect in
                Task { @MainActor in
                    observer(effect)
                }
            }
        )
    }

    func send(_ intent: LoginEmailIntent) {
        viewModel.sendIntent(intent: intent)
    }

    func close() {
        viewModel.close()
    }
}

private final class KMPLoginIdentifierObservation: KMPViewModelObservation {
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
#endif
