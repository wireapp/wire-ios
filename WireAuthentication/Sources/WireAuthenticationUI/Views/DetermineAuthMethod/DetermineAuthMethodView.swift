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
import WireFoundation
import WireReusableUIComponents

public protocol DetermineAuthMethodBuilder {

    @MainActor var determineAuthMethodView: DetermineAuthMethodView { get }

}

public struct DetermineAuthMethodView: View {

    @ObservedObject var viewModel: DetermineAuthMethodViewModel

    let builder: any LoginViaEmailBuilder

    public init(
        viewModel: DetermineAuthMethodViewModel,
        builder: any LoginViaEmailBuilder
    ) {
        self.viewModel = viewModel
        self.builder = builder
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                Logo()
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
            LabeledTextField(
                isMandatory: false,
                placeholder: L10n.Authentication.Identity.Input.Field.placeholder,
                title: L10n.Authentication.Identity.Input.Field.title,
                string: $viewModel.emailOrSSOCode
            )
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                viewModel.submitEmailOrSSOCode()
            }, label: {
                Text(L10n.Authentication.Identity.Input.submit)
                    .lineLimit(nil)
            })
            .wireButtonStyle(.primary)
            .disabled(viewModel.isNextButtonEnabled)
        }
        .padding()
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

#Preview {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().determineAuthMethodView
        }
}
