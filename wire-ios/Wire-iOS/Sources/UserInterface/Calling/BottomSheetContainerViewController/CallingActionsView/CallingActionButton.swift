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
import WireDesign

class CallingActionButton: IconLabelButton {

    override init(input: IconLabelButtonInput, iconSize: StyleKitIcon.Size = .tiny) {
        super.init(input: input)

        subtitleTransformLabel.text = input.label
        subtitleTransformLabel.textTransform = .capitalize
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        subtitleTransformLabel.font = titleLabel?.font
        iconButton.setIcon(input.icon(forState: .normal), size: iconSize, for: .normal)
        iconButton.setIcon(input.icon(forState: .selected), size: iconSize, for: .selected)
    }

    override func apply(_ configuration: CallActionAppearance) {
        iconButton.borderWidth = 1

        setTitleColor(
            SemanticColors.Button.textCallingNormal.resolvedColor(with: traitCollection),
            for: .normal
        )

        iconButton.setBorderColor(
            SemanticColors.Button.borderCallingNormal.resolvedColor(with: traitCollection),
            for: .normal
        )
        iconButton.setIconColor(
            SemanticColors.Button.iconCallingNormal.resolvedColor(with: traitCollection),
            for: .normal
        )
        iconButton.setBackgroundImageColor(
            SemanticColors.Button.backgroundCallingNormal.resolvedColor(with: traitCollection),
            for: .normal
        )
        iconButton.setBorderColor(
            SemanticColors.Button.borderCallingSelected.resolvedColor(with: traitCollection),
            for: .selected
        )
        iconButton.setIconColor(
            SemanticColors.Button.iconCallingSelected.resolvedColor(with: traitCollection),
            for: .selected
        )
        iconButton.setBackgroundImageColor(
            SemanticColors.Button.backgroundCallingSelected.resolvedColor(with: traitCollection),
            for: .selected
        )

        setTitleColor(SemanticColors.Button.textCallingDisabled, for: .disabled)
        iconButton
            .setBorderColor(
                SemanticColors.Button.borderCallingDisabled
                    .resolvedColor(with: traitCollection),
                for: .disabled
            )
        iconButton.setIconColor(
            SemanticColors.Button.iconCallingDisabled.resolvedColor(with: traitCollection),
            for: .disabled
        )
        iconButton.setBackgroundImageColor(
            SemanticColors.Button.backgroundCallingDisabled.resolvedColor(with: traitCollection),
            for: .disabled
        )
    }

}

final class EndCallButton: CallingActionButton {

    override func apply(_ configuration: CallActionAppearance) {
        let redColor = SemanticColors.Button.backgroundLikeHighlighted
        setTitleColor(SemanticColors.Button.textCallingNormal, for: .normal)
        iconButton.setIconColor(SemanticColors.View.backgroundDefaultWhite, for: .normal)
        iconButton.setBackgroundImageColor(redColor, for: .normal)
    }
}

final class PickUpButton: CallingActionButton {

    override func apply(_ configuration: CallActionAppearance) {
        let greenColor = SemanticColors.Button.backgroundPickUp
        setTitleColor(SemanticColors.Label.textDefault, for: .normal)
        iconButton.setIconColor(SemanticColors.View.backgroundDefaultWhite, for: .normal)
        iconButton.setBackgroundImageColor(greenColor, for: .normal)
    }
}
