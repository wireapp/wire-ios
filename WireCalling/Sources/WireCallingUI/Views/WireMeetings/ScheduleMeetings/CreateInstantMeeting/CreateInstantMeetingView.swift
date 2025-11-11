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

import Foundation
import SwiftUI
import WireDesign
import WireReusableUIComponents

struct CreateInstantMeetingView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: CreateInstantMeetingViewModel
    @State private var isPasswordVisible = false
    @State private var isConfirmedPasswordVisible = false

    init(viewModel: @autoclosure @escaping () -> CreateInstantMeetingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationView {
            if #available(iOS 17, *) {
                formContent
                    .listSectionSpacing(.compact)
            } else {
                formContent
                    .listStyle(.insetGrouped)
            }
        }
        .background(ColorTheme.Backgrounds.background.color)
    }

    private var titleSection: some View {
        Section(Strings.SetupTitle.header) {
            TextField(Strings.SetupTitle.placeholder, text: $viewModel.meetingTitle)
        }
    }

    private var participantsSection: some View {
        Section(Strings.SetupParticipants.header) {
            TextField(Strings.SetupParticipants.placeholder, text: $viewModel.participants)
        }
    }

    private var passwordSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isPasswordVisible {
                        TextField(Strings.Password.placeholder, text: $viewModel.password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    } else {
                        SecureField(Strings.Password.placeholder, text: $viewModel.password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(ColorTheme.Backgrounds.onSurface.color)
                    }
                }

                if !viewModel.password.isEmpty, !viewModel.isPasswordValid {
                    Text(viewModel.localizedPasswordRules)
                        .font(.caption)
                        .foregroundColor(ColorTheme.Base.error.color)
                }
            }
        } header: {
            Text(Strings.SetupPassword.header)
        }
    }

    private var confirmedPasswordSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isConfirmedPasswordVisible {
                        TextField(Strings.ConfirmedPassword.placeholder, text: $viewModel.confirmedPassword)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    } else {
                        SecureField(Strings.ConfirmedPassword.placeholder, text: $viewModel.confirmedPassword)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    }

                    Button {
                        isConfirmedPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isConfirmedPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(ColorTheme.Backgrounds.onSurface.color)
                    }
                }

                if !viewModel.confirmedPassword.isEmpty, !viewModel.isConfirmedPasswordValid {
                    Text(Strings.ConfirmedPassword.error)
                        .font(.caption)
                        .foregroundColor(ColorTheme.Base.error.color)
                }
            }
        }
    }

    @ViewBuilder private var formContent: some View {
        Form {
            titleSection
            participantsSection
            Toggle(Strings.AllowGuests.title, isOn: $viewModel.allowGuests)
            passwordSection
            confirmedPasswordSection
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color)
        .navigationTitle(Strings.Now.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Cancel.button) {
                    dismiss()
                }
                .foregroundColor(viewModel.accentColor)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Strings.Next.button) {
                    viewModel.createInstantMeeting()
                }
                .disabled(!viewModel.isNextButtonEnabled)
                .tint(viewModel.accentColor)
            }

        }
        .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
    }

}

// MARK: - Preview

#Preview {
    CreateInstantMeetingView(viewModel: CreateInstantMeetingViewModel(
        accentColor: .blue,
        passwordValidator: MockPasswordValidator()
    ))
}

private struct MockPasswordValidator: PasswordValidator {
    func isPasswordValid(_ password: String) -> Bool {
        password.count >= 8
    }

    var localizedRulesDescription: String? {
        "Password must be at least 8 characters"
    }
}
