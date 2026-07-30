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

struct MemberSelectionView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule.Members

    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor
    @State private(set) var viewModel: MemberSelectionViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.isSelectedExpanded {
                        ForEach(viewModel.selectedMembers, id: \.qualifiedID) { row(for: $0) }
                    }
                } header: {
                    sectionHeader(
                        title: "\(Strings.Selected.title) (\(viewModel.selectedMembers.count))",
                        isExpanded: $viewModel.isSelectedExpanded
                    )
                }

                Section {
                    if viewModel.isContactsExpanded {
                        contactsContent
                    }
                } header: {
                    sectionHeader(
                        title: Strings.Contacts.title,
                        isExpanded: $viewModel.isContactsExpanded
                    )
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(ColorTheme.Backgrounds.background.color)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Strings.Search.Field.placeholder
            )
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Cancel.button, role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Select.button) {
                        viewModel.confirmSelection()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder private var contactsContent: some View {
        if !viewModel.filteredUnselected.isEmpty {
            ForEach(viewModel.filteredUnselected, id: \.qualifiedID) { row(for: $0) }
        } else if viewModel.isSearching {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 24)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else if viewModel.hasSearchError {
            ContentUnavailableView {
                Label {
                    Text(Strings.Error.title)
                } icon: {
                    Image(systemName: "exclamationmark.magnifyingglass")
                        .foregroundStyle(.primary)
                }
            } description: {
                Text(Strings.Error.description)
            } actions: {
                Button {
                    viewModel.retrySearch()
                } label: {
                    Text(Strings.Retry.button)
                }
                .wireButtonStyle(.tertiary)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
            ContentUnavailableView {
                Label {
                    Text(Strings.Empty.title)
                } icon: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.primary)
                }
            } description: {
                Text(Strings.Empty.description)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        let accentColor = ColorTheme.Base.primary(wireAccentColor).color

        return Button {
            withAnimation { isExpanded.wrappedValue.toggle() }
        } label: {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                    .foregroundStyle(accentColor)
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    private func row(for member: MeetingMember) -> some View {
        let isSelected = viewModel.isSelected(member)
        let accentColor = ColorTheme.Base.primary(wireAccentColor).color

        return Button {
            viewModel.toggleSelection(member)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .hidden()
                    .overlay {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.tertiary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !member.handle.isEmpty {
                        Text("@" + member.handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isSelected ? accentColor : Color.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("success") {
    MemberSelectionView(viewModel: MemberSelectionViewModel(source: MockSearchMembersUseCase()))
}

#Preview("empty") {
    MemberSelectionView(viewModel: MemberSelectionViewModel(source: MockSearchMembersUseCase(members: [])))
}

#Preview("failure") {
    MemberSelectionView(
        viewModel: MemberSelectionViewModel(source: MockSearchMembersUseCase(error: URLError(.badServerResponse)))
    )
}

// MARK: - Mock

private struct MockSearchMembersUseCase: SearchMembersUseCaseProtocol {

    let result: Result<[MeetingMember], any Error>

    init(members: [MeetingMember] = .mock) {
        self.result = .success(members)
    }

    init(error: any Error) {
        self.result = .failure(error)
    }

    func invoke(query: String) async throws -> [MeetingMember] {
        switch result {
        case let .failure(error):
            throw error
        case let .success(members):
            guard !query.isEmpty else { return members }
            return members.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
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
            handle: handle
        )
    }

}
