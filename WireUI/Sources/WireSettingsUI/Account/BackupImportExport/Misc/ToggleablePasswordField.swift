import SwiftUI
import WireDesign

struct ToggleablePasswordField: View {

    @Binding var password: String

    var titleColor: Color
    var borderColor: Color

    @State private var isPasswordVisible = false

    var body: some View {
        HStack {

            if isPasswordVisible {
                TextField(text: $password) {
                    Text(L10n.Localizable.ImportBackup.EnterPassword.TextField.placeholder)
                        .foregroundStyle(titleColor)
                }
                .textContentType(.password)
                .autocapitalization(.none)
            } else {
                SecureField(text: $password) {
                    Text(L10n.Localizable.ImportBackup.EnterPassword.TextField.placeholder)
                        .foregroundStyle(titleColor)
                }
                .textContentType(.password)
            }

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(Color(uiColor: BaseColorPalette.Neutrals.black))
            }

        }
        .padding()
        .background(Color(uiColor: BaseColorPalette.Neutrals.white))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    ToggleablePasswordField(
        password: .constant(""),
        titleColor: Color(uiColor: BaseColorPalette.Neutrals.black),
        borderColor: Color(uiColor: BaseColorPalette.Neutrals.black)
    )
    .padding()
}
