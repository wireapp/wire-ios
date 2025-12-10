import UIKit
import WireDataModel
import WireMessagingDomain
import WireMessagingUI
import UniformTypeIdentifiers
import WireFoundation
import WireDesign
import Combine

/// A lightweight view that renders a preview for one or more message attachments.
/// It supports:
///  - Image and video thumbnail previews
///  - Generic file previews with icons
///  - Automatic preview loading and caching
final class MessageReplyAttachmentsView: UIView {
    
    // MARK: - Properties
    
    private let attachments: [MultipartMessageData.Attachment]
    private let fetchNodeUseCase: any WireCellsFetchNodeUseCaseProtocol
    
    private var task: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    private var previewImageView: UIImageView?
    
    // MARK: - Init
    
    init(
        attachments: [MultipartMessageData.Attachment],
        fetchNodeUseCase: any WireCellsFetchNodeUseCaseProtocol
    ) {
        self.attachments = attachments
        self.fetchNodeUseCase = fetchNodeUseCase
        super.init(frame: .zero)
        setupAttachmentUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelPreviewDownload()
    }
    
    // MARK: - Public
    
    func cancelPreviewDownload() {
        task?.cancel()
        task = nil
        subscriptions.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupAttachmentUI() {
        if attachments.count == 1 {
            setupSingleAttachment(attachments[0])
        } else {
            setupMultipleAttachments()
        }
    }
    
    private func setupSingleAttachment(_ attachment: MultipartMessageData.Attachment) {
        switch attachment.initialMetadata {
        case .image, .video:
            setupAttachmentPreview(for: attachment)
        default:
            let (icon, filename) = attachment.filePreviewInfo
            setupAttachmentView(icon: icon, text: filename)
        }
    }
    
    private func setupMultipleAttachments() {
        let image = UIImage(systemName: "folder.fill")!
        let text = L10n.Localizable.Content.Message.Reply.Files.count("\(attachments.count)")
        setupAttachmentView(icon: image, text: text)
    }
    
    // MARK: - Preview Setup
    
    private func setupAttachmentPreview(
        for attachment: MultipartMessageData.Attachment
    ) {
        let imageView = makeRoundedImageView()
        previewImageView = imageView
        
        let loadingView = makeLoadingOverlay()
        imageView.addSubview(loadingView)
        loadingView.fitIn(view: imageView)
        
        loadPreviewImage(for: attachment)
    }
    
    private func loadPreviewImage(
        for attachment: MultipartMessageData.Attachment
    ) {
        task = Task { [weak self] in
            guard let self else { return }
            
            guard let node = try? await fetchNodeUseCase
                .invoke(nodeID: attachment.nodeID)
                .compactMap({ $0 })
                .first(where: { $0.id == attachment.nodeID })
            else { return }
            
            setupPreviewImage(from: node, isVideo: attachment.isVideo)
        }
    }
    
    private func setupPreviewImage(
        from node: WireCellsNode,
        isVideo: Bool
    ) {
        guard let smallPreview = node.previews.min(by: {
            $0.dimension < $1.dimension
        }) else { return }
        
        let cache = UIImage.defaultUserImageCache.cache
        let cacheKey: NSString = {
            if let eTag = node.eTag {
                return "\(node.id.uuidString)-\(eTag)" as NSString
            }
            return node.id.uuidString as NSString
        }()
        
        if let cachedImage = cache.object(forKey: cacheKey) {
            applyPreviewImage(cachedImage, isVideo: isVideo)
            return
        }
        
        downloadPreviewImage(
            from: smallPreview.url,
            isVideo: isVideo,
            cacheKey: cacheKey,
            cache: cache
        )
    }
    
    private func downloadPreviewImage(
        from url: URL,
        isVideo: Bool,
        cacheKey: NSString,
        cache: NSCache<NSString, UIImage>
    ) {
        guard task?.isCancelled == false else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .compactMap(UIImage.init(data:))
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] image in
                guard let self else { return }
                cache.setObject(image, forKey: cacheKey)
                self.applyPreviewImage(image, isVideo: isVideo)
            }.store(in: &subscriptions)
    }
    
    private func setupAttachmentView(
        icon: UIImage,
        text: String
    ) {
        let stack = UIStackView(axis: .horizontal)
        stack.spacing = 4
        
        let iconView = UIImageView(image: icon)
        iconView.tintColor = ColorTheme.Backgrounds.onBackground
        iconView.setSize(15)
        
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
    
    // MARK: - Views
    
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

// MARK: - Helpers

private extension UIImageView {
    func setSize(_ size: CGFloat) {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: size),
            widthAnchor.constraint(equalToConstant: size)
        ])
    }
}

private extension MultipartMessageData.Attachment {
    var filePreviewInfo: (UIImage, String) {
        let fileType = contentType.flatMap { UTType(mimeType: $0) }
        let fileURL = initialName.flatMap(URL.init(string:))
        
        let icon = FileIcon.make(
            type: fileType,
            fileExtension: fileURL?.pathExtension
        ).image
        
        let filename = fileURL?
            .deletingPathExtension()
            .lastPathComponent ?? ""
        
        return (icon, filename)
    }
    
    var isVideo: Bool {
        switch initialMetadata {
        case .video:
            true
        default:
            false
        }
    }
}
