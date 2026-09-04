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
import WireCallingDomainSupport
import WireDesign
import WireFoundation

struct MeetingFormView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule
    private static let timePickerMinuteInterval = 15

    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor
    @State private(set) var viewModel: MeetingFormViewModel
    @State private var expandedField: ExpandedField?
    @State private var isPresentingMemberSelection = false
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                if viewModel.mode != .instant {
                    scheduleSection
                }
                participantsSection
            }
            .listSectionSpacing(.compact)
            .onAppear {
                // When editing, the title is already filled in, so there is
                // no need to bring up the keyboard right away.
                if !viewModel.mode.isEdit {
                    isTitleFieldFocused = true
                }
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.Backgrounds.background.color)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Cancel.button) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(actionButtonLabel) {
                        Task { await viewModel.submit() }
                    }
                    .disabled(!viewModel.isNextButtonEnabled || viewModel.isLoading)
                }
            }
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .sheet(isPresented: $isPresentingMemberSelection) {
                MemberSelectionView(viewModel: viewModel.makeMemberSelectionViewModel())
            }
            .alert(isPresented: $viewModel.hasError) {
                Alert(
                    title: Text(Strings.Error.Alert.title),
                    dismissButton: .default(Text(Strings.Error.Alert.ok))
                )
            }
            .alert(
                Strings.Error.ConversationName.title,
                isPresented: $viewModel.hasConversationNameUpdateError
            ) {
                Button(Strings.Error.ConversationName.retry) {
                    Task { await viewModel.retryConversationNameUpdate() }
                }
            } message: {
                Text(Strings.Error.ConversationName.message)
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.mode {
        case .instant:
            Strings.Now.title
        case .scheduled:
            Strings.Future.title
        case .edit:
            Strings.Edit.title
        }
    }

    private var actionButtonLabel: String {
        switch viewModel.mode {
        case .instant:
            Strings.Start.button
        case .scheduled:
            Strings.Schedule.button
        case .edit:
            Strings.Save.button
        }
    }

    private var titleSection: some View {
        Section {
            HStack {
                TextField(Strings.SetupTitle.placeholder, text: $viewModel.meetingTitle)
                    .focused($isTitleFieldFocused)
                if !viewModel.meetingTitle.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.lightGray))
                        .onTapGesture {
                            viewModel.clearTitle()
                        }
                }
            }
        } header: {
            Text(Strings.SetupTitle.header)
        } footer: {
            if viewModel.isMeetingTitleTooLong {
                Text(Strings.SetupTitle.Error.tooLong)
                    .foregroundStyle(ColorTheme.Base.error.color)
            }
        }
        .textCase(nil)
    }

    private var scheduleSection: some View {
        Section {
            dateTimeRow(
                label: Strings.Time.starts,
                date: $viewModel.startDate,
                range: viewModel.startDateRange,
                maximumDate: nil,
                dateField: .startDate,
                timeField: .startTime
            )
            dateTimeRow(
                label: Strings.Time.ends,
                date: $viewModel.endDate,
                range: viewModel.endDateRange.lowerBound...,
                maximumDate: viewModel.endDateRange.upperBound,
                dateField: .endDate,
                timeField: .endTime
            )
            Picker(Strings.Time.repeats, selection: $viewModel.repeatOption) {
                ForEach(viewModel.availableRepeatOptions, id: \.self) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
        }
    }

    private var participantsSection: some View {
        Section(Strings.SetupParticipants.header) {
            Button {
                isPresentingMemberSelection = true
            } label: {
                HStack {
                    if viewModel.selectedMembers.isEmpty {
                        Text(Strings.SetupParticipants.placeholder)
                            .foregroundStyle(Color(.placeholderText))
                        Spacer()
                    } else {
                        Text(viewModel.selectedMembersSummary)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(viewModel.selectedMembers.count)")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .textCase(nil)
    }

    // MARK: - Date/time row helpers

    @ViewBuilder
    private func dateTimeRow(
        label: String,
        date: Binding<Date>,
        range: PartialRangeFrom<Date>,
        maximumDate: Date?,
        dateField: ExpandedField,
        timeField: ExpandedField
    ) -> some View {
        let isDateFieldEnabled = dateField != .endDate

        HStack {
            Text(label)
            Spacer()
            pill(
                text: date.wrappedValue.formatted(.dateTime.day().month(.abbreviated).year()),
                isSelected: expandedField == dateField
            ) {
                toggleExpansion(dateField)
            }
            // Acceptance: the end date is visible but not editable, and VoiceOver ignores this disabled control.
            .disabled(!isDateFieldEnabled)
            .accessibilityHidden(!isDateFieldEnabled)
            pill(
                text: date.wrappedValue.formatted(date: .omitted, time: .shortened),
                isSelected: expandedField == timeField
            ) {
                toggleExpansion(timeField)
            }
        }

        if expandedField == dateField {
            DatePicker("", selection: date, in: range, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
        if expandedField == timeField {
            timePicker(date: date, range: range, maximumDate: maximumDate)
        }
    }

    @ViewBuilder
    private func timePicker(date: Binding<Date>, range: PartialRangeFrom<Date>, maximumDate: Date?) -> some View {
        MinuteIntervalTimePicker(
            selection: date,
            range: range,
            maximumDate: maximumDate,
            minuteInterval: Self.timePickerMinuteInterval
        )
        .id(Calendar.current.isDate(date.wrappedValue, equalTo: range.lowerBound, toGranularity: .hour))
    }

    private func pill(
        text: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let accentColor = ColorTheme.Base.primary(wireAccentColor).color

        return Button(action: action) {
            Text(text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func toggleExpansion(_ field: ExpandedField) {
        withAnimation { expandedField = expandedField == field ? nil : field }
    }

    private enum ExpandedField: Hashable {
        case startDate
        case startTime
        case endDate
        case endTime
    }
}

private struct MinuteIntervalTimePicker: UIViewRepresentable {

    @Binding var selection: Date
    let range: PartialRangeFrom<Date>
    let maximumDate: Date?
    let minuteInterval: Int

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minuteInterval = minuteInterval
        datePicker.minimumDate = range.lowerBound
        datePicker.maximumDate = maximumDate
        datePicker.date = selection
        datePicker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return datePicker
    }

    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.minuteInterval = minuteInterval
        datePicker.minimumDate = range.lowerBound
        datePicker.maximumDate = maximumDate

        if abs(datePicker.date.timeIntervalSince(selection)) > 0.5 {
            datePicker.date = selection
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    final class Coordinator: NSObject {

        private let selection: Binding<Date>

        init(selection: Binding<Date>) {
            self.selection = selection
        }

        @MainActor
        @objc
        func valueChanged(_ datePicker: UIDatePicker) {
            selection.wrappedValue = datePicker.date
        }
    }
}

private extension MeetingRepeatOption {

    typealias Strings = L10n.Localizable.WireMeetings.Schedule.Time

    var title: String {
        switch self {
        case .never:
            Strings.never
        case .daily:
            Strings.daily
        case .weekly:
            Strings.weekly
        case .everyTwoWeeks:
            Strings.everyTwoWeeks
        case .everyFourWeeks:
            Strings.everyFourWeeks
        case .monthly:
            Strings.monthly
        case .yearly:
            Strings.yearly
        }
    }
}

// MARK: - Preview

#Preview("Now mode") {
    MeetingFormView(
        viewModel: MeetingFormViewModel(
            mode: .instant,
            searchMembersUseCase: MockSearchMembersUseCase(),
            createMeetingUseCase: CreateMeetingUseCaseProtocolMock(),
            updateMeetingUseCase: UpdateMeetingUseCaseProtocolMock(),
            currentDateProvider: .system
        )
    )
}

#Preview("Scheduled mode") {
    MeetingFormView(
        viewModel: MeetingFormViewModel(
            mode: .scheduled,
            searchMembersUseCase: MockSearchMembersUseCase(),
            createMeetingUseCase: CreateMeetingUseCaseProtocolMock(),
            updateMeetingUseCase: UpdateMeetingUseCaseProtocolMock(),
            currentDateProvider: .system
        )
    )
}

#Preview("Scheduled mode with selected members") {
    let viewModel = MeetingFormViewModel(
        mode: .scheduled,
        searchMembersUseCase: MockSearchMembersUseCase(),
        createMeetingUseCase: CreateMeetingUseCaseProtocolMock(),
        updateMeetingUseCase: UpdateMeetingUseCaseProtocolMock(),
        currentDateProvider: .system
    )
    viewModel.selectedMembers = Array([MeetingMember].mock.shuffled().prefix(3))
    return MeetingFormView(viewModel: viewModel)
}

#Preview("Edit mode") {
    MeetingFormView(
        viewModel: MeetingFormViewModel(
            mode: .edit(
                Meeting(
                    id: QualifiedID(id: UUID(), domain: ""),
                    title: "Design review",
                    start: Date().addingTimeInterval(.oneHour),
                    end: Date().addingTimeInterval(2 * TimeInterval.oneHour),
                    recurrence: MeetingRecurrence(frequency: .weekly, interval: 1),
                    conversation: MeetingConversation(
                        participants: Set([MeetingMember].mock.prefix(3))
                    ),
                    conversationID: QualifiedID(id: UUID(), domain: ""),
                    creatorID: QualifiedID(id: UUID(), domain: "")
                )
            ),
            searchMembersUseCase: MockSearchMembersUseCase(),
            createMeetingUseCase: CreateMeetingUseCaseProtocolMock(),
            updateMeetingUseCase: UpdateMeetingUseCaseProtocolMock(),
            currentDateProvider: .system
        )
    )
}

// MARK: - Mock

private struct MockSearchMembersUseCase: SearchMembersUseCaseProtocol {

    let members: [MeetingMember] = .mock

    func invoke(query: String) async throws -> [MeetingMember] {
        guard !query.isEmpty else { return members }
        return members.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

private extension [MeetingMember] {
    static var mock: Self {
        [
            .init(name: "Martin Koch-Johansen", handle: "username"),
            .init(name: "Olga Heaney", handle: "username"),
            .init(name: "Margarete Springer", handle: "username"),
            .init(name: "Lorenzo Schmeler", handle: ""),
            .init(name: "Jaqueline Olaho", handle: ""),
            .init(name: "Katie Armstrong", handle: "username"),
            .init(name: "Zachary Ratke", handle: "username"),
            .init(name: "Marco Weissnat", handle: "username"),
            .init(name: "Deborah Schoen", handle: "username")
        ]
    }
}

private extension MeetingMember {

    init(
        name: String,
        handle: String
    ) {
        self.init(
            qualifiedID: QualifiedID(id: UUID(), domain: ""),
            name: name,
            handle: handle,
            isSelfUser: false,
            initials: "",
            accentColor: .default,
            avatarImageData: nil
        )
    }
}
