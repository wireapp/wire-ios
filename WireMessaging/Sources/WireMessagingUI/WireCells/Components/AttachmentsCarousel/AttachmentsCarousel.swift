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
import WireDesign
import WireFoundation

public struct AttachmentsCarousel: View {

    @ObservedObject private var viewModel: AttachmentsCarouselViewModel
    private let onTap: (AttachmentsCarouselItem) -> Void
    private let onRemove: (AttachmentsCarouselItem) -> Void
    private let onRetry: (AttachmentsCarouselItem) -> Void

    public init(
        viewModel: AttachmentsCarouselViewModel,
        onTap: @escaping (AttachmentsCarouselItem) -> Void,
        onRemove: @escaping (AttachmentsCarouselItem) -> Void,
        onRetry: @escaping (AttachmentsCarouselItem) -> Void
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
        self.onRemove = onRemove
        self.onRetry = onRetry
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(viewModel.items) { item in
                    AttachmentsCarouselItemView(
                        item: item,
                        onTap: { onTap(item) },
                        onRemove: { onRemove(item) },
                        onRetry: { onRetry(item) }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.all, edges: .bottom)
    }

}

private struct AttachmentsCarouselItemView: View {

    enum Constants {
        static let topPadding: CGFloat = 8
        static let trailingPadding: CGFloat = 6
        static let buttonCornerRadius: CGFloat = 24
    }

    let item: AttachmentsCarouselItem
    let onTap: () -> Void
    let onRemove: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            ZStack {
                content
                    .onTapGesture(perform: onTap)
            }
            .aspectRatio(item.aspectRatio, contentMode: .fill)
            .padding(.top, Constants.topPadding)
            .padding(.trailing, Constants.trailingPadding)

            cornerButton
        }
    }

    @ViewBuilder var content: some View {
        switch item.kind {
        case let .image(thumbnail):
            WireCellsImageAttachmentPreview(
                thumbnail: thumbnail.map { Image(uiImage: $0) },
                progress: item.state.progress,
                isError: item.state.isFailed
            )
        case let .video(thumbnail):
            WireCellsVideoAttachmentPreview(
                thumbnail: thumbnail.map { Image(uiImage: $0) },
                progress: item.state.progress,
                isError: item.state.isFailed,
                canPlay: false
            )
        case .audio, .document:
            WireCellsDocumentAttachmentPreview(
                headerIcon: Image(item.fileIcon.resource),
                headerText: item.fileExtension.map { "\($0.uppercased()) (\(item.size))" } ?? item.size,
                labelText: item.name,
                progress: item.state.progress,
                isError: item.state.isFailed
            )
        }
    }

    // TODO: [WPB-17604] Add missing accessibility labels
    var cornerButton: some View {
        VStack {
            HStack {
                Spacer()

                if item.state.isFailed {
                    Menu {
                        Button(L10n.Localizable.Conversation.Draft.AttachmentMenu.retry, action: onRetry)
                        Button(L10n.Localizable.Conversation.Draft.AttachmentMenu.remove, action: onRemove)
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.buttonCornerRadius, height: Constants.buttonCornerRadius)
                    }
                } else {
                    Button(
                        action: onRemove,
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.buttonCornerRadius, height: Constants.buttonCornerRadius)
                        }
                    )

                }
            }
            .buttonStyle(CornerButtonStyle())

            Spacer()
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
        case .uploaded:
            nil
        case .failed:
            1 // When failed we show a full red progress bar
        }
    }
}

private struct CornerButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .symbolRenderingMode(.palette)
            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color, ColorTheme.Buttons.Secondary.enabled.color)
            .overlay(
                Circle().strokeBorder(ColorTheme.Buttons.Secondary.enabledOutline.color, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }

}

#Preview {
    VStack {
        ZStack {
            Color(.green).ignoresSafeArea()

            AttachmentsCarousel(
                viewModel: AttachmentsCarouselViewModel(
                    items: [
                        AttachmentsCarouselItem(
                            id: UUID(),
                            state: .failed,
                            kind: .image(
                                thumbnail: UIImage(named: "rectangular-placeholder", in: Bundle.module, with: nil)
                            ),
                            name: "Image",
                            fileExtension: "jpg",
                            size: "1.2 MB",
                            fileIcon: .image
                        ),
                        AttachmentsCarouselItem(
                            id: UUID(),
                            state: .uploading(progress: 1),
                            kind: .video(thumbnail: nil),
                            name: "Video",
                            fileExtension: "mp4",
                            size: "1.2 MB",
                            fileIcon: .video
                        ),
                        AttachmentsCarouselItem(
                            id: UUID(),
                            state: .uploading(progress: 0.5),
                            kind: .document,
                            name: "Doc",
                            fileExtension: "pdf",
                            size: "1.2 MB",
                            fileIcon: .pdf
                        )
                    ]
                ),
                onTap: { _ in },
                onRemove: { _ in },
                onRetry: { _ in }
            )
            .frame(height: 82)
            .background(Color.white)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
        }
        Spacer(minLength: 500)
    }
}
