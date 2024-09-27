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

/// A view that displays the avatar of a user, either as text initials or as an image.
class AvatarImageView: UIView {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    // MARK: -

    /// The different, mutually-exclusive forms of avatars.
    enum Avatar: Equatable {
        case image(UIImage)
        case text(String)

        // MARK: Lifecycle

        init() {
            self = .image(resource: .unavailableUser)
        }

        // MARK: Internal

        static func image(resource: ImageResource) -> Self {
            .image(.init(resource: resource))
        }
    }

    /// The different shapes of avatars.
    enum Shape {
        case rectangle
        case circle
        case relative
    }

    /// The view that contains the avatar.
    var container = RoundedView()

    // MARK: - Properties

    /// The avatar to display.
    var avatar = Avatar() {
        didSet { avatar != oldValue ? updateAvatar() : () }
    }

    /// The shape of the avatar
    var shape: Shape = .circle {
        didSet { shape != oldValue ? updateShape() : () }
    }

    /// Whether to allow initials.
    var allowsInitials = true {
        didSet { allowsInitials != oldValue ? updateAvatar() : () }
    }

    /// The font to use of the initials label.
    var initialsFont: UIFont {
        get { initialsLabel.font }
        set { initialsLabel.font = newValue }
    }

    /// The color to use for the initials label.
    var initialsColor: UIColor {
        get { initialsLabel.textColor }
        set { initialsLabel.textColor = newValue }
    }

    override var contentMode: UIView.ContentMode {
        didSet { imageView.contentMode = contentMode }
    }

    /// Updates the image constraints hugging and resistance priorities.
    /// - parameter resistance: The compression resistance priority.
    /// - parameter hugging: The content hugging priority.
    func setImageConstraint(resistance: Float, hugging: Float) {
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: hugging), for: .vertical)
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: hugging), for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: resistance), for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: resistance), for: .horizontal)
    }

    // MARK: Private

    private let imageView = UIImageView()
    private let initialsLabel = UILabel()

    private func configureSubviews() {
        imageView.contentMode = .scaleAspectFill

        isOpaque = false
        imageView.isOpaque = false
        container.backgroundColor = .yellow

        initialsLabel.textColor = .white
        initialsLabel.font = .systemFont(ofSize: 17)

        container.clipsToBounds = true
        container.isUserInteractionEnabled = false

        imageView.isAccessibilityElement = false
        initialsLabel.isAccessibilityElement = false

        addSubview(container)
        container.addSubview(imageView)
        container.addSubview(initialsLabel)

        updateAvatar()
        updateShape()
    }

    private func configureConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // containerView
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.widthAnchor.constraint(equalTo: container.heightAnchor),

            // imageView
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            // initials
            initialsLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    // MARK: - Content

    /// Updates the displayed avatar.
    private func updateAvatar() {
        switch avatar {
        case .text where !allowsInitials:
            imageView.image = nil
            initialsLabel.text = nil
            imageView.isHidden = true
            initialsLabel.isHidden = true

        case let .image(image):
            imageView.image = image
            initialsLabel.text = nil
            imageView.isHidden = false
            initialsLabel.isHidden = true

        case let .text(text):
            imageView.image = nil
            initialsLabel.text = text
            imageView.isHidden = true
            initialsLabel.isHidden = false
        }
    }

    /// Updates the shape of the displayed avatar.
    private func updateShape() {
        switch shape {
        case .circle:
            container.shape = .circle
        case .rectangle:
            container.shape = .rectangle
        case .relative:
            container.shape = .relative(multiplier: 1 / 6, dimension: .height)
        }
    }
}
