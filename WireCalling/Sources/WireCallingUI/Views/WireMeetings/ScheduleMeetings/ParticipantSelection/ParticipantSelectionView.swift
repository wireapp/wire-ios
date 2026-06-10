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

struct ParticipantSelectionView: View {

    struct Participant: Identifiable, Hashable {
        let id: UUID
        var name: String
        var username: String?
    }

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var isSelectedExpanded = true
    @State private var isContactsExpanded = true
    @State private var selectedIDs: Set<Participant.ID> = []

    // TODO: inject from caller / view model
    private let allParticipants: [Participant] = .mock

    var body: some View {
        NavigationStack {
            List {
                if !selectedParticipants.isEmpty {
                    Section {
                        if isSelectedExpanded {
                            ForEach(selectedParticipants) { row(for: $0) }
                        }
                    } header: {
                        sectionHeader(
                            title: "Selected (\(selectedIDs.count))",
                            isExpanded: $isSelectedExpanded
                        )
                    }
                }

                Section {
                    if isContactsExpanded {
                        ForEach(filteredUnselected) { row(for: $0) }
                    }
                } header: {
                    sectionHeader(
                        title: "Contacts",
                        isExpanded: $isContactsExpanded
                    )
                }
            }
            .listStyle(.plain)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Enter a name or email"
            )
            .navigationTitle("Meet Now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") { dismiss() }
                        .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation { isExpanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    private func row(for participant: Participant) -> some View {
        let isSelected = selectedIDs.contains(participant.id)
        return Button {
            toggleSelection(participant.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let username = participant.username {
                        Text("@" + username)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived state

    private var selectedParticipants: [Participant] {
        allParticipants.filter { selectedIDs.contains($0.id) }
    }

    private var filteredUnselected: [Participant] {
        let unselected = allParticipants.filter { !selectedIDs.contains($0.id) }
        guard !searchText.isEmpty else { return unselected }
        return unselected.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func toggleSelection(_ id: Participant.ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

private extension Array where Element == ParticipantSelectionView.Participant {
    static var mock: Self {
        [
            .init(id: UUID(), name: "Martin Koch-Johansen", username: "username"),
            .init(id: UUID(), name: "Olga Heaney", username: "username"),
            .init(id: UUID(), name: "Margarete Springer", username: "username"),
            .init(id: UUID(), name: "Lorenzo Schmeler", username: nil),
            .init(id: UUID(), name: "Jaqueline Olaho", username: nil),
            .init(id: UUID(), name: "Katie Armstrong", username: "username"),
            .init(id: UUID(), name: "Zachary Ratke", username: "username"),
            .init(id: UUID(), name: "Marco Weissnat", username: "username"),
            .init(id: UUID(), name: "Deborah Schoen", username: "username")
        ]
    }
}

// MARK: - Preview

#Preview {
    ParticipantSelectionView()
}
