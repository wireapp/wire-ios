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
            return SketchColorName.black
        case .white:
            return SketchColorName.white
        case .blue:
            return SketchColorName.blue
        case .green:
            return SketchColorName.green
        case .yellow:
            return SketchColorName.yellow
        case .red:
            return SketchColorName.red
        case .orange:
            return SketchColorName.orange
        case .purple:
            return SketchColorName.purple
        case .brown:
            return SketchColorName.brown
        case .turquoise:
            return SketchColorName.turquoise
        case .sky:
            return SketchColorName.sky
        case .lime:
            return SketchColorName.lime
        case .cyan:
            return SketchColorName.cyan
        case .lilac:
            return SketchColorName.lilac
        case .coral:
            return SketchColorName.coral
        case .pink:
            return SketchColorName.pink
        case .chocolate:
            return SketchColorName.chocolate
        case .gray:
            return SketchColorName.gray
        }
    }

    var color: UIColor {
        switch self {
        case .black:
            return SketchColorValues.black
        case .white:
            return SketchColorValues.white
        case .blue:
            return SketchColorValues.blue
        case .green:
            return SketchColorValues.green
        case .yellow:
            return SketchColorValues.yellow
        case .red:
            return SketchColorValues.red
        case .orange:
            return SketchColorValues.orange
        case .purple:
            return SketchColorValues.purple
        case .brown:
            return SketchColorValues.brown
        case .turquoise:
            return SketchColorValues.turquoise
        case .sky:
            return SketchColorValues.sky
        case .lime:
            return SketchColorValues.lime
        case .cyan:
            return SketchColorValues.cyan
        case .lilac:
            return SketchColorValues.lilac
        case .coral:
            return SketchColorValues.coral
        case .pink:
            return SketchColorValues.pink
        case .chocolate:
            return SketchColorValues.chocolate
        case .gray:
            return SketchColorValues.gray
        }
    }
}

// MARK: - SketchColor

struct SketchColor: Equatable {
    var name: String
    var color: UIColor

    static func getAllColors() -> [SketchColor] {
        return SketchColors.allCases.map { SketchColor(name: $0.name, color: $0.color) }
    }
}

// MARK: - SketchColorCollectionViewCell

final class SketchColorCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    var titleLabel = DynamicFontLabel(style: .subline1,
                                      color: SemanticColors.Label.textDefault)

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
        knobView = ColorKnobView()

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
            knobView.heightAnchor.constraint(equalToConstant: 10)
        ])

        initialContraintsCreated = true
    }
}
