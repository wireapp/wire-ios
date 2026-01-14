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

import Combine
import UIKit
import WireDataModel
import WireDesign
import WireLogging
import WireMessagingDomain

/// A lightweight view that renders a preview for one or more message attachments.
/// It supports:
///  - Image and video thumbnail previews
///  - Generic file previews with icons
///  - Automatic preview loading and caching
final class MessageReplyAttachmentsView: UIView {

    // MARK: - Properties

    private let viewModel: MessageReplyAttachmentsViewModel
    private var previewImageView: UIImageView?
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Object lifecycle

    init(
        attachments: [MultipartMessageData.Attachment],
        viewModel: MessageReplyAttachmentsViewModel,
        onSizeChange: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        let cachedVisibleAttachments = viewModel.cachedVisibleAttachments(attachments: attachments)
        setup(attachments: cachedVisibleAttachments)

        Task { @MainActor in
            do {
                let latestVisibleAttachments = try await viewModel.latestVisibleAttachments(attachments: attachments)
                if latestVisibleAttachments != cachedVisibleAttachments {
                    viewModel.cancel()
                    removeSubviews()
                    setup(attachments: latestVisibleAttachments)
                    onSizeChange?()
                }
            } catch {
                WireLogger.conversation.info("Error fetching latest visible attachments: \(error)")
            }
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func cancelPreviewDownload() {
        viewModel.cancel()
        subscriptions = .init()
    }

    // MARK: - Private

    private func setup(attachments: [MultipartMessageData.Attachment]) {
        switch attachments.count {
        case 0:
            let image = UIImage(named: "ReplyPreviewFileNotAvailable")!
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(ColorTheme.Backgrounds.onBackground)
            let text = L10n.Localizable.Content.Message.Reply.Files.notAvailable
            setupGenericView(icon: image, text: text)
        case 1 where attachments[0].isVideo || attachments[0].isImage:
            setupImagePreview(for: attachments[0])
        case 1:
            let (icon, filename) = attachments[0].filePreviewInfo
            setupGenericView(icon: icon, text: filename)
        default:
            let image = UIImage(named: "WireCellsFilesIcon")!
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(ColorTheme.Backgrounds.onBackground)
            let text = L10n.Localizable.Content.Message.Reply.Files.count("\(attachments.count)")
            setupGenericView(icon: image, text: text)
        }
    }

    private func setupImagePreview(
        for attachment: MultipartMessageData.Attachment
    ) {
        viewModel.$previewImageInfo
            .compactMap(\.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] previewImageInfo in
                self?.applyPreviewImage(
                    previewImageInfo.image,
                    isVideo: previewImageInfo.isVideo
                )
            }.store(in: &subscriptions)

        viewModel.loadPreviewImage(for: attachment)

        let imageView = makeRoundedImageView()
        previewImageView = imageView

        let loadingView = makeLoadingOverlay()
        imageView.addSubview(loadingView)
        loadingView.fitIn(view: imageView)
    }

    private func setupGenericView(
        icon: UIImage,
        text: String
    ) {
        let stack = UIStackView(axis: .horizontal)
        stack.spacing = 4

        let iconView = UIImageView(image: icon)
        iconView.tintColor = ColorTheme.Backgrounds.onBackground
        iconView.contentMode = .scaleAspectFit

        let baseHeight: CGFloat = 16
        let scaledHeight = UIFontMetrics.default.scaledValue(for: baseHeight)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: scaledHeight),
            iconView.widthAnchor.constraint(equalToConstant: scaledHeight)
        ])

        let label = UILabel()
        label.font = .smallRegularFont
        label.textColor = ColorTheme.Base.secondaryText
        label.text = text

        [iconView, label].forEach(stack.addArrangedSubview)

        addSubview(stack)
        stack.fitIn(view: self)
    }

    private func applyPreviewImage(
        _ image: UIImage,
        isVideo: Bool
    ) {
        guard let previewImageView else { return }
        previewImageView.removeSubviews()
        previewImageView.image = image
        if isVideo {
            let playIcon = makePlayIconOverlay()
            previewImageView.addSubview(playIcon)
            let insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            playIcon.fitIn(view: previewImageView, insets: insets)
        }
    }

    // MARK: - Helpers

    private func makeRoundedImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 60),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        return imageView
    }

    private func makeLoadingOverlay() -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = ColorTheme.Backdrop.background

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        indicator.color = ColorTheme.Backgrounds.surface
        indicator.startAnimating()

        overlay.addSubview(indicator)
        indicator.fitIn(view: overlay)

        return overlay
    }

    private func makePlayIconOverlay() -> UIImageView {
        typealias Theme = ColorTheme.Buttons.Secondary
        let config = UIImage.SymbolConfiguration(
            paletteColors: [
                Theme.onEnabled,
                Theme.enabled
            ]
        )

        let image = UIImage(
            systemName: "play.circle.fill",
            withConfiguration: config
        )

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)

        return imageView
    }
}
