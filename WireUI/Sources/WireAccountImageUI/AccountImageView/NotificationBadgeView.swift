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

import SwiftUI
import WireDesign

// MARK: -

final class NotificationBadgeView: UIView {

    // MARK: - Constants

    enum Sizes {
        static let backgroundBorderWidth: CGFloat = 1
    }

    enum Defaults {
        static let badgeColor: UIColor = ColorTheme.NotificationBadge.fill
        static let backgroundViewColor: UIColor = .systemBackground
    }

    // MARK: - Properties

    var availability: Availability? {
        didSet { setNeedsLayout() }
    }

    var badgeColor: UIColor = Defaults.badgeColor {
        didSet { setNeedsLayout() }
    }

    var backgroundViewColor: UIColor = Defaults.backgroundViewColor {
        didSet { backgroundView.backgroundColor = backgroundViewColor }
    }

    var showNotifications: Bool = false {
        didSet { setNeedsLayout() }
    }

    // MARK: - Private Properties

    /// A view which serves as background and outer border.
    private let backgroundView = UIView()

    /// An image view for the icon
    private let iconView = UIImageView(image: .info)

    /// The container is needed, so that a layer's `mask` property can be set.
    /// Setting the `mask` layer of the root view (self) would result in the background being masked too.
    private let shapeContainerView = UIView()
    private let shapeView = UIView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Methods

    private func setupSubviews() {
        backgroundView.backgroundColor = backgroundViewColor
        addSubview(backgroundView)

        shapeContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shapeContainerView.addSubview(shapeView)
        shapeContainerView.frame = bounds
        addSubview(shapeContainerView)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.backgroundColor = .clear
        addSubview(iconView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalTo: widthAnchor),
            iconView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard showNotifications else {
            shapeContainerView.layer.mask = nil
            backgroundView.isHidden = true
            shapeView.backgroundColor = .none
            return
        }

        let diameter = min(bounds.width, bounds.height)
        let baseCircleFrame = CGRect(
            origin: .init(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2),
            size: .init(width: diameter, height: diameter)
        )
        shapeView.frame = baseCircleFrame
        shapeView.layer.cornerRadius = diameter / 2

        if showNotifications {
            shapeView.backgroundColor = badgeColor
            shapeContainerView.layer.mask = nil
        }

        backgroundView.isHidden = false
        backgroundView.frame = shapeView.frame.insetBy(
            dx: -Sizes.backgroundBorderWidth,
            dy: -Sizes.backgroundBorderWidth
        )
        backgroundView.layer.cornerRadius = backgroundView.frame.width / 2
    }
}

// MARK: AvailabilityIndicatorView + init(availability:)

extension NotificationBadgeView {

    public convenience init(
        showNotifications: Bool
    ) {
        self.init()
        self.showNotifications = showNotifications
        setNeedsLayout()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    VStack {
        NotificationsBadgeViewRepresentable(showNotifications: false)
        NotificationsBadgeViewRepresentable(showNotifications: true)
    }
    .background(Color(UIColor.systemGray2))
}

private struct NotificationsBadgeViewRepresentable: UIViewRepresentable {
    @State private(set) var showNotifications: Bool
    func makeUIView(context: Context) -> NotificationBadgeView { .init() }
    func updateUIView(_ view: NotificationBadgeView, context: Context) {
        view.showNotifications = showNotifications
    }
}
