//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireCallingDomain
import WireDesign

struct ScheduleMeetingView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: ScheduleMeetingViewModel

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                scheduleSection
                participantsSection
            }
            .listSectionSpacing(.compact)
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
    }

    private var titleSection: some View {
        Section(Strings.SetupTitle.header) {
            TextField(Strings.SetupTitle.placeholder, text: $viewModel.meetingTitle)
        }
        .textCase(nil)
    }

    private var participantsSection: some View {
        Section(Strings.SetupParticipants.header) {
            TextField(Strings.SetupParticipants.placeholder, text: $viewModel.participants)
        }
        .textCase(nil)
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
    ScheduleMeetingView(viewModel: ScheduleMeetingViewModel())
}
