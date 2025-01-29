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

package struct VerificationCodeView: View {

    @State private var code: [String]
    @FocusState private var focusedIndex: Int?

    private let receiver: String
    private let onConfirm: ([String]) -> Void
    private let onResend: () -> Void

    private var isConfirmButtonDisabled: Bool {
        code.contains { $0.isEmpty }
    }

    package init(
        initialCode: [String] = Array(repeating: "", count: 6),
        receiver: String,
        onConfirm: @escaping ([String]) -> Void,
        onResend: @escaping () -> Void
    ) {
        self._code = State(initialValue: initialCode)
        self.receiver = receiver
        self.onConfirm = onConfirm
        self.onResend = onResend
    }

    package var body: some View {
        VStack(spacing: 20) {
            Text(L10n.VerificationCode.title)
                .font(.textStyle(.h2))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            Text(L10n.VerificationCode.message(receiver))
                .wireTextStyle(.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primaryText)

            verificationCodeView

            Button(action: {
                onConfirm(code)
            }, label: {
                Text(L10n.VerificationCode.confirm)
            })
            .wireButtonStyle(.primary)
            .padding(.horizontal)
            .disabled(isConfirmButtonDisabled)

            Button(action: {
                onResend()
            }, label: {
                Text(L10n.VerificationCode.resendCode)
            })
            .wireButtonStyle(.link)
            Spacer()
        }
        .padding()
        .background(ColorTheme.Backgrounds.surface.color)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
        )
    }

    private var verificationCodeView: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                TextField("", text: $code[index])
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
                    .onChange(of: code[index]) { newValue in
                        handleInput(newValue, index: index)
                    }
            }
        }
        .onAppear {
            focusedIndex = 0
        }
    }

    private func handleInput(_ newValue: String, index: Int) {
        if let intValue = Int(newValue.prefix(1)), (0...9).contains(intValue) {
            code[index] = String(intValue)
        } else {
            code[index] = ""
        }

        if !code[index].isEmpty {
            if index < 5 {
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
        receiver: "name.name@mail.com",
        onConfirm: { _ in },
        onResend: {}
    )
}

#Preview("Not empty code") {
    VerificationCodeView(
        initialCode: ["1", "2", "3", "4", "5", ""],
        receiver: "name.name@mail.com",
        onConfirm: { _ in },
        onResend: {}
    )
}

#Preview {
    BackgroundView()
        .overlay {
            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: .infinity)
                VerificationCodeView(
                    receiver: "name.name@mail.com",
                    onConfirm: { _ in },
                    onResend: {}
                )
            }
        }
}
