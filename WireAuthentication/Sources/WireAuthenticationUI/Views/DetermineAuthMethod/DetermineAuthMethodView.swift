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
                    // TODO: [WPB-16045] Set error on `LabeledTextField` when supported.
                    LabeledTextField(
                        isMandatory: false,
                        placeholder: L10n.Authentication.Identity.Input.Field.placeholder,
                        title: L10n.Authentication.Identity.Input.Field.title,
                        string: $viewModel.emailOrSSOCode
                    )
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .wireTextStyle(.subline1)
                            .foregroundColor(ColorTheme.Base.error.color)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }

                Button(action: {
                    viewModel.submitEmailOrSSOCode()
                }, label: {
                    HStack {
                        // TODO: [WPB-15725] Implement custom loading indicator
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

}

@MainActor
public func makeDetermineAuthMethodViewPreview(
    emailOrSSOCode: String = "",
    isLoading: Bool = false,
    errorMessage: String? = nil
) -> some View {
    MockDependencies().makeDetermineAuthMethodView(
        emailOrSSOCode: emailOrSSOCode,
        isLoading: isLoading,
        errorMessage: errorMessage
    )
}

#Preview {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            makeDetermineAuthMethodViewPreview(
                emailOrSSOCode: "sam@wire.com",
                isLoading: false,
                errorMessage: "Some error message that is too long to fit on a single line"
            )
        }
}
