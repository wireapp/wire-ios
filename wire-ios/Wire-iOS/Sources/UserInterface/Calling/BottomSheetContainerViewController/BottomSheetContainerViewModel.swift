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

import CoreGraphics

struct BottomSheetContainerViewModel {

    typealias Configuration = BottomSheetContainerViewController.BottomSheetConfiguration
    typealias State = BottomSheetContainerViewController.BottomSheetState

    enum PanChangeDecision: Equatable {
        case none
        case update(topConstraintConstant: CGFloat)
        case show
    }

    enum SnapDecision: Equatable {
        case show
        case hide
    }

    struct ConfigurationConstraintState: Equatable {
        let visibleControllerBottomConstant: CGFloat
        let bottomViewHeightConstant: CGFloat
    }

    func configurationConstraintState(
        for configuration: Configuration
    ) -> ConfigurationConstraintState {
        ConfigurationConstraintState(
            visibleControllerBottomConstant: -configuration.initialOffset,
            bottomViewHeightConstant: configuration.height
        )
    }

    func topConstraintConstant(
        for state: State,
        configuration: Configuration
    ) -> CGFloat {
        switch state {
        case .initial:
            return -configuration.initialOffset
        case .full:
            return -configuration.height
        }
    }

    func offsetPercentage(
        topConstraintConstant: CGFloat,
        configuration: Configuration
    ) -> CGFloat {
        (-topConstraintConstant - configuration.initialOffset) /
            (configuration.height - configuration.initialOffset)
    }

    func panChangeDecision(
        state: State,
        translationY: CGFloat,
        configuration: Configuration
    ) -> PanChangeDecision {
        let yTranslationMagnitude = translationY.magnitude

        switch state {
        case .full:
            guard translationY > 0 else { return .none }
            return .update(topConstraintConstant: -(configuration.height - yTranslationMagnitude))
        case .initial:
            guard translationY < 0 else { return .none }

            let newConstant = -(configuration.initialOffset + yTranslationMagnitude)
            guard newConstant.magnitude < configuration.height else {
                return .show
            }

            return .update(topConstraintConstant: newConstant)
        }
    }

    func panEndSnapDecision(
        state: State,
        translationY: CGFloat,
        velocityY: CGFloat,
        configuration: Configuration
    ) -> SnapDecision {
        let yTranslationMagnitude = translationY.magnitude

        switch state {
        case .full:
            if velocityY < 0 {
                return .show
            } else if yTranslationMagnitude >= configuration.height / 2 || velocityY > 1000 {
                return .hide
            } else {
                return .show
            }
        case .initial:
            if yTranslationMagnitude >= configuration.height / 2 || velocityY < -1000 {
                return .show
            } else {
                return .hide
            }
        }
    }

    func panFailedSnapDecision(state: State) -> SnapDecision {
        switch state {
        case .full:
            return .show
        case .initial:
            return .hide
        }
    }
}
