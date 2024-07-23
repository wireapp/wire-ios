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

public extension FontSpec {

    // MARK: - Small

    static var smallFont: Self {
        self.init(.small, .none)
    }

    static var smallLightFont: Self {
        self.init(.small, .light)
    }

    static var smallRegularFont: Self {
        self.init(.small, .regular)
    }

    static var smallMediumFont: Self {
        self.init(.small, .medium)
    }

    static var smallSemiboldFont: Self {
        self.init(.small, .semibold)
    }

    static var smallBoldFont: Self {
        self.init(.small, .bold)
    }

    // MARK: - Normal

    static var normalFont: Self {
        self.init(.normal, .none)
    }

    static var normalLightFont: Self {
        self.init(.normal, .light)
    }

    static var normalRegularFont: Self {
        self.init(.normal, .regular)
    }

    static var normalMediumFont: Self {
        self.init(.normal, .medium)
    }

    static var normalSemiboldFont: Self {
        self.init(.normal, .semibold)
    }

    static var normalBoldFont: Self {
        self.init(.normal, .bold)
    }

    static var normalRegularFontWithInputTextStyle: Self {
        self.init(.normal, .regular, .inputText)
    }

    // MARK: - Medium

    static var mediumFont: Self {
        self.init(.medium, .none)
    }

    static var mediumSemiboldFont: Self {
        self.init(.medium, .semibold)
    }

    static var mediumLightLargeTitleFont: Self {
        self.init(.medium, .light, .largeTitle)
    }

    static var mediumRegularFont: Self {
        self.init(.medium, .regular)
    }

    static var mediumSemiboldInputText: Self {
        self.init(.medium, .semibold, .inputText)
    }

    // MARK: - Large

    static var largeFont: Self {
        self.init(.large, .none)
    }

    static var largeThinFont: Self {
        self.init(.large, .thin)
    }

    static var largeLightFont: Self {
        self.init(.large, .light)
    }

    static var largeRegularFont: Self {
        self.init(.large, .regular)
    }

    static var largeMediumFont: Self {
        self.init(.large, .medium)
    }

    static var largeSemiboldFont: Self {
        self.init(.large, .semibold)
    }

    static var largeLightWithTextStyleFont: Self {
        self.init(.large, .light, .largeTitle)
    }

    // Account
    static var accountName: Self {
        self.init(.titleThree, .semibold)
    }

    static var accountTeam: Self {
        self.init(.subHeadline, .regular)
    }

    // Navigation
    static var headerSemiboldFont: Self {
        self.init(.header, .semibold)
    }

    static var headerRegularFont: Self {
        self.init(.header, .regular)
    }

    static var subheadlineFont: Self {
        self.init(.subHeadline, .regular)
    }

    // MARK: - Body

    static var body: Self {
        self.init(.body, .regular)
    }

    // MARK: - Body Two

    static var bodyTwoSemibold: Self {
        self.init(.bodyTwo, .semibold)
    }

    // MARK: - Button Small

    static var buttonSmallBold: Self {
        self.init(.buttonSmall, .bold)
    }

    static var buttonSmallSemibold: Self {
        self.init(.buttonSmall, .semibold)
    }

    // MARK: - Button Big

    static var buttonBigSemibold: Self {
        self.init(.buttonBig, .semibold)
    }
}
