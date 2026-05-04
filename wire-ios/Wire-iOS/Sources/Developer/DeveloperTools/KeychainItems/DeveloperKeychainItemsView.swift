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

struct DeveloperKeychainItemsView: View {
    @StateObject var viewModel: DeveloperKeychainItemsViewModel
    @State private var showDeleteAllAlert = false

    var body: some View {
        VStack {
            if viewModel.passwordItems.isEmpty, viewModel.keyItems.isEmpty {
                Text("No items in the keychain")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    if !viewModel.passwordItems.isEmpty {
                        section(
                            named: "Password",
                            withItems: viewModel.passwordItems
                        )
                    }

                    if !viewModel.keyItems.isEmpty {
                        section(
                            named: "Keys",
                            withItems: viewModel.keyItems
                        )
                    }
                }
                deleteAllButton
            }
        }
        .navigationTitle("Keychain Items")
    }

    var deleteAllButton: some View {
        Button(role: .destructive) {
            showDeleteAllAlert = true
        } label: {
            Text("Delete All")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .alert(
            "Delete All Items?",
            isPresented: $showDeleteAllAlert
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                viewModel.deleteAll()
            }
        } message: {
            Text("This will permanently remove all keychain items. This action cannot be undone.")
        }
    }

    func section(named name: String, withItems items: [KeychainItem]) -> some View {
        Section(name) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.nameFor(item) ?? "<no name>")
                        .font(.headline)

                    if let value = item.value {
                        ExpandableText(text: value)
                    }
                    if let accessGroup = item.accessGroup {
                        Text(accessGroup).font(.subheadline)
                    }
                }
            }
            .onDelete { indexSet in
                indexSet
                    .map { items[$0] }
                    .forEach(viewModel.delete)
            }
        }
    }

}

// MARK: - Expandable Text

struct ExpandableText: View {
    let text: String
    @State private var expanded = false
    @State private var truncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .lineLimit(expanded ? nil : 3)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .background(
                    // Measure if text is truncated
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.clear)
                        .lineLimit(3)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.onAppear {
                                    let singleLine = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
                                    let maxHeight = singleLine * 3
                                    truncated = proxy.size.height >= maxHeight - 1
                                }
                            }
                        )
                        .hidden()
                )

            if truncated {
                Button(expanded ? "Show less" : "Show more") {
                    withAnimation { expanded.toggle() }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}
