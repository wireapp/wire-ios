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

import avs
import Foundation
import WireDesign

// MARK: - AudioEffectCellBorders

struct AudioEffectCellBorders: OptionSet {
    static let None   = AudioEffectCellBorders([])
    static let Right  = AudioEffectCellBorders(rawValue: 1 << 0)
    static let Bottom = AudioEffectCellBorders(rawValue: 1 << 1)

    let rawValue: Int
}

// MARK: - AudioEffectCell

final class AudioEffectCell: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        clipsToBounds = false

        iconView.isUserInteractionEnabled = false
        [iconView, borderRightView, borderBottomView].forEach(contentView.addSubview)

        for v in [borderRightView, borderBottomView] {
            v.backgroundColor = SemanticColors.Icon.foregroundDefaultBlack
        }

        for item in [iconView, borderRightView, borderBottomView] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            iconView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            iconView.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            borderRightView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            borderRightView.topAnchor.constraint(equalTo: contentView.topAnchor),
            borderRightView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0.5),
            borderRightView.widthAnchor.constraint(equalToConstant: .hairline),

            borderBottomView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            borderBottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0.5),
            borderBottomView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            borderBottomView.heightAnchor.constraint(equalToConstant: .hairline),
        ])

        updateForSelectedState()
        setupAccessibility()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var borders: AudioEffectCellBorders = [.None] {
        didSet {
            updateBorders()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateForSelectedState()
        }
    }

    var effect: AVSAudioEffectType = .none {
        didSet {
            iconView.setIcon(effect.icon, size: .small, for: .normal)
            accessibilityLabel = effect.accessibilityLabel
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        effect = .none
        borders = .None
        updateForSelectedState()
    }

    // MARK: Private

    private let iconView = IconButton()
    private let borderRightView = UIView()
    private let borderBottomView = UIView()

    private func updateBorders() {
        borderRightView.isHidden = !borders.contains(.Right)
        borderBottomView.isHidden = !borders.contains(.Bottom)
    }

    private func updateForSelectedState() {
        let color: UIColor = isSelected ? UIColor.accent() : SemanticColors.Icon.foregroundDefaultBlack
        iconView.setIconColor(color, for: .normal)
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
