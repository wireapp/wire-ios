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
import WireCallingDomain
import WireDesign
import WireReusableUIComponents

struct ScheduleMeetingView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ScheduleMeetingViewModel
    @State private var isPasswordVisible = false
    @State private var isConfirmedPasswordVisible = false

    init(viewModel: @autoclosure @escaping () -> ScheduleMeetingViewModel) {
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
            scheduleSection
            participantsSection
            Toggle(Strings.AllowGuests.title, isOn: $viewModel.allowGuests)
            passwordSection
            confirmedPasswordSection
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color)
        .navigationTitle(Strings.Future.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Cancel.button) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Strings.Schedule.button) {
                    viewModel.scheduleMeeting()
                }
                .disabled(!viewModel.isNextButtonEnabled)
            }
        }
        .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
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

    private var scheduleSection: some View {
        Section {
            DateTimeRow(
                label: L10n.Localizable.WireMeetings.Schedule.Time.starts,
                date: $viewModel.startDate
            )

            DateTimeRow(
                label: L10n.Localizable.WireMeetings.Schedule.Time.ends,
                date: $viewModel.endDate
            )

            RepeatRow(
                selectedOption: $viewModel.repeatOption
            )
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

private struct RepeatRow: View {
    @Binding var selectedOption: RepeatOption

    var body: some View {
        HStack {
            Text(L10n.Localizable.WireMeetings.Schedule.Time.repeats)
                .foregroundColor(ColorTheme.Backgrounds.onSurface.color)

            Spacer()

            Menu {
                ForEach(RepeatOption.allCases, id: \.self) { option in
                    Button(option.title) {
                        selectedOption = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedOption.title)
                        .foregroundColor(ColorTheme.Base.secondaryText.color)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(ColorTheme.Base.secondaryText.color)
                }
            }
        }
    }
}

private struct DateTimeRow: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.Backgrounds.onSurface.color)

            Spacer()

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .labelsHidden()
            .fixedSize()

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .fixedSize()
        }
    }
}

// MARK: - Preview

#Preview {
    ScheduleMeetingView(viewModel: ScheduleMeetingViewModel(
        passwordValidator: MockPasswordValidator(), isContextMenuAllowed: true
    )
    )
}
