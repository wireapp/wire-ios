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
import WireDesign

// MARK: - SwitchStyle

struct SwitchStyle {
    static let `default` = SwitchStyle(
        enabledOnStateColor: SemanticColors.Switch.backgroundOnStateEnabled,
        enabledOffStateColor: SemanticColors.Switch.backgroundOffStateEnabled,
        enabledOnStateBorderColor: SemanticColors.Switch.borderOnStateEnabled,
        enabledOffStateBorderColor: SemanticColors.Switch.borderOffStateEnabled
    )

    private(set) var enabledOnStateColor: UIColor
    private(set) var enabledOffStateColor: UIColor
    private(set) var enabledOnStateBorderColor: UIColor
    private(set) var enabledOffStateBorderColor: UIColor
    private(set) var borderWidth: CGFloat = 1
}

// MARK: - Switch

final class Switch: UISwitch, Stylable {
    // MARK: Lifecycle

    init(style: SwitchStyle = .default) {
        self.switchStyle = style
        super.init(frame: .zero)
        applyStyle(switchStyle)

        addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    let switchStyle: SwitchStyle

    override var isOn: Bool {
        didSet {
            guard isOn != oldValue else {
                return
            }
            valueDidChange()
        }
    }

    func applyStyle(_ style: SwitchStyle) {
        backgroundColor = style.enabledOffStateColor
        onTintColor = style.enabledOnStateColor

        layer.cornerRadius = frame.height / 2.0
        layer.borderColor = isOn ? style.enabledOnStateBorderColor.cgColor : style.enabledOffStateBorderColor.cgColor
        layer.borderWidth = style.borderWidth
        clipsToBounds = true
    }

    // MARK: Private

    // MARK: - Methods

    @objc
    private func valueDidChange() {
        applyStyle(switchStyle)
    }
}
