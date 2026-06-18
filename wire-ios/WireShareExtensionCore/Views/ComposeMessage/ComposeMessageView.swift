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
    
    @FocusState
    private var isTextFieldFocused: Bool

    var body: some View {
        content
            .navigationTitle(viewModel.conversation.name)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.start()
            }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 15) {
            Spacer()
            thumbnails
            inputBar
        }
        .padding(.bottom, 16)
        .overlay {
            if viewModel.isLoading {
                loadingIndicator
            }
        }
    }

    @ViewBuilder
    private var thumbnails: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.thumbnails) { thumbnail in
                    thumbnailView(for: thumbnail)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func thumbnailView(for thumbnail: Thumbnail) -> some View {
        Group {
            if let imageData = thumbnail.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 75, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                placeholderView(for: thumbnail)
            }
        }
    }
    
    @ViewBuilder
    private func placeholderView(for thumbnail: Thumbnail) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 75, height: 75)
            
            Image(systemName: thumbnail.systemIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var inputBar: some View {
        HStack {
            TextField("Add a comment", text: $viewModel.messageText)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onAppear {
                    isTextFieldFocused = true
                }

            Button {
                Task {
                    await viewModel.send()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canSend)
        }
        .padding(.horizontal)
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

}

#Preview {
    NavigationStack {
        ComposeMessageView(
            viewModel: ComposeMessageViewModelMock(
                conversation: Conversation(name: "iOS Team"),
                thumbnails: [Thumbnail(imageData: nil, systemIconName: "photo")]
            )
        )
    }
}
