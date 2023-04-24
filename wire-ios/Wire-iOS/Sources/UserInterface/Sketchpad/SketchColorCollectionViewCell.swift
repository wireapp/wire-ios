//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

enum ColorNew: CaseIterable {
    typealias SketchColorValues = SemanticColors.SketchColors

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
            return "Black"
        case .white:
            return "White"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .yellow:
            return "Yellow"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .purple:
            return "Purple"
        case .brown:
            return "Brown"
        case .turquoise:
            return "Turquoise"
        case .sky:
            return "Sky"
        case .lime:
            return "Lime"
        case .cyan:
            return "Cyan"
        case .lilac:
            return "Lilac"
        case .coral:
            return "Coral"
        case .pink:
            return "Pink"
        case .chocolate:
            return "Chocolate"
        case .gray:
            return "Gray"
        }
    }

    var color: UIColor {
        switch self {
        case .black:
            return SketchColorValues.blackColor
        case .white:
            return SketchColorValues.whiteColor
        case .blue:
            return SketchColorValues.blueColor
        case .green:
            return SketchColorValues.greenColor
        case .yellow:
            return SketchColorValues.yellowColor
        case .red:
            return SketchColorValues.redColor
        case .orange:
            return SketchColorValues.orangeColor
        case .purple:
            return SketchColorValues.purpleColor
        case .brown:
            return SketchColorValues.brownColor
        case .turquoise:
            return SketchColorValues.turquoiseColor
        case .sky:
            return SketchColorValues.skyColor
        case .lime:
            return SketchColorValues.limeColor
        case .cyan:
            return SketchColorValues.cyanColor
        case .lilac:
            return SketchColorValues.lilacColor
        case .coral:
            return SketchColorValues.coralColor
        case .pink:
            return SketchColorValues.pinkColor
        case .chocolate:
            return SketchColorValues.chocolateColor
        case .gray:
            return SketchColorValues.grayColor
        }
    }
}

struct SketchColor: Equatable {
    var name: String
    var color: UIColor

    init(name: String, color: UIColor) {
        self.name = name
        self.color = color
    }

    static func getAllColors() -> [SketchColor] {
        return ColorNew.allCases.map { SketchColor(name: $0.name, color: $0.color) }
    }
}

final class SketchColorCollectionViewCell: UICollectionViewCell {

    var titleLabel = DynamicFontLabel(fontSpec: .smallRegularFont,
                                      color: SemanticColors.Label.textDefault)

    var contentStackView = UIStackView()

    var sketchColor: SketchColor? {
        didSet {
            guard sketchColor != oldValue else {
                return
            }

            if let sketchColor = sketchColor {
                knobView.knobColor = sketchColor.color
                titleLabel.text = sketchColor.name

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
        }
    }

    private var knobView: ColorKnobView!
    private var initialContraintsCreated = false

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

    override func updateConstraints() {
        super.updateConstraints()

        if initialContraintsCreated {
            return
        }

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        knobView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5).isActive = true
        knobView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        knobView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        initialContraintsCreated = true
    }
}
