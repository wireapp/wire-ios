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
import WireMessagingDomain

struct CatchUpSummarizerDemoView: View {

    var body: some View {
        if #available(iOS 26.0, *) {
            CatchUpSummarizerDemoContentView()
        } else {
            ContentUnavailableView(
                "Requires iOS 26",
                systemImage: "brain",
                description: Text("On-device AI summarization requires iOS 26 or later.")
            )
        }
    }
}

// MARK: - Content (iOS 26+)

@available(iOS 26.0, *)
@MainActor
private final class CatchUpSummarizerDemoViewModel: ObservableObject {

    enum State {
        case idle
        case loading
        case result(String)
        case error(String)
    }

    @Published var state: State = .idle

    private let summarizer = CatchUpSummarizer()

    func summarize() {
        state = .loading
        Task {
            do {
                let summary = try await summarizer.summarize(messages: CatchUpSummarizer.mockMessages)
                state = .result(summary)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}

@available(iOS 26.0, *)
private struct CatchUpSummarizerDemoContentView: View {

    @StateObject private var viewModel = CatchUpSummarizerDemoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                messagesSection
                Divider()
                summarySection
            }
            .padding()
        }
        .navigationTitle(Text(verbatim: "Catch-Up Summarizer"))
    }

    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "Mock conversation")
                .font(.headline)
            ForEach(CatchUpSummarizer.mockMessages, id: \.self) { message in
                Text(verbatim: message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        Text(verbatim: "Summary")
            .font(.headline)

        switch viewModel.state {
        case .idle:
            Button("Summarize with Apple Intelligence") {
                viewModel.summarize()
            }
            .buttonStyle(.borderedProminent)

        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text(verbatim: "Summarizing on-device…")
                    .foregroundStyle(.secondary)
            }

        case let .result(text):
            Text(verbatim: text)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            Button("Run again") {
                viewModel.summarize()
            }
            .buttonStyle(.bordered)

        case let .error(message):
            Text(verbatim: "Error: \(message)")
                .foregroundStyle(.red)
            Button("Retry") {
                viewModel.summarize()
            }
            .buttonStyle(.bordered)
        }
    }
}
