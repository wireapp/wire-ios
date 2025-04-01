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

    @MainActor
    func determineAuthMethodView(
        backendInfo: BackendInfo
    ) -> DetermineAuthMethodView

}

package struct DetermineAuthMethodView: View {

    package typealias Factory = DetermineAuthMethodBuilder &
        LoginViaEmailBuilder &
        NoHistoryViewBuilder

    @StateObject var viewModel: DetermineAuthMethodViewModel

    package init(factory: @autoclosure @escaping () -> any DetermineAuthMethodFactory) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
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
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
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
            }
            .padding()
            .setPreferredSize(navigationBarHidden: !viewModel.existsAnotherAccount)
        }
        .toolbar {
            if viewModel.existsAnotherAccount {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.exitFlow()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(L10n.Authentication.Error.confirm, action: viewModel.onAlertDismiss)
            }
        )
        .navigationDestination(for: Destination.self) {
            switch $0 {
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
        .sheet(
            item: $viewModel.modalDestination,
            content: {
                switch $0 {
                case let .switchBackendConfirmation(
                    email,
                    backendInfo
                ):
                    if #available(iOS 16.4, *) {
                        SwitchBackendConfirmation(backendConfig: backendInfo.backendConfig) { didConfirm in
                            guard didConfirm else { return }
                            Task {
                                await viewModel.switchBackend(
                                    email: email,
                                    backendInfo: backendInfo
                                )
                            }
                        }.presentationBackground(Color.black.opacity(0.7))
                    } else {
                        SwitchBackendConfirmation(backendConfig: backendInfo.backendConfig) { didConfirm in
                            guard didConfirm else { return }
                            Task {
                                await viewModel.switchBackend(
                                    email: email,
                                    backendInfo: backendInfo
                                )
                            }
                        }.background(TransparentBackgroundView())
                    }
                }
            }
        )
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    package enum Destination: Hashable {

        case login(
            email: String?,
            didDetectDomainConflict: Bool,
            backendInfo: BackendInfo
        )
        case loginOrRegister(
            email: String,
            didDetectDomainConflict: Bool,
            backendInfo: BackendInfo
        )
        case noHistory(AuthenticationResult)
    }

}

extension Alert {

    private typealias Title = L10n.Authentication.Error.Title
    private typealias Message = L10n.Authentication.Error.Message

    static let invalidSSOLink = Alert(title: Title.ssoLoginFailed, message: Message.ssoLoginFailed)
    static let incorrectSSOCode = Alert(title: Title.incorrectSsoCode, message: Message.incorrectSsoCode)

}

//@MainActor
//func makeDetermineAuthMethodViewPreview(
//    emailOrSSOCode: String = "",
//    existsAnotherAccount: Bool = false,
//    isLoading: Bool = false,
//    alert: Alert? = nil
//) -> some View {
//    MockDependencies().makeDetermineAuthMethodView(
//        emailOrSSOCode: emailOrSSOCode,
//        existsAnotherAccount: existsAnotherAccount,
//        isLoading: isLoading,
//        alert: alert
//    )
//}
//
//#Preview("can't exit flow") {
//    BackgroundView()
//        .sheet(isPresented: .constant(true)) {
//            NavigationStack {
//                makeDetermineAuthMethodViewPreview(
//                    emailOrSSOCode: "user@wire.com",
//                    existsAnotherAccount: false,
//                    isLoading: false,
//                    alert: nil
//                )
//            }
//        }
//}
//
//#Preview("can exit flow") {
//    BackgroundView()
//        .sheet(isPresented: .constant(true)) {
//            NavigationStack {
//                makeDetermineAuthMethodViewPreview(
//                    emailOrSSOCode: "user@wire.com",
//                    existsAnotherAccount: true,
//                    isLoading: false,
//                    alert: nil
//                )
//            }
//        }
//}
//
private struct TransparentBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        InnerView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            superview?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        }

    }
}
