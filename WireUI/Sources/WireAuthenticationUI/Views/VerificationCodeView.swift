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

struct VerificationCodeView: View {

    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.VerificationCode.title)
                .font(.textStyle(.h2))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            Text(L10n.VerificationCode.message)
                .wireTextStyle(.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $code[index])
                        .frame(width: 50, height: 50)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .keyboardType(.numberPad)
                        .focused($focusedIndex, equals: index)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: code[index]) { newValue in
                            if newValue.count > 1 {
                                code[index] = String(newValue.prefix(1)) // Keep only 1 character
                            }
                            if !newValue.isEmpty && index < 5 {
                                focusedIndex = index + 1 // Move to the next field
                            } else if newValue.isEmpty && index > 0 {
                                focusedIndex = index - 1 // Move to the previous field
                            }
                        }
                }
            }

            Button(action: {
                confirmCode()
//                actionCallback(.submit(identity: identity))
            }, label: {
                Text(L10n.VerificationCode.confirm)
            })
            .wireButtonStyle(.primary)
            .padding(.horizontal)

            Button(action: {
                resendCode()
//                actionCallback(.submit(identity: identity))
            }, label: {
                Text(L10n.VerificationCode.resendCode)
            })
            .wireButtonStyle(.link)
        }
        .padding()
    }

    private func confirmCode() {
        print("Code entered: \(code.joined())")
    }

    private func resendCode() {
        print("Resend code tapped")
    }

}

//struct VerificationCodeView_Previews: PreviewProvider {
//    static var previews: some View {
//        VerificationCodeView()
//    }
//}

#Preview {
    VerificationCodeView()
}
