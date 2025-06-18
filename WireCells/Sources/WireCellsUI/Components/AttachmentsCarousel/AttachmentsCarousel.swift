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

public import SwiftUI

public struct AttachmentsCarousel: View {

    @ObservedObject private var viewModel: AttachmentsCarouselViewModel
    private let onTap: (AttachmentsCarouselItem) -> Void
    private let onRemove: (AttachmentsCarouselItem) -> Void
    private let onOptions: (AttachmentsCarouselItem) -> Void

    public init(
        viewModel: AttachmentsCarouselViewModel,
        onTap: @escaping (AttachmentsCarouselItem) -> Void,
        onRemove: @escaping (AttachmentsCarouselItem) -> Void,
        onOptions: @escaping (AttachmentsCarouselItem) -> Void
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
        self.onRemove = onRemove
        self.onOptions = onOptions
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(viewModel.items) { item in
                    AttachmentsCarouselItemView(
                        item: item,
                        onTap: { onTap(item) },
                        onRemove: { onRemove(item) },
                        onOptions: { onOptions(item) }
                    )
                }
            }
            .padding(.horizontal, 12) // TODO: [WPB-17604] Don't hardcode but rely on system spacing
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

}

// TODO: [WPB-17604] This implementation is a functional placeholder. It needs to be updated to match designs.
private struct AttachmentsCarouselItemView: View {

    enum Constants {
        static let cornerButtonRadius: CGFloat = 12
    }

    let item: AttachmentsCarouselItem
    let onTap: () -> Void
    let onRemove: () -> Void
    let onOptions: () -> Void

    var body: some View {
        ZStack {
            ZStack {
                content

                if let progress = item.state.progress {
                    VStack(alignment: .leading) {
                        Spacer()
                        ProgressView(value: progress, total: 1)
                            .tint(Color.blue)
                    }
                }
            }
            .aspectRatio(item.aspectRatio, contentMode: .fill)
            .padding([.top, .trailing], Constants.cornerButtonRadius)

            cornerButton
        }
    }

    var content: some View {
        Text(contentLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
            .onTapGesture(perform: onTap)
    }

    var cornerButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(
                    action: item.state.isFailed ? onOptions : onRemove,
                    label: {
                        Image(systemName: item.state.isFailed ? "ellipsis.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: Constants.cornerButtonRadius * 2))
                            .foregroundStyle(.black)
                    }
                )
            }
            Spacer()
        }
    }

    var contentLabel: String {
        switch item.kind {
        case .image:
            "Image"
        case .video:
            "Video"
        case .audio:
            "Audio"
        case .document:
            "Document"
        }
    }

}

private extension AttachmentsCarouselItem {

    var aspectRatio: CGFloat {
        switch kind {
        case .image, .video:
            1
        case .audio, .document:
            3
        }
    }

}

private extension AttachmentsCarouselItem.State {

    var isFailed: Bool {
        switch self {
        case .failed:
            true
        default:
            false
        }
    }

    var progress: Double? {
        switch self {
        case let .uploading(progress):
            progress
        case .uploaded, .failed:
            nil
        }
    }
}

#Preview {
    AttachmentsCarousel(
        viewModel: AttachmentsCarouselViewModel(
            items: [
                AttachmentsCarouselItem(
                    id: UUID(),
                    state: .uploaded,
                    kind: .image(thumbnail: UIImage()),
                    name: "Image",
                    size: "1.2 MB"
                ),
                AttachmentsCarouselItem(
                    id: UUID(),
                    state: .uploading(progress: 0.5),
                    kind: .video(thumbnail: UIImage()),
                    name: "Video",
                    size: "1.2 MB"
                )
            ]
        ),
        onTap: { _ in },
        onRemove: { _ in },
        onOptions: { _ in }
    )
    .frame(height: 74)
    .background(Color.red)
}
