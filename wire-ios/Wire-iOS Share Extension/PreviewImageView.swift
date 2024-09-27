//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit

// MARK: - PreviewDisplayMode

/// The aspect ratio of the video view.

enum PreviewDisplayMode {
    case video
    case link
    case placeholder
    indirect case mixed(Int, PreviewDisplayMode?)

    // MARK: Internal

    /// The size of the preview, in points.
    static var size: CGSize {
        CGSize(width: 70, height: 70)
    }

    /// The maximum size of a preview, adjusted for the device scale.
    static var pixelSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: 70 * scale, height: 70 * scale)
    }
}

// MARK: - PreviewImageView

/// An image view used to preview the content of a post.

final class PreviewImageView: UIImageView {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    // MARK: - Display Mode

    /// How the content should be displayed.
    var displayMode: PreviewDisplayMode? {
        didSet {
            invalidateIntrinsicContentSize()
            updateContentMode(for: displayMode)
            updateBorders(for: displayMode)
            updateDetailsBadge(for: displayMode)
        }
    }

    override var intrinsicContentSize: CGSize {
        PreviewDisplayMode.size
    }

    // MARK: Private

    private let detailsContainer = UIView()
    private let videoBadgeImageView = UIImageView()
    private let countLabel = UILabel()

    private func configureSubviews() {
        displayMode = nil

        detailsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        videoBadgeImageView.setIcon(.movie, size: .small, color: .white)

        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .white
        countLabel.textAlignment = .natural

        detailsContainer.addSubview(videoBadgeImageView)
        detailsContainer.addSubview(countLabel)
        addSubview(detailsContainer)
    }

    private func configureConstraints() {
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        videoBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            // Video Indicator
            videoBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
            videoBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            videoBadgeImageView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 4),
            videoBadgeImageView.centerYAnchor.constraint(equalTo: detailsContainer.centerYAnchor),
            // Count Label
            countLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -4),
            countLabel.centerYAnchor.constraint(equalTo: detailsContainer.centerYAnchor),
            // Details Container
            detailsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            detailsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailsContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            detailsContainer.heightAnchor.constraint(equalToConstant: 24),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateContentMode(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .none:
            contentMode = .scaleAspectFit
        case .link?, .video?:
            contentMode = .scaleAspectFill
        case .placeholder?:
            contentMode = .center
        case let .mixed(_, mainMode)?:
            updateContentMode(for: mainMode)
        }
    }

    private func updateBorders(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .link?, .placeholder?:
            layer.borderColor = UIColor.gray.cgColor
            layer.borderWidth = UIScreen.hairline

        case let .mixed(_, mainMode)?:
            updateBorders(for: mainMode)

        default:
            layer.borderColor = nil
            layer.borderWidth = 0
        }
    }

    private func updateDetailsBadge(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .video?:
            detailsContainer.isHidden = false
            videoBadgeImageView.isHidden = false
            countLabel.isHidden = true

        case let .mixed(count, _)?:
            detailsContainer.isHidden = false
            videoBadgeImageView.isHidden = true
            countLabel.isHidden = false
            countLabel.text = String(count)

        default:
            detailsContainer.isHidden = true
            videoBadgeImageView.isHidden = true
            countLabel.isHidden = true
        }
    }
}
