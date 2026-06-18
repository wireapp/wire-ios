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

public import SwiftUI

import WireDesign
import WireFoundation
import WireMessagingDomain

// MARK: - View

public struct SemanticSearchView: View {

    @StateObject private var viewModel = SemanticSearchViewModel()
    @Environment(\.wireAccentColor) private var accentColor
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isIndexEmpty {
                    emptyIndexView
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty && !viewModel.isSearching {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle(Text(verbatim: "Search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .searchable(text: $viewModel.query, prompt: "Search all conversations…")
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - States

    private var emptyIndexView: some View {
        ContentUnavailableView(
            "Index Building",
            systemImage: "magnifyingglass",
            description: Text("Messages are being indexed in the background. Try again in a moment.")
        )
    }

    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different phrase or topic.")
        )
    }

    // MARK: - Results

    private var resultsList: some View {
        List {
            if !viewModel.query.isEmpty {
                Section {
                    ForEach(viewModel.results) { result in
                        resultRow(result)
                    }
                } header: {
                    Text(verbatim: "\(viewModel.results.count) result\(viewModel.results.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.background.opacity(0.6))
            }
        }
    }

    private func resultRow(_ result: SemanticSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: result.conversationName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(result.timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: result.messageText)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Text(verbatim: String(format: "%.0f%% match", result.score * 100))
                .font(.caption2)
                .foregroundStyle(Color(accentColor))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel

@MainActor
private final class SemanticSearchViewModel: ObservableObject {

    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }
    @Published var results: [SemanticSearchResult] = []
    @Published var isSearching = false
    @Published var isIndexEmpty = false

    private var searchTask: Task<Void, Never>?
    private let embedder = MessageEmbedder()
    private let index = SemanticSearchIndex.shared

    func onAppear() {
        Task { isIndexEmpty = await index.indexedCount == 0 }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await search(trimmed)
        }
    }

    private func search(_ query: String) async {
        guard let embedding = embedder.embed(query) else { return }
        isSearching = true
        let found = await index.search(queryEmbedding: embedding)
        results = found
        isSearching = false
    }
}

// MARK: - Preview

#Preview {
    SemanticSearchView()
        .environment(\.wireAccentColor, .purple)
}
