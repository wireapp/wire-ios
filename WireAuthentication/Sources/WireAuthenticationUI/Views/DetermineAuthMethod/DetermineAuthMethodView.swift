//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Combine
import SwiftUI
import WireAuthenticationAPI
import WireDesign
import WireReusableUIComponents

package protocol DetermineAuthMethodFactory {

    @MainActor var viewModel: DetermineAuthMethodViewModel { get }

    @MainActor
    func loginViaEmailFactory(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> any LoginViaEmailFactory

    @MainActor
    func noHistoryFactory(authenticationResult: AuthenticationResult) -> any NoHistoryFactory
}

package struct DetermineAuthMethodView: View {

    @StateObject var viewModel: DetermineAuthMethodViewModel

    private typealias Strings = L10n.Localizable.Authentication

    package init(factory: @autoclosure @escaping () -> any DetermineAuthMethodFactory) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                header
                message
                inputField
                submitButton
            }
            .padding()
            .setPreferredSize(navigationBarHidden: !viewModel.existsAnotherAccount)
        }
        .toolbar {
            if viewModel.existsAnotherAccount {
                ToolbarItem(placement: .topBarTrailing) {
                    dismissButton
                }
            }
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(Strings.Error.confirm, action: viewModel.onAlertDismiss)
            }
        )
        .navigationDestination(for: DetermineAuthMethodDestination.self) {
            destinationView(for: $0)
        }
        .fullScreenCover(item: $viewModel.modalDestination) {
            sheetView(for: $0)
                .presentationBackground(Color.black.opacity(0.7))
        }
        .interactiveDismissDisabled()
        .background(ColorTheme.Backgrounds.surface.color)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Views

    @ViewBuilder private var header: some View {
        HStack {
            Spacer()
                .frame(maxWidth: .infinity)
            if viewModel.isOnPremiseBackend {
                OnPremHeaderView(backendConfig: viewModel.backendInfo.backendConfig)
                    .foregroundColor(ColorTheme.Backgrounds.onBackground.color)
                    .frame(width: 164, height: 95)
            } else {
                Logo()
                    .foregroundColor(ColorTheme.Backgrounds.onBackground.color)
                    .frame(width: 164, height: 95)
            }

            Spacer()
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var message: some View {
        Text(Strings.Identity.Input.body)
            .multilineTextAlignment(.leading)
            .wireTextStyle(.body1)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing)
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledTextField(
                isMandatory: false,
                placeholder: Strings.Identity.Input.Field.placeholder,
                title: Strings.Identity.Input.Field.title,
                string: $viewModel.emailOrSSOCode
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .textContentType(.username)
            .keyboardType(.emailAddress)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitEmailOrSSOCode()
            }
        }, label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                }

                Text(Strings.Identity.Input.submit)
                    .lineLimit(nil)
            }
        })
        .wireButtonStyle(.primary)
        .disabled(viewModel.isNextButtonEnabled || viewModel.isLoading)
    }

    @ViewBuilder private var dismissButton: some View {
        Button {
            viewModel.exitFlow()
        } label: {
            Image(systemName: "xmark")
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destinationView(for destination: DetermineAuthMethodDestination) -> some View {
        switch destination {
        case let .login(
            email,
            didDetectDomainConflict,
            backendInfo
        ):
            LoginViaEmailView(factory: viewModel.factory.loginViaEmailFactory(
                email: email,
                canCreateAccount: false,
                didDetectDomainConflict: didDetectDomainConflict,
                backendInfo: backendInfo
            ))
        case let .loginOrRegister(
            email,
            didDetectDomainConflict,
            backendInfo
        ):
            LoginViaEmailView(factory: viewModel.factory.loginViaEmailFactory(
                email: email,
                canCreateAccount: true,
                didDetectDomainConflict: didDetectDomainConflict,
                backendInfo: backendInfo
            ))
        case let .noHistory(authenticationResult):
            NoHistoryView(factory: viewModel.factory.noHistoryFactory(authenticationResult: authenticationResult))
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: DetermineAuthMethodSheet) -> some View {
        switch sheet {
        case let .switchBackendConfirmation(
            email,
            backendInfo
        ):
            SwitchBackendConfirmation(backendConfig: backendInfo.backendConfig) { didConfirm in
                guard didConfirm else { return }
                Task {
                    await viewModel.switchBackend(
                        email: email,
                        backendInfo: backendInfo
                    )
                }
            }
        }
    }
}
