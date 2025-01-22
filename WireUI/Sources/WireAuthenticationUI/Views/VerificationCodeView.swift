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

public struct VerificationCodeView: View {

    @State private var code: [String]
    @FocusState private var focusedIndex: Int?

    private let receiver: String
    private let onConfirm: ([String]) -> Void
    private let onResend: () -> Void

    public init(
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

    public var body: some View {
        VStack(spacing: 20) {
            Text(L10n.VerificationCode.title)
                .font(.textStyle(.h2))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            Text(L10n.VerificationCode.message(receiver))
                .wireTextStyle(.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 10) {
                ForEach(0 ..< 6, id: \.self) { index in
                    TextField("", text: $code[index])
                        .frame(width: 50, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedIndex == index ? Color.primaryButtonBackground : Color.secondaryButtonBorder,
                                    lineWidth: 1
                                )
                        )
                        .multilineTextAlignment(.center)
                        .font(.textStyle(.h2))
                        .foregroundColor(.primary)
                        .keyboardType(.numberPad)
                        .focused($focusedIndex, equals: index)
                        .onChange(of: code[index]) { newValue in
                            if newValue.count > 1 {
                                code[index] = String(newValue.prefix(1))
                            }
                            if !newValue.isEmpty, index < 5 {
                                focusedIndex = index + 1
                            } else if newValue.isEmpty, index > 0 {
                                focusedIndex = index - 1
                            }
                        }
                        .onChange(of: focusedIndex) { newValue in
                            print("Focused Index changed to: \(newValue ?? -1)")
                        }
                }
            }

            Button(action: {
                onConfirm(code)
            }, label: {
                Text(L10n.VerificationCode.confirm)
            })
            .wireButtonStyle(.primary)
            .padding(.horizontal)

            Button(action: {
                onResend()
            }, label: {
                Text(L10n.VerificationCode.resendCode)
            })
            .wireButtonStyle(.link)
        }
        .padding()
    }

}

#Preview("Empty code") {
    VerificationCodeView(
        receiver: "name@name.com",
        onConfirm: { _ in },
        onResend: {}
    )
}

#Preview("Not empty code") {
    VerificationCodeView(
        initialCode: ["1", "2", "3", "4", "5", ""],
        receiver: "name@name.com",
        onConfirm: { _ in },
        onResend: {}
    )
}
