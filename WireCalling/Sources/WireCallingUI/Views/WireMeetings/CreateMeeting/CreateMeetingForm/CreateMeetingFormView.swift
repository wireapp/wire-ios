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

struct CreateMeetingFormView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: CreateMeetingFormViewModel
    @State private var expandedField: ExpandedField?
    @State private var isPresentingMemberSelection = false
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                if viewModel.mode == .scheduled {
                    scheduleSection
                }
                participantsSection
            }
            .listSectionSpacing(.compact)
            .onAppear {
                isTitleFieldFocused = true
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
            .alert(isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Alert(
                    title: Text(Strings.Error.Alert.title),
                    message: Text(viewModel.error?.localizedDescription ?? ""),
                    dismissButton: .default(Text(Strings.Error.Alert.ok))
                )
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.mode {
        case .instant:
            Strings.Now.title
        case .scheduled:
            Strings.Future.title
        }
    }

    private var actionButtonLabel: String {
        switch viewModel.mode {
        case .instant:
            Strings.Start.button
        case .scheduled:
            Strings.Schedule.button
        }
    }

    private var titleSection: some View {
        Section(Strings.SetupTitle.header) {
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
        }
        .textCase(nil)
    }

    private var scheduleSection: some View {
        Section {
            dateTimeRow(
                label: Strings.Time.starts,
                date: $viewModel.startDate,
                range: viewModel.startDateRange,
                dateField: .startDate,
                timeField: .startTime
            )
            dateTimeRow(
                label: Strings.Time.ends,
                date: $viewModel.endDate,
                range: viewModel.endDateRange,
                dateField: .endDate,
                timeField: .endTime
            )
            Picker(Strings.Time.repeats, selection: $viewModel.repeatOption) {
                ForEach(MeetingRepeatOption.allCases, id: \.self) { option in
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
            DatePicker("", selection: date, in: range, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
        if expandedField == timeField {
            DatePicker("", selection: date, in: range, displayedComponents: .hourAndMinute)
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

    private enum ExpandedField: Hashable {
        case startDate
        case startTime
        case endDate
        case endTime
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

#Preview("Now mode") {
    CreateMeetingFormView(
        viewModel: CreateMeetingFormViewModel(
            mode: .instant,
            searchMembersUseCase: MockSearchMembersUseCase(),
            createInstantMeetingUseCase: CreateInstantMeetingUseCaseProtocolMock(),
            createScheduledMeetingUseCase: CreateScheduledMeetingUseCaseProtocolMock(),
            currentDateProvider: .system
        )
    )
}

#Preview("Scheduled mode") {
    CreateMeetingFormView(
        viewModel: CreateMeetingFormViewModel(
            mode: .scheduled,
            searchMembersUseCase: MockSearchMembersUseCase(),
            createInstantMeetingUseCase: CreateInstantMeetingUseCaseProtocolMock(),
            createScheduledMeetingUseCase: CreateScheduledMeetingUseCaseProtocolMock(),
            currentDateProvider: .system
        )
    )
}

#Preview("Scheduled mode with selected members") {
    let viewModel = CreateMeetingFormViewModel(
        mode: .scheduled,
        searchMembersUseCase: MockSearchMembersUseCase(),
        createInstantMeetingUseCase: CreateInstantMeetingUseCaseProtocolMock(),
        createScheduledMeetingUseCase: CreateScheduledMeetingUseCaseProtocolMock(),
        currentDateProvider: .system
    )
    viewModel.selectedMembers = Array([Member].mock.shuffled().prefix(3))
    return CreateMeetingFormView(viewModel: viewModel)
}

// MARK: - Mock

private struct MockSearchMembersUseCase: SearchMembersUseCaseProtocol {

    let members: [Member] = .mock

    func invoke(query: String) async throws -> [Member] {
        guard !query.isEmpty else { return members }
        return members.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

private extension [Member] {
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

private extension Member {

    init(
        name: String,
        handle: String
    ) {
        self.init(
            qualifiedID: QualifiedID(id: UUID(), domain: ""),
            name: name,
            handle: handle
        )
    }
}
