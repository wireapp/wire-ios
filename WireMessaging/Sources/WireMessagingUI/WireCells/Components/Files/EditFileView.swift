//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WebKit

// MARK: - EditFileView

struct EditFileView<ViewModel>: View where ViewModel: EditFileViewModelProtocol {

    @StateObject private var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    package init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let url = viewModel.editorURL {
                    WebView(url: url)
                } else {
                    EmptyView()
                }
            }
            .onAppear(perform: {
                Task {
                    await viewModel.load()

                }
            })
            .navigationTitle(Text(verbatim: "Edit File"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
        }
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Image(.close)
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        )
        .accessibilityIdentifier("close")
    }
}

// MARK: - WebView

private struct WebView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
