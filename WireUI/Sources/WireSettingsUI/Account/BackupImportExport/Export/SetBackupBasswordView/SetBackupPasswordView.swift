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

struct SetBackupPasswordView: View {

    @StateObject var viewModel: SetBackupPasswordViewModel

    private typealias Strings = L10n.Localizable
    private typealias Labels = L10n.Accessibility.SetBackupPassword

    var body: some View {
        NavigationStack {
            setBackupPasswordView
                .background(Color.viewBackground)
                .scrollContentBackground(.hidden)
                .navigationTitle(Strings.ExportBackup.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Strings.ExportBackup.Cancel.title) { viewModel.cancel() }
                            .foregroundStyle(ColorTheme.Base.primary.color)
                            .accessibilityLabel(Labels.Close.label)
                            .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var setBackupPasswordView: some View {
        VStack {
            let scrollView = ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(Strings.ExportBackup.description)
                        .font(.body)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    PasswordFieldView(
                        passwordRules: Text(viewModel.localizedPasswordRules),
                        password: $viewModel.password,
                        isPasswordVisible: false,
                        isPasswordValid: viewModel.isPasswordValid
                    )
                    .padding(.horizontal)
                }
            }
            if #available(iOS 16.4, *) {
                scrollView
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                scrollView
            }

            Spacer()

            Button(Strings.ExportBackup.button, action: viewModel.triggerExport)
                .bold()
                .disabled(!viewModel.isPasswordValid)
                .wireButtonStyle(.primary)
                .padding()
        }
    }

}

#Preview {
    SetBackupPasswordPreview()
}
