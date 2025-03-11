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

import SwiftUI
import WireAuthenticationAPI
import WireDesign
import WireReusableUIComponents

package protocol DetermineAuthMethodBuilder {

    @MainActor var determineAuthMethodView: DetermineAuthMethodView { get }

}

package struct DetermineAuthMethodView: View {

    package typealias Factory = LoginViaEmailBuilder & LoginViaSSOBuilder & SwitchBackendConfirmationBuilder

    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: DetermineAuthMethodViewModel

    let factory: any Factory

    package init(
        viewModel: DetermineAuthMethodViewModel,
        factory: any Factory
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.factory = factory
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Spacer()
                        .frame(maxWidth: .infinity)
                    Logo()
                        .foregroundColor(ColorTheme.Backgrounds.onBackground.color)
                        .frame(width: 164, height: 95)
                    Spacer()
                        .frame(maxWidth: .infinity)
                }

                Text(L10n.Authentication.Identity.Input.body)
                    .multilineTextAlignment(.leading)
                    .wireTextStyle(.body1)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing)

                VStack(alignment: .leading, spacing: 8) {
                    LabeledTextField(
                        isMandatory: false,
                        placeholder: L10n.Authentication.Identity.Input.Field.placeholder,
                        title: L10n.Authentication.Identity.Input.Field.title,
                        string: $viewModel.emailOrSSOCode
                    )
                    .autocapitalization(.none)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: {
                    Task {
                        await viewModel.submitEmailOrSSOCode()
                    }
                }, label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }

                        Text(L10n.Authentication.Identity.Input.submit)
                            .lineLimit(nil)
                    }
                })
                .wireButtonStyle(.primary)
                .disabled(viewModel.isNextButtonEnabled || viewModel.isLoading)
            }.padding()
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button {
                    // FIXME: What is needed here?
                    dismiss()
                } label: {
                    Text(L10n.Authentication.Error.confirm)
                }
            }
        )
        .navigationDestination(for: Destination.self) {
            switch $0 {
            case let .login(email, didDetectDomainConflict, backendMetadata):
                factory.loginViaEmailView(
                    email: email,
                    canCreateAccount: false,
                    didDetectDomainConflict: didDetectDomainConflict,
                    backendMetadata: backendMetadata
                )
            case let .loginOrRegister(email, backendMetadata):
                factory.loginViaEmailView(
                    email: email,
                    canCreateAccount: true,
                    didDetectDomainConflict: false,
                    backendMetadata: backendMetadata
                )
            }
        }
        .sheet(item: $viewModel.modalDestination, content: {
            switch $0 {
            case let .ssoLogin(url: ssoURL):
                factory.loginViaSSOView(ssoURL: ssoURL)
            case let .switchBackend(email: email, backendConfig: backendConfig):
                factory.switchBackendView(email: email, backendConfig: backendConfig)
            }
        })
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    package enum Destination: Hashable {

        case login(email: String, didDetectDomainConflict: Bool, backendMetadata: BackendMetadata)
        case loginOrRegister(email: String, backendMetadata: BackendMetadata)

    }

}

extension Alert {

    private typealias Title = L10n.Authentication.Error.Title
    private typealias Message = L10n.Authentication.Error.Message

    static let invalidSSOLink = Alert(title: Title.invalidSsoLink, message: Message.invalidSsoLink)
    static let incorrectSSOCode = Alert(title: Title.incorrectSsoCode, message: Title.incorrectSsoCode)

}

@MainActor
func makeDetermineAuthMethodViewPreview(
    emailOrSSOCode: String = "",
    isLoading: Bool = false,
    alert: Alert? = nil
) -> some View {
    MockDependencies().makeDetermineAuthMethodView(
        emailOrSSOCode: emailOrSSOCode,
        isLoading: isLoading,
        alert: alert
    )
}

#Preview {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            makeDetermineAuthMethodViewPreview(
                emailOrSSOCode: "user@wire.com",
                isLoading: false,
                alert: .unknownError
            )
        }
}
