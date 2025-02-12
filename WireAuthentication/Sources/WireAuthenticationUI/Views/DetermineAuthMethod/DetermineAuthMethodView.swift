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
import WireDesign
import WireReusableUIComponents

package protocol DetermineAuthMethodBuilder {

    @MainActor var determineAuthMethodView: DetermineAuthMethodView { get }

}

package struct DetermineAuthMethodView: View {

    @StateObject var viewModel: DetermineAuthMethodViewModel

    let builder: any LoginViaEmailBuilder

    package init(
        viewModel: DetermineAuthMethodViewModel,
        builder: any LoginViaEmailBuilder
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.builder = builder
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
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: titleForAlert(alert),
                message: messageForAlert(alert),
                dismissButton: .default(
                    Text("OK"), // FIXME: Localize
                    action: { viewModel.didDismissAlert(alert: alert) }
                )
            )
        }
        .navigationDestination(for: Destination.self) {
            switch $0 {
            case let .login(email):
                builder.loginViaEmailView(email: email)
            case .loginOrRegister:
                Color.red
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    enum Destination: Hashable {

        case login(email: String)
        case loginOrRegister(email: String)

    }

    // MARK: - Private helpers

    private func titleForAlert(_ alert: DetermineAuthMethodViewModel.Alert) -> Text {
        // TODO: Localize
        switch alert {
        case .noInternet:
            Text("No internet")
        case .invalidResponse:
            Text("Error")
        case .unknownError:
            Text("Error")
        case .onPremLoginNotPossible(recovery: let recovery):
            Text("On prem not possible")
        }
    }

    private func messageForAlert(_ alert: DetermineAuthMethodViewModel.Alert) -> Text {
        // TODO: Localize
        switch alert {
        case .noInternet:
            Text("You are not connected to the internet.")
        case .invalidResponse:
            Text("Something went wrong")
        case .unknownError:
            Text("Something went wrong")
        case .onPremLoginNotPossible(recovery: let recovery):
            Text("Email is already registered on Wire Cloud.")
        }
    }

}

@MainActor
package func makeDetermineAuthMethodViewPreview(
    emailOrSSOCode: String = "",
    isLoading: Bool = false,
    alert: DetermineAuthMethodViewModel.Alert? = nil
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
