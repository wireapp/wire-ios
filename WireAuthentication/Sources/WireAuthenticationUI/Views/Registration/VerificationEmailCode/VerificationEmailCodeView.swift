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
import WireLocators

package struct VerificationEmailCodeView: View {

    @StateObject private var viewModel: VerificationEmailCodeViewModel
    @FocusState private var focusedIndex: Int?

    private typealias Strings = L10n.Localizable.CreatePersonalAccount
    private typealias Labels = L10n.Accessibility.CreatePersonalAccount

    package init(
        factory: @autoclosure @escaping () -> VerificationEmailCodeFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(Strings.VerificationCode.message(viewModel.email))
                    .font(for: .body1)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color.primaryText)

                verificationCodeView

                Button(action: {
                    Task { await viewModel.confirm() }
                }, label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }

                        Text(Strings.VerificationCode.confirm)
                    }
                })
                .accessibilityIdentifier(Locators.VerificationCodePage.confirmButton.rawValue)
                .wireButtonStyle(.primary)
                .padding(.horizontal)
                .disabled(viewModel.isConfirmButtonDisabled)

                Button(action: {
                    Task.detached { await viewModel.requestVerificationCode() }
                }, label: {
                    Text(Strings.VerificationCode.resendCode)
                })
                .wireButtonStyle(.link)
                .disabled(viewModel.isResending)
            }
            .background(ColorTheme.Backgrounds.surface.color)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .setPreferredSize(navigationBarHidden: false)
            .customBackButton()
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in
                    Button(L10n.Localizable.Authentication.Error.confirm, action: {})
                }
            )
            .onAppear {
                viewModel.trackReachedVerificationCodeIfNeeded()
            }
        }
    }

    private var verificationCodeView: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< viewModel.numberOfDigits, id: \.self) { index in
                TextField("", text: $viewModel.code[index])
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                focusedIndex == index ? Color.primaryButtonBackground : Color.secondaryButtonBorder,
                                lineWidth: 1
                            )
                    )
                    .multilineTextAlignment(.center)
                    .font(for: .h2)
                    .keyboardType(.numberPad)
                    .foregroundColor(.primary)
                    .focused($focusedIndex, equals: index)
                    .accessibilityIdentifier(Locators.VerificationCodePage.verificationCodeTextField.rawValue)
                    .onChange(of: viewModel.code[index]) { newValue in
                        focusedIndex = viewModel.handleInputReturningFocus(newValue, at: index)
                    }
            }
        }
        .onAppear {
            focusedIndex = 0
        }
    }

}
