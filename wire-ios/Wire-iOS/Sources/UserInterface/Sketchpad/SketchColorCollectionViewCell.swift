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
import WireCommonComponents
import WireDesign

// MARK: - SketchColors Enum

enum SketchColors: CaseIterable {
    typealias SketchColorValues = SemanticColors.DrawingColors
    typealias SketchColorName = L10n.Localizable.Drawing.Colors

    case black
    case white
    case blue
    case green
    case yellow
    case red
    case orange
    case purple
    case brown
    case turquoise
    case sky
    case lime
    case cyan
    case lilac
    case coral
    case pink
    case chocolate
    case gray

    var name: String {
        switch self {
        case .black:
            SketchColorName.black
        case .white:
            SketchColorName.white
        case .blue:
            SketchColorName.blue
        case .green:
            SketchColorName.green
        case .yellow:
            SketchColorName.yellow
        case .red:
            SketchColorName.red
        case .orange:
            SketchColorName.orange
        case .purple:
            SketchColorName.purple
        case .brown:
            SketchColorName.brown
        case .turquoise:
            SketchColorName.turquoise
        case .sky:
            SketchColorName.sky
        case .lime:
            SketchColorName.lime
        case .cyan:
            SketchColorName.cyan
        case .lilac:
            SketchColorName.lilac
        case .coral:
            SketchColorName.coral
        case .pink:
            SketchColorName.pink
        case .chocolate:
            SketchColorName.chocolate
        case .gray:
            SketchColorName.gray
        }
    }

    var color: UIColor {
        switch self {
        case .black:
            SketchColorValues.black
        case .white:
            SketchColorValues.white
        case .blue:
            SketchColorValues.blue
        case .green:
            SketchColorValues.green
        case .yellow:
            SketchColorValues.yellow
        case .red:
            SketchColorValues.red
        case .orange:
            SketchColorValues.orange
        case .purple:
            SketchColorValues.purple
        case .brown:
            SketchColorValues.brown
        case .turquoise:
            SketchColorValues.turquoise
        case .sky:
            SketchColorValues.sky
        case .lime:
            SketchColorValues.lime
        case .cyan:
            SketchColorValues.cyan
        case .lilac:
            SketchColorValues.lilac
        case .coral:
            SketchColorValues.coral
        case .pink:
            SketchColorValues.pink
        case .chocolate:
            SketchColorValues.chocolate
        case .gray:
            SketchColorValues.gray
        }
    }
}

// MARK: - SketchColor

struct SketchColor: Equatable {
    var name: String
    var color: UIColor

    static func getAllColors() -> [SketchColor] {
        SketchColors.allCases.map { SketchColor(name: $0.name, color: $0.color) }
    }
}

// MARK: - SketchColorCollectionViewCell

final class SketchColorCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    var titleLabel = DynamicFontLabel(
        fontSpec: .smallRegularFont,
        color: SemanticColors.Label.textDefault
    )

    var contentStackView = UIStackView()

    var sketchColor: SketchColor? {
        didSet {
            guard sketchColor != oldValue else {
                return
            }

            if let sketchColor {
                knobView.knobColor = sketchColor.color
                titleLabel.text = sketchColor.name.localizedCapitalized
            }
        }
    }

    var brushWidth: CGFloat = 6 {
        didSet {
            guard brushWidth != oldValue else {
                return
            }

            knobView.knobDiameter = brushWidth
            knobView.setNeedsLayout()
        }
    }

    override var isSelected: Bool {
        didSet {
            knobView.knobColor = sketchColor?.color
            knobView.isSelected = isSelected
            if isSelected {
                titleLabel.font = FontSpec.smallSemiboldFont.font!
            } else {
                titleLabel.font = FontSpec.smallRegularFont.font!
            }
        }
    }

    private var knobView: ColorKnobView!
    private var initialContraintsCreated = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.knobView = ColorKnobView()

        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentStackView.spacing = 9
        contentStackView.addArrangedSubview(knobView)
        contentStackView.addArrangedSubview(titleLabel)

        addSubview(contentStackView)

        setNeedsUpdateConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setting up constraints

    override func updateConstraints() {
        super.updateConstraints()

        if initialContraintsCreated {
            return
        }

        [contentStackView, knobView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5),
            knobView.widthAnchor.constraint(equalToConstant: 10),
            knobView.heightAnchor.constraint(equalToConstant: 10),
        ])

        initialContraintsCreated = true
    }
}
