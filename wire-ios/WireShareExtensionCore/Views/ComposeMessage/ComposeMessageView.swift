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

struct ComposeMessageView<
    ViewModel: ComposeMessageViewModel
>: View {

    @State
    var viewModel: ViewModel

    var body: some View {
        content
            .navigationTitle(viewModel.conversation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Send") {
                        Task {
                            await viewModel.send()
                        }
                    }
                    .disabled(!viewModel.canSend)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            shareItemPreview
                .padding()

            Divider()

            messageTextField
                .padding()

            Spacer()
        }
        .overlay {
            if viewModel.isLoading {
                loadingIndicator
            }
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                if let progressState = viewModel.progressState {
                    switch progressState {
                    case .preparing:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                        
                        Text("Preparing")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                    case .sending(let progress):
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 200)
                        
                        Text("Sending")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("Sent Successfully")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }

    @ViewBuilder
    private var shareItemPreview: some View {
        HStack(spacing: 12) {
            thumbnailView
                .padding()
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(shareItemTypeText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        Image(systemName: shareItemIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .font(.title)
            .foregroundStyle(.secondary)
    }

    private var shareItemIcon: String {
        switch viewModel.shareItem {
        case .image:
            return "photo"
        case .video:
            return "video"
        case .file:
            return "doc"
        }
    }

    private var shareItemTypeText: String {
        switch viewModel.shareItem {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .file:
            return "File"
        }
    }

    @ViewBuilder
    private var messageTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a message (optional)")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Type a message", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}

#Preview {
    NavigationStack {
        ComposeMessageView(
            viewModel: ComposeMessageViewModelImpl(
                account: .sam,
                conversation: Conversation(
                    id: UUID(),
                    name: "Design Team"
                ),
                shareItem: .image(
                    ImageShareItem(
                        url: URL(string: "")!,
                        name: "foo.jpg",
                        size: 1048
                    )
                ),
                router: RootRouter(),
                sendMessage: SendMessageUseCaseMock(),
                onDone: {
                    print("Message sent")
                }
            )
        )
    }
}
