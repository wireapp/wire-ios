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

package protocol VerificationCodeBuilder {

    @MainActor
    func verificationCodeView(
        email: String,
        password: String
    ) -> VerificationCodeView

}

package struct VerificationCodeView: View {

    // MARK: - Constants

    private enum Constants {
        static let backgroundCornerRadius: CGFloat = 16
        static let numberOfDigits = 6
    }

    @StateObject private var viewModel: VerificationCodeViewModel

    @FocusState private var focusedIndex: Int?

    private var isConfirmButtonDisabled: Bool {
        viewModel.code.contains { $0.isEmpty }
    }

    package init(viewModel: VerificationCodeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    package var body: some View {
        VStack(spacing: 20) {
            Text(L10n.VerificationCode.title)
                .font(.textStyle(.h2))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            Text(L10n.VerificationCode.message(viewModel.email))
                .wireTextStyle(.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primaryText)

            verificationCodeView

            Button(action: {
                Task.detached { await viewModel.confirm() }
            }, label: {
                Text(L10n.VerificationCode.confirm)
            })
            .wireButtonStyle(.primary)
            .padding(.horizontal)
            .disabled(isConfirmButtonDisabled)

            Button(action: {
                Task.detached { await viewModel.resend() }
            }, label: {
                Text(L10n.VerificationCode.resendCode)
            })
            .wireButtonStyle(.link)
            Spacer()
        }
        .padding()
        .background(ColorTheme.Backgrounds.surface.color)
        .cornerRadius(Constants.backgroundCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.backgroundCornerRadius)
                .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
        )
    }

    private var verificationCodeView: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< Constants.numberOfDigits, id: \.self) { index in
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
                    .font(.textStyle(.h2))
                    .keyboardType(.numberPad)
                    .foregroundColor(.primary)
                    .focused($focusedIndex, equals: index)
                    .onChange(of: viewModel.code[index]) { newValue in
                        handleInput(newValue, index: index)
                    }
            }
        }
        .onAppear {
            focusedIndex = 0
        }
    }

    private func handleInput(_ newValue: String, index: Int) {
        if let intValue = Int(newValue.prefix(1)), (0 ... 9).contains(intValue) {
            viewModel.code[index] = String(intValue)
        } else {
            viewModel.code[index] = ""
        }

        if !viewModel.code[index].isEmpty {
            if index < Constants.numberOfDigits - 1 {
                focusedIndex = index + 1
            } else {
                focusedIndex = nil
            }
        } else {
            if index > 0 {
                focusedIndex = index - 1
            }
        }
    }
}

#Preview("Empty code") {
    VerificationCodeView(
        viewModel: VerificationCodeViewModel(
            email: "name.name@mail.com",
            password: "pasword"
        )
    )
}

#Preview("Not empty code") {
    VerificationCodeView(
        viewModel: VerificationCodeViewModel(
            email: "name.name@mail.com",
            password: "pasword",
            code: ["1", "2", "3", "4", "5", ""]
        )
    )
}

#Preview {
    BackgroundView()
        .overlay {
            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: .infinity)
                VerificationCodeView(
                    viewModel: VerificationCodeViewModel(
                        email: "name.name@mail.com",
                        password: "pasword"
                    )
                )
            }
        }
}
