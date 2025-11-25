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
        NavigationStack {
            if #available(iOS 17, *) {
                formContent
                    .listSectionSpacing(.compact)
            } else {
                formContent
                    .listStyle(.insetGrouped)
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
        .toolbar { toolbarContent }
        .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(Strings.Cancel.button) {
                dismiss()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(Strings.Next.button) {
                viewModel.createInstantMeeting()
            }
            .disabled(!viewModel.isNextButtonEnabled)
        }
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
            PasswordFieldWithToggle(
                placeholder: Strings.Password.placeholder,
                text: $viewModel.password,
                isVisible: $isPasswordVisible,
                errorMessage: viewModel.localizedPasswordRules,
                showError: !viewModel.password.isEmpty && !viewModel.isPasswordValid,
                isContextMenuAllowed: viewModel.isContextMenuAllowed
            )
        } header: {
            Text(Strings.SetupPassword.header)
        }
    }

    private var confirmedPasswordSection: some View {
        Section {
            PasswordFieldWithToggle(
                placeholder: Strings.ConfirmedPassword.placeholder,
                text: $viewModel.confirmedPassword,
                isVisible: $isConfirmedPasswordVisible,
                errorMessage: Strings.ConfirmedPassword.error,
                showError: !viewModel.confirmedPassword.isEmpty && !viewModel.isConfirmedPasswordValid,
                isContextMenuAllowed: viewModel.isContextMenuAllowed
            )
        }
    }

}

// MARK: - Preview

#Preview {
    CreateInstantMeetingView(viewModel: CreateInstantMeetingViewModel(
        passwordValidator: MockPasswordValidator(),
        isContextMenuAllowed: true
    ))
}
