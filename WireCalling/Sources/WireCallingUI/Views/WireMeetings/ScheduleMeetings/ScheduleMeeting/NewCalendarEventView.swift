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

    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind = .event
    @State private var title = ""
    @State private var location = ""
    @State private var isAllDay = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var travelTime: TravelTime = .none

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

                    DatePicker(
                        "Starts",
                        selection: $startDate,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )

                    DatePicker(
                        "Ends",
                        selection: $endDate,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )

                    Picker("Travel Time", selection: $travelTime) {
                        ForEach(TravelTime.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
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
}

#Preview {
    NewCalendarEventView()
}
