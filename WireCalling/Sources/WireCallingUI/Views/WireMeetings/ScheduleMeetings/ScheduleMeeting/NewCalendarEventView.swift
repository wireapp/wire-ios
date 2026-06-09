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

struct NewCalendarEventView: View {

    enum Kind: String, CaseIterable, Identifiable {
        case event = "Event"
        case reminder = "Reminder"
        var id: Self { self }
    }

    enum TravelTime: String, CaseIterable, Identifiable {
        case none = "None"
        case fiveMinutes = "5 minutes"
        case fifteenMinutes = "15 minutes"
        case thirtyMinutes = "30 minutes"
        case oneHour = "1 hour"
        var id: Self { self }
    }

    private enum ExpandedField: Hashable {
        case startDate, startTime, endDate, endTime
    }

    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind = .event
    @State private var title = ""
    @State private var location = ""
    @State private var isAllDay = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var travelTime: TravelTime = .none
    @State private var expandedField: ExpandedField?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $kind) {
                        ForEach(Kind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    TextField("Title", text: $title)
                    TextField("Location or Video Call", text: $location)
                }

                Section {
                    Toggle("All-day", isOn: $isAllDay)
                        .onChange(of: isAllDay) { _, _ in
                            withAnimation { expandedField = nil }
                        }

                    dateTimeRow(
                        label: "Starts",
                        date: $startDate,
                        dateField: .startDate,
                        timeField: .startTime
                    )
                    dateTimeRow(
                        label: "Ends",
                        date: $endDate,
                        dateField: .endDate,
                        timeField: .endTime
                    )

                    Picker("Travel Time", selection: $travelTime) {
                        ForEach(TravelTime.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle("New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

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
            if !isAllDay {
                pill(
                    text: date.wrappedValue.formatted(date: .omitted, time: .shortened),
                    isSelected: expandedField == timeField
                ) {
                    toggleExpansion(timeField)
                }
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
}

#Preview {
    NewCalendarEventView()
}
