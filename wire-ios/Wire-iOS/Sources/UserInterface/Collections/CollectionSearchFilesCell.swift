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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFoundation

final class CollectionSearchFilesCell: CollectionCell {
    private let containerView = UIView()

    private let label: UILabel = {
        let label = UILabel()
        label.text = L10n.Localizable.Collections.Section.SearchFiles.description
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = ColorTheme.Base.secondaryText
        return imageView
    }()

    private let informationButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "info.circle")
        config.baseForegroundColor = ColorTheme.Buttons.Primary.enabled

        return UIButton(configuration: config)
    }()

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }

    private func loadView() {
        let views = [label, containerView, chevronImageView, informationButton]
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        views.forEach(secureContentsView.addSubview)
        secureContentsView.layer.cornerRadius = 16

        NSLayoutConstraint.activate([
            // label
            label.topAnchor.constraint(equalTo: secureContentsView.topAnchor),
            label.bottomAnchor.constraint(equalTo: secureContentsView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(greaterThanOrEqualTo: informationButton.trailingAnchor),

            // information button
            informationButton.heightAnchor.constraint(equalToConstant: 18),
            informationButton.widthAnchor.constraint(equalToConstant: 18),
            informationButton.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -16),
            informationButton.centerYAnchor.constraint(equalTo: secureContentsView.centerYAnchor),

            // chevron icon
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.centerYAnchor.constraint(equalTo: secureContentsView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor, constant: -16),

            // containerView
            containerView.topAnchor.constraint(equalTo: secureContentsView.bottomAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: secureContentsView.bottomAnchor, constant: 4)
        ])
    }

    func configure(
        accentColor: WireAccentColor?,
        informationButtonHandler: @escaping () -> Void
    ) {
        if let accentColor {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "info.circle")
            config.baseForegroundColor = ColorTheme.Base.primary(accentColor)
            informationButton.configuration = config
        }
        let action = UIAction { _ in informationButtonHandler() }
        informationButton.addAction(action, for: .touchUpInside)
    }
}
