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
import WireFoundation

struct ScheduleMeetingView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: ScheduleMeetingViewModel
    @State private var expandedField: ExpandedField?
    @State private var selectedMembers: [Member] = []

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
            HStack {
                TextField(Strings.SetupTitle.placeholder, text: $viewModel.meetingTitle)
                if !viewModel.meetingTitle.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.lightGray))
                        .onTapGesture {
                            viewModel.clearTitle()
                        }
                }
            }
        }
        .textCase(nil)
    }

    private var scheduleSection: some View {
        Section {
            dateTimeRow(
                label: Strings.Time.starts,
                date: $viewModel.startDate,
                dateField: .startDate,
                timeField: .startTime
            )
            dateTimeRow(
                label: Strings.Time.ends,
                date: $viewModel.endDate,
                dateField: .endDate,
                timeField: .endTime
            )

            Picker(Strings.Time.repeats, selection: $viewModel.repeatOption) {
                ForEach(RepeatOption.allCases, id: \.self) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
        }
    }

    private var participantsSection: some View {
        Section(Strings.SetupParticipants.header) {
            // TextField(Strings.SetupParticipants.placeholder, text: $viewModel.participants)

            NavigationLink {
                ParticipantPickerView(selection: $selectedMembers)
            } label: {
                TextField(Strings.SetupParticipants.placeholder, text: .constant(""))
                    .disabled(true)
            }

            NavigationLink {
                ParticipantPickerView(selection: $selectedMembers)
            } label: {
                HStack {
                    Text("Participants")
                    Spacer()
                    Text(participantsSummary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            NavigationLink {
                ParticipantPickerView(selection: $selectedMembers)
            } label: {
                HStack {
                    Text(
                        "Lorem, ipsum, dolor, sit, amet, consetetur, sadipscing, elitr, sed, diam, nonumy, eirmod, tempor, invidunt, ut labore, et dolore, magna aliquyam, erat"
                    )
                    .lineLimit(1)
                    Spacer()
                    Text("18")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .textCase(nil)
    }

    // MARK: -

    @ViewBuilder
    private func dateTimeRow(
        label: String,
        date: Binding<Date>,
        dateField: ExpandedField,
        timeField: ExpandedField
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            pill(
                text: date.wrappedValue.formatted(.dateTime.day().month(.abbreviated).year()),
                isSelected: expandedField == dateField
            ) {
                toggleExpansion(dateField)
            }
            pill(
                text: date.wrappedValue.formatted(date: .omitted, time: .shortened),
                isSelected: expandedField == timeField
            ) {
                toggleExpansion(timeField)
            }
        }

        if expandedField == dateField {
            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
        if expandedField == timeField {
            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }

    private func pill(
        text: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func toggleExpansion(_ field: ExpandedField) {
        withAnimation { expandedField = expandedField == field ? nil : field }
    }

    private var participantsSummary: String {
        guard let first = selectedMembers.first else { return "None" }
        let extra = selectedMembers.count - 1
        return extra > 0 ? "\(first.name), + \(extra) more" : first.name
    }

    private enum ExpandedField: Hashable {
        case startDate
        case startTime
        case endDate
        case endTime
    }

}

private struct ParticipantPickerView: View {
    @Binding var selection: [Member]

    private let allParticipants = [
        "Martina Koch-Johansen",
        "Daniel Becker",
        "Sophia Müller",
        "Lucas Hoffmann",
        "Anna Schmidt"
    ].map { name in
        Member(qualifiedID: QualifiedID(id: UUID(), domain: ""), name: name, handle: name)
    }

    var body: some View {
        Form {
            ForEach(allParticipants, id: \.qualifiedID) { participant in
                Button {
                    toggle(participant)
                } label: {
                    HStack {
                        Text(participant.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection.contains(participant) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Participants")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ participant: Member) {
        if let index = selection.firstIndex(of: participant) {
            selection.remove(at: index)
        } else {
            selection.append(participant)
        }
    }
}

private extension RepeatOption {

    typealias Strings = L10n.Localizable.WireMeetings.Schedule.Time

    var title: String {
        switch self {
        case .never:
            Strings.never
        case .daily:
            Strings.daily
        case .weekly:
            Strings.weekly
        case .every2Weeks:
            Strings.everyTwoWeeks
        case .monthly:
            Strings.monthly
        case .yearly:
            Strings.yearly
        }
    }

}

// MARK: - Preview

#Preview {
    ScheduleMeetingView(
        viewModel: ScheduleMeetingViewModel(
            memberRepository: MemberRepositoryMock()
        )
    )
}

private struct MemberRepositoryMock: MemberRepositoryProtocol {
    func search(query: String) async throws -> [Member] {
        []
    }
}
