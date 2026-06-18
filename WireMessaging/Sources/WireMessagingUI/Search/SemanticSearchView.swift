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
            VStack(spacing: 0) {
                indexingProgressBar

                Group {
                    if viewModel.isIndexEmpty && viewModel.indexingProgress == nil {
                        emptyIndexView
                    } else if viewModel.results.isEmpty && !viewModel.query.isEmpty && !viewModel.isSearching {
                        noResultsView
                    } else {
                        resultsList
                    }
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

    @ViewBuilder
    private var indexingProgressBar: some View {
        if let progress = viewModel.indexingProgress {
            VStack(spacing: 2) {
                ProgressView(value: progress)
                    .tint(Color(accentColor))
                Text(verbatim: "Building search index… \(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
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
                    if !viewModel.isSearching && !viewModel.isReranking {
                        Text(verbatim: "\(viewModel.results.count) result\(viewModel.results.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isSearching || viewModel.isReranking {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(verbatim: viewModel.isReranking ? "Re-ranking with AI…" : "Searching…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    @Published var isReranking = false
    @Published var isIndexEmpty = false
    /// Non-nil while background indexing is running. Value in 0...1.
    @Published var indexingProgress: Double?

    private var searchTask: Task<Void, Never>?
    private var progressObservation: NSObjectProtocol?
    private let embedder = MessageEmbedder()
    private let index = SemanticSearchIndex.shared

    func onAppear() {
        Task { isIndexEmpty = await index.indexedCount == 0 }
        observeIndexingProgress()
    }

    private func observeIndexingProgress() {
        progressObservation = NotificationCenter.default.addObserver(
            forName: .semanticIndexingProgress,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let indexed = notification.userInfo?[SemanticSearchIndex.progressIndexedKey] as? Int,
                  let total = notification.userInfo?[SemanticSearchIndex.progressTotalKey] as? Int,
                  total > 0
            else { return }
            let fraction = Double(indexed) / Double(total)
            self.indexingProgress = fraction < 1 ? fraction : nil
            // Refresh the empty-index state once indexing finishes
            if fraction >= 1 {
                Task { @MainActor in
                    self.isIndexEmpty = await self.index.indexedCount == 0
                }
            }
        }
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
        let candidates = await index.search(queryEmbedding: embedding)
        isSearching = false

        if #available(iOS 26.0, *), !candidates.isEmpty {
            isReranking = true
            results = await MessageReranker().rerank(query: query, candidates: candidates)
            isReranking = false
        } else {
            results = candidates
        }
    }
}

// MARK: - Preview

#Preview {
    SemanticSearchView()
        .environment(\.wireAccentColor, .purple)
}
